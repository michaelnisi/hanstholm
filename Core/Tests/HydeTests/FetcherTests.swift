//
//  FetcherTests.swift
//
//
//  Created by Michael Nisi on 11.07.26.
//

import XCTest
@testable import Hyde

final class FetcherTests: XCTestCase {
    func testDownloadedDataReturnsData() throws {
        let location = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let expected = Data("<html></html>".utf8)
        try expected.write(to: location)
        defer { try? FileManager.default.removeItem(at: location) }

        XCTAssertEqual(location.downloadedData(), expected)
    }

    func testDownloadedDataReturnsNilForMissingFile() {
        let missing = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

        XCTAssertNil(missing.downloadedData())
    }

    func testUpdateStoresData() async throws {
        let fetcher = Fetcher()
        let payload = Data("hello".utf8)

        await fetcher.update(data: payload)

        let cached = await fetcher.cached
        XCTAssertEqual(cached, payload)
    }

    func testUpdateStoresNilWhenGivenNil() async throws {
        let fetcher = Fetcher()

        await fetcher.update(data: nil)

        let cached = await fetcher.cached
        XCTAssertNil(cached)
    }
}
