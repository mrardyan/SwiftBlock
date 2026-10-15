import Foundation

/// Type-erased job execution handler.
public typealias JobExecutionHandler = @Sendable (Data) async throws -> Void

/// Network reachability abstraction for pausing/resuming queues based on connectivity.
public protocol JobReachabilityProvider: Sendable {
    var isConnected: Bool { get async }
}

/// Actor-isolated, thread-safe asynchronous job queue with partition serialization,
/// idempotency deduplication, exponential backoff retries, and offline pausing.
public actor __MODULE_NAME__ {
    public static let shared = __MODULE_NAME__()

    private let storage: any JobStorageProtocol
    private let errorClassifier: any JobErrorClassifier
    private var reachability: (any JobReachabilityProvider)?

    private var registeredHandlers: [String: JobExecutionHandler] = [:]
    private var adHocExecutors: [String: @Sendable () async throws -> Void] = [:]

    // In-memory queue index
    private var pendingJobs: [String: (type: String, partitionKey: String?, nextEligibleAt: Date)] = [:]
    private var runningPartitions: Set<String> = []
    private var activeWorkerCount = 0

    public let maxConcurrentWorkers: Int
    public let baseDelay: TimeInterval
    public let maxDelay: TimeInterval
    public let multiplier: Double
    public private(set) var isPaused: Bool = false

    public init(
        storage: any JobStorageProtocol = InMemoryJobStorage(),
        errorClassifier: any JobErrorClassifier = DefaultJobErrorClassifier(),
        reachability: (any JobReachabilityProvider)? = nil,
        maxConcurrentWorkers: Int = 4,
        baseDelay: TimeInterval = 1.0,
        maxDelay: TimeInterval = 30.0,
        multiplier: Double = 2.0
    ) {
        self.storage = storage
        self.errorClassifier = errorClassifier
        self.reachability = reachability
        self.maxConcurrentWorkers = max(1, maxConcurrentWorkers)
        self.baseDelay = max(0.1, baseDelay)
        self.maxDelay = max(baseDelay, maxDelay)
        self.multiplier = max(1.0, multiplier)
    }

    /// Sets or updates the network reachability provider.
    public func setReachabilityProvider(_ provider: any JobReachabilityProvider) {
        self.reachability = provider
    }

    /// Registers a persistent handler for a specific `JobPayload.jobType`.
    public func registerHandler<P: JobPayload>(
        for payloadType: P.Type,
        handler: @escaping @Sendable (P) async throws -> Void
    ) {
        let jsonDecoder = JSONDecoder()
        registeredHandlers[P.jobType] = { data in
            let payload = try jsonDecoder.decode(P.self, from: data)
            try await handler(payload)
        }
    }

    /// Enqueues a job payload with an ad-hoc closure. Deduplicates based on `payload.idempotencyKey`.
    @discardableResult
    public func enqueue<P: JobPayload>(
        _ payload: P,
        maxAttempts: Int = 3,
        execute: (@Sendable () async throws -> Void)? = nil
    ) async throws -> String {
        let id = payload.idempotencyKey

        // Deduplication check: Do not re-enqueue if the same idempotency key is active
        if pendingJobs[id] != nil {
            return id
        }
        if let existingRecord = try await storage.loadJob(id: id, as: P.self), !existingRecord.status.isTerminal {
            return id
        }

        let record = JobRecord(payload: payload, maxAttempts: maxAttempts, status: .pending)
        try await storage.saveJob(record)

        if let execute {
            adHocExecutors[id] = execute
        }

        pendingJobs[id] = (type: P.jobType, partitionKey: payload.partitionKey, nextEligibleAt: Date())

        triggerProcessing()
        return id
    }

    /// Restores all uncompleted jobs from persistent storage into memory (cold-start recovery).
    ///
    /// Call this during application launch or when initializing the queue to resume
    /// persistent outbox processing across app restarts and crashes.
    @discardableResult
    public func restorePendingJobs() async throws -> Int {
        let pending = try await storage.loadAllPendingJobInfo()
        for item in pending {
            if pendingJobs[item.id] == nil {
                pendingJobs[item.id] = (type: item.jobType, partitionKey: item.partitionKey, nextEligibleAt: Date())
            }
        }
        triggerProcessing()
        return pending.count
    }

    /// Returns the current lifecycle status of a job by its idempotency ID.
    public func status<P: JobPayload>(for id: String, as: P.Type) async throws -> JobStatus? {
        let record = try await storage.loadJob(id: id, as: P.self)
        return record?.status
    }

    /// Pauses job queue processing (e.g. when network becomes unreachable).
    public func pause() {
        isPaused = true
    }

    /// Resumes job queue processing.
    public func resume() {
        isPaused = false
        triggerProcessing()
    }

    /// Cancels a pending job by its ID.
    public func cancel<P: JobPayload>(id: String, as: P.Type) async throws {
        pendingJobs.removeValue(forKey: id)
        adHocExecutors.removeValue(forKey: id)
        if var record = try await storage.loadJob(id: id, as: P.self) {
            record.status = .cancelled
            try await storage.saveJob(record)
        }
    }

    // MARK: - Dispatch Engine

    private func triggerProcessing() {
        guard !isPaused, activeWorkerCount < maxConcurrentWorkers else { return }

        // Find next eligible job considering partition serialization and backoff delays
        let now = Date()
        var selectedJobID: String?
        var selectedPartition: String?
        var selectedJobType: String?

        for (id, meta) in pendingJobs {
            guard now >= meta.nextEligibleAt else { continue }

            if let partition = meta.partitionKey {
                // If partition is already executing, skip to preserve strictly serial ordering
                if runningPartitions.contains(partition) {
                    continue
                }
                selectedPartition = partition
            }

            selectedJobID = id
            selectedJobType = meta.type
            break
        }

        guard let jobID = selectedJobID, let jobType = selectedJobType else { return }

        // Lock partition and allocate worker
        if let partition = selectedPartition {
            runningPartitions.insert(partition)
        }
        pendingJobs.removeValue(forKey: jobID)
        activeWorkerCount += 1

        let partitionToRun = selectedPartition
        Task { [weak self] in
            await self?.executeJob(
                id: jobID,
                jobType: jobType,
                partitionKey: partitionToRun
            )
        }

        // Check if more workers can be spun up concurrently
        if activeWorkerCount < maxConcurrentWorkers {
            triggerProcessing()
        }
    }

    private func executeJob(
        id: String,
        jobType: String,
        partitionKey: String?
    ) async {
        defer {
            activeWorkerCount -= 1
            if let partition = partitionKey {
                runningPartitions.remove(partition)
            }
            triggerProcessing()
        }

        // Verify reachability if configured
        if let reachability, !(await reachability.isConnected) {
            // Delay execution until online
            pendingJobs[id] = (type: jobType, partitionKey: partitionKey, nextEligibleAt: Date().addingTimeInterval(5.0))
            return
        }

        // Execute via registered handler or ad-hoc executor
        var executionError: (any Error)?

        do {
            if let adHoc = adHocExecutors[id] {
                try await adHoc()
                adHocExecutors.removeValue(forKey: id)
            } else if let handler = registeredHandlers[jobType] {
                let pending = try await storage.loadAllPendingJobInfo()
                guard let info = pending.first(where: { $0.id == id }) else {
                    throw URLError(.fileDoesNotExist)
                }
                try await handler(info.payloadData)
            } else {
                throw URLError(.unsupportedURL)
            }
        } catch {
            executionError = error
        }

        if let error = executionError {
            await handleFailure(id: id, jobType: jobType, partitionKey: partitionKey, error: error)
        } else {
            // Job Succeeded
            pendingJobs.removeValue(forKey: id)
            adHocExecutors.removeValue(forKey: id)
            try? await storage.updateJobStatus(id: id, status: .completed)
        }
    }

    private func handleFailure(
        id: String,
        jobType: String,
        partitionKey: String?,
        error: any Error
    ) async {
        let classification = errorClassifier.classify(error, statusCode: nil)

        switch classification {
        case .permanent(let reason):
            // Fail immediately without retries
            pendingJobs.removeValue(forKey: id)
            adHocExecutors.removeValue(forKey: id)
            try? await storage.updateJobStatus(id: id, status: .failed(reason: reason))

        case .transient(let explicitDelay):
            // Calculate delay with exponential backoff and jitter
            let delay = explicitDelay ?? calculateBackoffDelay(attempt: 1)
            let nextEligible = Date().addingTimeInterval(delay)

            // Re-enqueue for retry
            pendingJobs[id] = (type: jobType, partitionKey: partitionKey, nextEligibleAt: nextEligible)
            try? await storage.updateJobStatus(id: id, status: .retrying(attempt: 1, nextRetryAt: nextEligible))
        }
    }

    /// Computes exponential delay with jitter: `min(maxDelay, base * multiplier^attempt) + jitter`.
    public func calculateBackoffDelay(attempt: Int) -> TimeInterval {
        let exp = baseDelay * pow(multiplier, Double(max(0, attempt - 1)))
        let capped = min(maxDelay, exp)
        let jitter = Double.random(in: 0...(capped * 0.25))
        return capped + jitter
    }
}
