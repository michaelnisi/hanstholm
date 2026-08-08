import XCTest
import DomainTypes
@testable import Conditions

private actor EventLog {
    private(set) var events: [String] = []

    func record(_ event: String) {
        events.append(event)
    }
}

final class DeferredDownloaderTests: XCTestCase {
    private let session = URLSession(configuration: .ephemeral)
    private let place = Place(pluginID: "test.stub", key: "hanstholm", name: "Hanstholm")

    private func makeDownloadTask(taskDescription: String?) -> URLSessionDownloadTask {
        let task = session.downloadTask(with: URL(string: "https://example.invalid")!)
        task.taskDescription = taskDescription
        return task
    }

    private func writeTempFile(_ data: Data) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try data.write(to: url)
        return url
    }

    func testDidFinishDownloadingRoutesDataMimeTypeAndTokenToIngest() async throws {
        let downloader = DeferredDownloader(configuration: .init())
        let token = DeferredDownloader.Token(place: place)
        let payload = Data("payload".utf8)
        let fileURL = try writeTempFile(payload)
        defer { try? FileManager.default.removeItem(at: fileURL) }

        let ingested = expectation(description: "ingest called")
        let log = EventLog()

        downloader.setIngest { data, mimeType, receivedToken in
            await log.record("data:\(data == payload) mimeType:\(mimeType ?? "nil") token:\(receivedToken == token)")
            ingested.fulfill()
        }

        downloader.urlSession(session, downloadTask: makeDownloadTask(taskDescription: token.encoded()), didFinishDownloadingTo: fileURL)

        await fulfillment(of: [ingested], timeout: 1)

        let events = await log.events
        XCTAssertEqual(events, ["data:true mimeType:nil token:true"])
    }

    func testDidFinishDownloadingSkipsIngestWhenPayloadIsUnreadable() async throws {
        let downloader = DeferredDownloader(configuration: .init())
        let token = DeferredDownloader.Token(place: place)
        let missingFileURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

        let log = EventLog()

        downloader.setIngest { _, _, _ in
            await log.record("ingest")
        }

        downloader.urlSession(session, downloadTask: makeDownloadTask(taskDescription: token.encoded()), didFinishDownloadingTo: missingFileURL)

        try await Task.sleep(nanoseconds: 100_000_000)

        let events = await log.events
        XCTAssertTrue(events.isEmpty)
    }
}
