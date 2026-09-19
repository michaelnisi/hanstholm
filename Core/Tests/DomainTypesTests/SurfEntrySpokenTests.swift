import XCTest
@testable import DomainTypes

final class SurfEntrySpokenTests: XCTestCase {
    private let place = Place(pluginID: "test", key: "spot", name: "Hanstholm")

    func testWindSpokenDescribesSpeedAndDirection() {
        let wind = SurfEntry.Wind(
            speed: .init(gust: 9, middle: 6, current: 6),
            direction: .init(cardinal: .southWest)
        )

        XCTAssertEqual(wind.spoken, "wind is 12 knots from southwest")
    }

    func testWaveSpokenDescribesHeightPeriodAndDirection() {
        let wave = SurfEntry.Wave(max: 1.2, middle: 0.9, period: 8, direction: .init(cardinal: .northWest))

        XCTAssertEqual(wave.spoken, "waves are 3 feet at 8 seconds from northwest")
    }

    func testSpokenSummaryComposesPlaceWindAndWave() {
        let wind = SurfEntry.Wind(
            speed: .init(gust: 9, middle: 6, current: 6),
            direction: .init(cardinal: .southWest)
        )
        let wave = SurfEntry.Wave(max: 1.2, middle: 0.9, period: 8, direction: .init(cardinal: .northWest))
        let entry = SurfEntry(date: .now, place: place, status: .ok, wave: wave, wind: wind)

        XCTAssertEqual(
            entry.spokenSummary,
            "At Hanstholm, wind is 12 knots from southwest, and waves are 3 feet at 8 seconds from northwest."
        )
    }
}
