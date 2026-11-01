import DomainTypes
import Foundation
import Hummingbird
import HummingbirdTesting
import XCTest

@testable import Server

final class ServerTests: XCTestCase {
    func testHealthReturnsOK() async throws {
        let app = buildApplication(host: "127.0.0.1", port: 0)

        try await app.test(.router) { client in
            try await client.execute(uri: "/health", method: .get) { response in
                XCTAssertEqual(response.status, .ok)
            }
        }
    }

    func testSurfEntryRoundTripsThroughJSON() throws {
        let entry = SurfEntry(
            date: Date(timeIntervalSince1970: 0),
            place: Place(pluginID: "test", key: "spot", name: "Spot"),
            status: .ok,
            wave: .init(
                max: 2, middle: 1, period: 8, direction: Direction(cardinal: .northEast)),
            wind: .init(
                speed: .init(gust: nil, middle: 5, current: 6),
                direction: Direction(cardinal: .south))
        )

        let data = try JSONEncoder().encode(entry)
        let decoded = try JSONDecoder().decode(SurfEntry.self, from: data)

        XCTAssertEqual(decoded, entry)
    }
}
