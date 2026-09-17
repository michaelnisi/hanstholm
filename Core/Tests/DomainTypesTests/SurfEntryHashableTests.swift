import XCTest
import Foundation
@testable import DomainTypes

final class SurfEntryHashableTests: XCTestCase {
    private func makePlace() -> Place {
        Place(pluginID: "test.stub", key: "hanstholm", name: "Hanstholm")
    }

    private func makeWave(direction: Direction = Direction(cardinal: .west)) -> SurfEntry.Wave {
        SurfEntry.Wave(max: 1.2, middle: 0.8, period: 8, direction: direction)
    }

    private func makeWind(direction: Direction = Direction(cardinal: .west)) -> SurfEntry.Wind {
        SurfEntry.Wind(
            speed: SurfEntry.Wind.Speed(gust: 12, middle: 9, current: 10),
            direction: direction
        )
    }

    private func makeEntry(
        date: Date = Date(timeIntervalSince1970: 1_700_000_000),
        wave: SurfEntry.Wave? = nil,
        wind: SurfEntry.Wind? = nil
    ) -> SurfEntry {
        SurfEntry(
            date: date,
            place: makePlace(),
            status: .ok,
            wave: wave ?? makeWave(),
            wind: wind ?? makeWind()
        )
    }

    func testEqualEntriesHashEqually() {
        let first = makeEntry()
        let second = makeEntry()

        XCTAssertEqual(first, second)
        XCTAssertEqual(Set([first, second]).count, 1)
    }

    func testEntriesDifferingOnlyInWaveAreNotEqualAndBothSurviveASet() {
        let first = makeEntry(wave: makeWave())
        let second = makeEntry(wave: makeWave(direction: Direction(cardinal: .east)))

        XCTAssertNotEqual(first, second)
        XCTAssertEqual(Set([first, second]).count, 2)
    }

    func testEntriesDifferingOnlyInWindAreNotEqualAndBothSurviveASet() {
        let first = makeEntry(wind: makeWind())
        let second = makeEntry(wind: makeWind(direction: Direction(cardinal: .east)))

        XCTAssertNotEqual(first, second)
        XCTAssertEqual(Set([first, second]).count, 2)
    }

    func testIDIsStableForTheSamePlaceAndDate() {
        let first = makeEntry()
        let second = makeEntry()

        XCTAssertEqual(first.id, second.id)
    }

    func testIDDiffersForDatesLessThanAMinuteApart() {
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        let first = makeEntry(date: base)
        let second = makeEntry(date: base.addingTimeInterval(30))

        XCTAssertNotEqual(first.id, second.id)
    }
}
