import Foundation

/// Type-erased stored job representation for inspecting and recovering jobs across cold-starts.
public struct StoredJobInfo: Sendable, Equatable {
    public let id: String
    public let jobType: String
    public let partitionKey: String?
    public let status: JobStatus
    public let payloadData: Data
    public let createdAt: Date

    public init(
        id: String,
        jobType: String,
        partitionKey: String?,
        status: JobStatus,
        payloadData: Data,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.jobType = jobType
        self.partitionKey = partitionKey
        self.status = status
        self.payloadData = payloadData
        self.createdAt = createdAt
    }
}

private struct StoredJobHeader: Decodable {
    let id: String
    let jobType: String
    let partitionKey: String?
    let status: JobStatus
    let createdAt: Date
}

private func parseStoredJobInfo(from data: Data) -> StoredJobInfo? {
    let decoder = JSONDecoder()
    guard let header = try? decoder.decode(StoredJobHeader.self, from: data) else {
        return nil
    }
    guard let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
          let payloadObj = json["payload"],
          let payloadData = try? JSONSerialization.data(withJSONObject: payloadObj) else {
        return nil
    }
    return StoredJobInfo(
        id: header.id,
        jobType: header.jobType,
        partitionKey: header.partitionKey,
        status: header.status,
        payloadData: payloadData,
        createdAt: header.createdAt
    )
}

private func updateStatusInData(_ data: Data, newStatus: JobStatus) -> Data? {
    guard var json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
          let statusData = try? JSONEncoder().encode(newStatus),
          let statusObj = try? JSONSerialization.jsonObject(with: statusData) else {
        return nil
    }
    json["status"] = statusObj
    return try? JSONSerialization.data(withJSONObject: json, options: [])
}

/// Abstract persistence interface for storing and retrieving serialized job records.
public protocol JobStorageProtocol: Sendable {
    func saveJob<P: JobPayload>(_ record: JobRecord<P>) async throws
    func loadJob<P: JobPayload>(id: String, as: P.Type) async throws -> JobRecord<P>?
    func loadAllJobs<P: JobPayload>(as: P.Type) async throws -> [JobRecord<P>]
    func loadAllPendingJobInfo() async throws -> [StoredJobInfo]
    func updateJobStatus(id: String, status: JobStatus) async throws
    func deleteJob(id: String) async throws
    func clear() async throws
}

/// In-memory ephemeral storage for jobs. Suitable for non-critical queues within a single app session.
public actor InMemoryJobStorage: JobStorageProtocol {
    private var storage: [String: Data] = [:]
    private let jsonEncoder = JSONEncoder()
    private let jsonDecoder = JSONDecoder()

    public init() {}

    public func saveJob<P: JobPayload>(_ record: JobRecord<P>) async throws {
        let data = try jsonEncoder.encode(record)
        storage[record.id] = data
    }

    public func loadJob<P: JobPayload>(id: String, as: P.Type) async throws -> JobRecord<P>? {
        guard let data = storage[id] else { return nil }
        return try jsonDecoder.decode(JobRecord<P>.self, from: data)
    }

    public func loadAllJobs<P: JobPayload>(as: P.Type) async throws -> [JobRecord<P>] {
        var results: [JobRecord<P>] = []
        for (_, data) in storage {
            if let record = try? jsonDecoder.decode(JobRecord<P>.self, from: data) {
                results.append(record)
            }
        }
        return results.sorted { $0.createdAt < $1.createdAt }
    }

    public func loadAllPendingJobInfo() async throws -> [StoredJobInfo] {
        var results: [StoredJobInfo] = []
        for (_, data) in storage {
            if let info = parseStoredJobInfo(from: data), !info.status.isTerminal {
                results.append(info)
            }
        }
        return results.sorted { $0.createdAt < $1.createdAt }
    }

    public func updateJobStatus(id: String, status: JobStatus) async throws {
        guard let data = storage[id],
              let updated = updateStatusInData(data, newStatus: status) else {
            return
        }
        storage[id] = updated
    }

    public func deleteJob(id: String) async throws {
        storage.removeValue(forKey: id)
    }

    public func clear() async throws {
        storage.removeAll()
    }
}

/// Disk-backed persistent storage for jobs. Saves serialized JSON files so jobs survive app restarts and crashes.
public actor DiskJobStorage: JobStorageProtocol {
    private let directoryURL: URL
    private let fileManager = FileManager.default
    private let jsonEncoder = JSONEncoder()
    private let jsonDecoder = JSONDecoder()

    public init(folderName: String = "SwiftBlockJobQueue") {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        self.directoryURL = base.appendingPathComponent(folderName, isDirectory: true)
        try? fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }

    public init(directoryURL: URL) {
        self.directoryURL = directoryURL
        try? fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }

    private func fileURL(for id: String) -> URL {
        let sanitized = id.replacingOccurrences(of: "/", with: "_")
        return directoryURL.appendingPathComponent("\(sanitized).json")
    }

    public func saveJob<P: JobPayload>(_ record: JobRecord<P>) async throws {
        let data = try jsonEncoder.encode(record)
        let url = fileURL(for: record.id)
        try data.write(to: url, options: .atomic)
    }

    public func loadJob<P: JobPayload>(id: String, as: P.Type) async throws -> JobRecord<P>? {
        let url = fileURL(for: id)
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        let data = try Data(contentsOf: url)
        return try jsonDecoder.decode(JobRecord<P>.self, from: data)
    }

    public func loadAllJobs<P: JobPayload>(as: P.Type) async throws -> [JobRecord<P>] {
        guard let files = try? fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil) else {
            return []
        }
        var results: [JobRecord<P>] = []
        for file in files where file.pathExtension == "json" {
            if let data = try? Data(contentsOf: file),
               let record = try? jsonDecoder.decode(JobRecord<P>.self, from: data) {
                results.append(record)
            }
        }
        return results.sorted { $0.createdAt < $1.createdAt }
    }

    public func loadAllPendingJobInfo() async throws -> [StoredJobInfo] {
        guard let files = try? fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil) else {
            return []
        }
        var results: [StoredJobInfo] = []
        for file in files where file.pathExtension == "json" {
            if let data = try? Data(contentsOf: file),
               let info = parseStoredJobInfo(from: data),
               !info.status.isTerminal {
                results.append(info)
            }
        }
        return results.sorted { $0.createdAt < $1.createdAt }
    }

    public func updateJobStatus(id: String, status: JobStatus) async throws {
        let url = fileURL(for: id)
        guard fileManager.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let updated = updateStatusInData(data, newStatus: status) else {
            return
        }
        try updated.write(to: url, options: .atomic)
    }

    public func deleteJob(id: String) async throws {
        let url = fileURL(for: id)
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }

    public func clear() async throws {
        guard let files = try? fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil) else {
            return
        }
        for file in files {
            try? fileManager.removeItem(at: file)
        }
    }
}
