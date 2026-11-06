import Foundation
import XCTest

@testable import DomainTypes

final class LightTests: XCTestCase {
    private let first = Date(timeIntervalSince1970: 1_700_000_000)
    private let last = Date(timeIntervalSince1970: 1_700_000_000 + 9 * 60 * 60)

    private var light: Light {
        Light(first: first, last: last)
    }

    private func makeEntry(light: Light?) -> SurfEntry {
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
            tide: nil,
            light: light
        )
    }

    func testNextIsTheEarlierChangeWhenBothAreAhead() {
        XCTAssertEqual(light.next(after: first.addingTimeInterval(-60)), first)
    }

    func testNextIsTheLaterChangeOnceTheEarlierHasPassed() {
        XCTAssertEqual(light.next(after: first.addingTimeInterval(60)), last)
    }

    func testNoNextChangeOnceBothHavePassed() {
        XCTAssertNil(light.next(after: last.addingTimeInterval(60)))
    }

    func testAChangeAtTheGivenDateHasAlreadyPassed() {
        XCTAssertEqual(light.next(after: first), last)
    }

    func testEntryCachedBeforeLightExistedDecodesWithoutLight() throws {
        let encoded = try JSONEncoder().encode(makeEntry(light: light))
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])

        object.removeValue(forKey: "light")

        let legacy = try JSONSerialization.data(withJSONObject: object)
        let decoded = try JSONDecoder().decode(SurfEntry.self, from: legacy)

        XCTAssertNil(decoded.light)
    }

    func testEntryWithLightRoundTripsThroughCoding() throws {
        let entry = makeEntry(light: light)

        let decoded = try JSONDecoder().decode(SurfEntry.self, from: JSONEncoder().encode(entry))

        XCTAssertEqual(decoded, entry)
    }
}
