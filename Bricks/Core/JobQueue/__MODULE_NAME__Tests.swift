import Foundation
import XCTest
@testable import __APP_MODULE__

final class __MODULE_NAME__Tests: XCTestCase {
    struct TestPayload: JobPayload {
        static var jobType: String = "test_job"
        let idempotencyKey: String
        let partitionKey: String?
        let value: String

        init(idempotencyKey: String = UUID().uuidString, partitionKey: String? = nil, value: String = "test") {
            self.idempotencyKey = idempotencyKey
            self.partitionKey = partitionKey
            self.value = value
        }
    }

    private actor TestRecorder {
        private(set) var count = 0
        private(set) var log: [Int] = []

        func increment() {
            count += 1
        }

        func append(_ value: Int) {
            log.append(value)
        }
    }

    func testEnqueueAndExecution() async throws {
        let queue = __MODULE_NAME__(storage: InMemoryJobStorage())
        let expectation = expectation(description: "Job executed")

        let payload = TestPayload(value: "hello")
        try await queue.enqueue(payload) {
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 2.0)
    }

    func testIdempotencyDeduplication() async throws {
        let queue = __MODULE_NAME__(storage: InMemoryJobStorage())
        let recorder = TestRecorder()
        let key = "idempotent_key_123"

        let payload1 = TestPayload(idempotencyKey: key, value: "first")
        let payload2 = TestPayload(idempotencyKey: key, value: "second")

        let exp = expectation(description: "Executed once")

        try await queue.enqueue(payload1) {
            await recorder.increment()
            exp.fulfill()
        }

        // Second enqueue with identical key while first is queued
        try await queue.enqueue(payload2) {
            await recorder.increment()
        }

        await fulfillment(of: [exp], timeout: 2.0)
        let count = await recorder.count
        XCTAssertEqual(count, 1, "Duplicate idempotency key must not trigger second execution")
    }

    func testPartitionSerialOrdering() async throws {
        let queue = __MODULE_NAME__(storage: InMemoryJobStorage(), maxConcurrentWorkers: 4)
        let recorder = TestRecorder()
        let partition = "user_account_1"

        let exp1 = expectation(description: "Job 1 executed")
        let exp2 = expectation(description: "Job 2 executed")

        let p1 = TestPayload(idempotencyKey: "j1", partitionKey: partition, value: "1")
        let p2 = TestPayload(idempotencyKey: "j2", partitionKey: partition, value: "2")

        try await queue.enqueue(p1) {
            try? await Task.sleep(nanoseconds: 50_000_000)
            await recorder.append(1)
            exp1.fulfill()
        }

        try await queue.enqueue(p2) {
            await recorder.append(2)
            exp2.fulfill()
        }

        await fulfillment(of: [exp1, exp2], timeout: 2.0)
        let log = await recorder.log
        XCTAssertEqual(log, [1, 2], "Jobs with identical partition key must run sequentially in FIFO order")
    }

    func testErrorClassification() {
        let classifier = DefaultJobErrorClassifier()

        let timeout = URLError(.timedOut)
        XCTAssertEqual(classifier.classify(timeout, statusCode: nil), .transient(retryAfter: nil))

        let offline = URLError(.notConnectedToInternet)
        XCTAssertEqual(classifier.classify(offline, statusCode: nil), .transient(retryAfter: nil))

        let badRequest = classifier.classify(URLError(.badURL), statusCode: 400)
        if case .permanent = badRequest {
            // Success
        } else {
            XCTFail("Status 400 should be classified as permanent error")
        }
    }

    func testMutationIntentDeclarativeSerialization() throws {
        struct TaskPayload: Codable, Sendable, Equatable {
            let title: String
        }

        let intent = MutationIntent(
            jobId: "job-1",
            idempotencyKey: "idem-1",
            entity: "task",
            operation: .create,
            localId: "local-task-123",
            payload: TaskPayload(title: "Buy milk")
        )

        XCTAssertEqual(intent.partitionKey, "local-task-123")
        let data = try JSONEncoder().encode(intent)
        let decoded = try JSONDecoder().decode(MutationIntent<TaskPayload>.self, from: data)
        XCTAssertEqual(decoded, intent)
    }

    func testColdStartPersistentJobRestoration() async throws {
        let storage = InMemoryJobStorage()
        let queue1 = __MODULE_NAME__(storage: storage)

        let payload = TestPayload(idempotencyKey: "cold_start_id", value: "restore_me")
        try await queue1.enqueue(payload)

        // Simulate fresh app launch with fresh queue instance over same storage
        let queue2 = __MODULE_NAME__(storage: storage)
        let exp = expectation(description: "Restored job executed via registered handler")

        await queue2.registerHandler(for: TestPayload.self) { loadedPayload in
            if loadedPayload.value == "restore_me" {
                exp.fulfill()
            }
        }

        let restoredCount = try await queue2.restorePendingJobs()
        XCTAssertEqual(restoredCount, 1)

        await fulfillment(of: [exp], timeout: 2.0)
    }
}
