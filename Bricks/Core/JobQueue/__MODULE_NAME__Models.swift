import Foundation

/// Lifecycle status of an asynchronous job in the queue.
public enum JobStatus: Codable, Equatable, Sendable {
    case pending
    case running
    case retrying(attempt: Int, nextRetryAt: Date)
    case completed
    case failed(reason: String)
    case cancelled

    public var isTerminal: Bool {
        switch self {
        case .completed, .failed, .cancelled:
            return true
        case .pending, .running, .retrying:
            return false
        }
    }
}

/// Protocol for a serializable, idempotent job payload.
public protocol JobPayload: Codable, Sendable, Equatable {
    /// Unique identifier for the type of job (e.g. "sync_profile", "upload_media").
    static var jobType: String { get }

    /// Idempotency key used for deduplication in the queue and server idempotency headers.
    var idempotencyKey: String { get }

    /// Optional partition key. Jobs sharing the same partition key execute strictly serially.
    var partitionKey: String? { get }
}

public extension JobPayload {
    var partitionKey: String? { nil }
}

/// Protocol for API network mutation jobs that map directly into an HTTP request.
public protocol APIJobPayload: JobPayload {
    /// Builds a Foundation `URLRequest` configured with method, headers (including Idempotency-Key), and body.
    func makeURLRequest(baseURL: URL) throws -> URLRequest
}

/// Standard business mutation operations for declarative outbox intents.
public enum MutationOperation: String, Codable, Sendable, Equatable {
    case create
    case update
    case delete
    case custom
}

/// A declarative, durable business mutation intent suitable for persistent outbox queues.
///
/// Encapsulates the complete business intent (entity, operation, localId, payload) rather than
/// an arbitrary execution closure, enabling safe replays across app restarts and crashes.
public struct MutationIntent<Payload: Codable & Sendable & Equatable>: JobPayload {
    public static var jobType: String {
        "mutation_\(String(describing: Payload.self))"
    }

    public let jobId: String
    public let idempotencyKey: String
    public let entity: String
    public let operation: MutationOperation
    public let localId: String?
    public let payload: Payload

    public var partitionKey: String? {
        localId ?? entity
    }

    public init(
        jobId: String = UUID().uuidString,
        idempotencyKey: String = UUID().uuidString,
        entity: String,
        operation: MutationOperation,
        localId: String? = nil,
        payload: Payload
    ) {
        self.jobId = jobId
        self.idempotencyKey = idempotencyKey
        self.entity = entity
        self.operation = operation
        self.localId = localId
        self.payload = payload
    }
}

/// Metadata record tracking the state and execution history of an enqueued job.
public struct JobRecord<Payload: JobPayload>: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public let jobType: String
    public let partitionKey: String?
    public let payload: Payload
    public var status: JobStatus
    public var attempts: Int
    public let maxAttempts: Int
    public let createdAt: Date
    public var lastAttemptAt: Date?

    public init(
        payload: Payload,
        maxAttempts: Int = 3,
        status: JobStatus = .pending,
        attempts: Int = 0,
        createdAt: Date = Date(),
        lastAttemptAt: Date? = nil
    ) {
        self.id = payload.idempotencyKey
        self.jobType = Payload.jobType
        self.partitionKey = payload.partitionKey
        self.payload = payload
        self.maxAttempts = max(1, maxAttempts)
        self.status = status
        self.attempts = attempts
        self.createdAt = createdAt
        self.lastAttemptAt = lastAttemptAt
    }
}

/// Classification of job execution errors into transient (retryable) or permanent (fatal).
public enum JobErrorCategory: Equatable, Sendable {
    /// Error is temporary (e.g. network timeout, 503, 429). The job should be retried after an interval.
    case transient(retryAfter: TimeInterval?)

    /// Error is non-recoverable (e.g. 400 Bad Request, 404, 422 Unprocessable). The job fails immediately.
    case permanent(reason: String)
}

/// Protocol for inspecting errors and determining if they are transient or permanent.
public protocol JobErrorClassifier: Sendable {
    func classify(_ error: any Error, statusCode: Int?) -> JobErrorCategory
}

/// Default classifier handling standard Foundation URLErrors and HTTP status codes.
public struct DefaultJobErrorClassifier: JobErrorClassifier {
    public init() {}

    public func classify(_ error: any Error, statusCode: Int?) -> JobErrorCategory {
        if let statusCode {
            switch statusCode {
            case 408: // Request Timeout
                return .transient(retryAfter: nil)
            case 429: // Too Many Requests
                return .transient(retryAfter: nil)
            case 500, 502, 503, 504: // Server errors
                return .transient(retryAfter: nil)
            case 400...499: // Client errors
                return .permanent(reason: "Client error with HTTP status \(statusCode).")
            default:
                break
            }
        }

        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut,
                 .cannotFindHost,
                 .cannotConnectToHost,
                 .networkConnectionLost,
                 .notConnectedToInternet,
                 .dnsLookupFailed:
                return .transient(retryAfter: nil)
            default:
                return .permanent(reason: urlError.localizedDescription)
            }
        }

        if error is CancellationError {
            return .permanent(reason: "Operation was cancelled.")
        }

        return .transient(retryAfter: nil)
    }
}
