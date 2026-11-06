import Foundation
import XCTest

@testable import DomainTypes

final class TideTests: XCTestCase {
    private let low = Date(timeIntervalSince1970: 1_700_000_000)
    private let high = Date(timeIntervalSince1970: 1_700_000_000 + 6 * 60 * 60)

    private var tide: Tide {
        Tide(high: high, low: low)
    }

    private func makeEntry(tide: Tide?) -> SurfEntry {
        SurfEntry(
            date: Date(timeIntervalSince1970: 1_700_000_000),
            place: Place(pluginID: "test.stub", key: "hanstholm", name: "Hanstholm"),
            status: .ok,
            wave: SurfEntry.Wave(
                max: 1.2, middle: 0.8, period: 8, direction: Direction(cardinal: .west)),
            wind: SurfEntry.Wind(
                speed: SurfEntry.Wind.Speed(gust: 12, middle: 9, current: 10),
                direction: Direction(cardinal: .west)
            ),
            tide: tide
        )
    }

    func testNextIsTheEarlierTurnWhenBothAreAhead() {
        XCTAssertEqual(tide.next(after: low.addingTimeInterval(-60)), low)
    }

    func testNextIsTheLaterTurnOnceTheEarlierHasPassed() {
        XCTAssertEqual(tide.next(after: low.addingTimeInterval(60)), high)
    }

    func testNoNextTurnOnceBothHavePassed() {
        XCTAssertNil(tide.next(after: high.addingTimeInterval(60)))
    }

    func testATurnAtTheGivenDateHasAlreadyPassed() {
        XCTAssertEqual(tide.next(after: low), high)
    }

    func testEntryCachedBeforeTidesExistedDecodesWithoutATide() throws {
        let encoded = try JSONEncoder().encode(makeEntry(tide: tide))
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])

        object.removeValue(forKey: "tide")

        let legacy = try JSONSerialization.data(withJSONObject: object)
        let decoded = try JSONDecoder().decode(SurfEntry.self, from: legacy)

        XCTAssertNil(decoded.tide)
    }

    func testEntryWithATideRoundTripsThroughCoding() throws {
        let entry = makeEntry(tide: tide)

        let decoded = try JSONDecoder().decode(SurfEntry.self, from: JSONEncoder().encode(entry))

        XCTAssertEqual(decoded, entry)
    }
}
