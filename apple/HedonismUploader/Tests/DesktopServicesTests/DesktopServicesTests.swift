import XCTest
import CogsworthIPC
@testable import HedonismUploader

@MainActor
private final class FakeWorker: MLWorkerTransport {
    var configurations: [WorkerConfiguration] = []
    var status: ((String) -> Void)?
    var finished: ((String?) -> Void)?
    var stops = 0
    func start(_ configuration: WorkerConfiguration, status: @escaping (String) -> Void,
               finished: @escaping (String?) -> Void, reply: @escaping (String?) -> Void) {
        configurations.append(configuration); self.status = status; self.finished = finished
        reply(nil)
    }
    func stop() { stops += 1 }
}

@MainActor
final class DesktopServicesTests: XCTestCase {
    func testRequiresAuthenticationAndSecureEndpoint() {
        let worker = FakeWorker()
        let services = DesktopServices(makeWorker: { worker })
        services.start(server: "https://example.com", token: "")
        XCTAssertEqual(services.status, "Sign in to start the service")
        services.start(server: "http://example.com", token: "secret")
        XCTAssertEqual(services.status, "Enter a valid server URL")
        XCTAssertTrue(worker.configurations.isEmpty)
    }

    func testSingleSessionReadinessAndStopWaitsForInvalidation() {
        let worker = FakeWorker()
        let services = DesktopServices(makeWorker: { worker })
        services.start(server: "https://example.com", token: "secret")
        services.start(server: "https://example.com", token: "secret")
        XCTAssertEqual(worker.configurations.count, 1)
        XCTAssertTrue(services.isRunning)
        XCTAssertFalse(services.isReady)
        worker.status?("COGSWORTH_READY")
        XCTAssertTrue(services.isReady)
        services.stop()
        worker.status?("COGSWORTH_READY")
        XCTAssertFalse(services.isReady)
        XCTAssertTrue(services.isStopping)
        services.start(server: "https://example.com", token: "secret")
        XCTAssertEqual(worker.configurations.count, 1)
        worker.finished?(nil)
        XCTAssertFalse(services.isRunning)
        XCTAssertFalse(services.isStopping)
        XCTAssertEqual(worker.stops, 1)
    }

    func testAuthenticationStatusSurvivesWorkerExitAndOldEventsAreIgnored() {
        var workers: [FakeWorker] = []
        let services = DesktopServices(makeWorker: { let worker = FakeWorker(); workers.append(worker); return worker })
        services.start(server: "https://example.com", token: "old")
        workers[0].status?("COGSWORTH_AUTH_REQUIRED")
        workers[0].finished?(nil)
        XCTAssertEqual(services.status, "Sign in again to reconnect the service")
        services.start(server: "https://example.com", token: "new")
        workers[0].finished?("old error")
        workers[0].status?("COGSWORTH_READY")
        XCTAssertTrue(services.isRunning)
        XCTAssertFalse(services.isReady)
        workers[1].status?("COGSWORTH_READY")
        XCTAssertTrue(services.isReady)
        services.stop(); workers[1].finished?(nil)
    }
}
