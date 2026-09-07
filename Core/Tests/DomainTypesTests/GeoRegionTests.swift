import XCTest
@testable import DomainTypes

final class GeoRegionTests: XCTestCase {
    func testEqualFieldsAreEqual() {
        let first = GeoRegion(latitude: 56.49, longitude: 8.29, radius: 75_000)
        let second = GeoRegion(latitude: 56.49, longitude: 8.29, radius: 75_000)

        XCTAssertEqual(first, second)
    }

    func testDifferingRadiusIsNotEqual() {
        let first = GeoRegion(latitude: 56.49, longitude: 8.29, radius: 75_000)
        let second = GeoRegion(latitude: 56.49, longitude: 8.29, radius: 1_000)

        XCTAssertNotEqual(first, second)
    }

    func testCodableRoundTripPreservesEquality() throws {
        let region = GeoRegion(latitude: 56.49, longitude: 8.29, radius: 75_000)

        let data = try JSONEncoder().encode(region)
        let decoded = try JSONDecoder().decode(GeoRegion.self, from: data)

        XCTAssertEqual(decoded, region)
    }
}
