//
//  SurfEntryHydeTests.swift
//
//
//  Created by Michael Nisi on 11.07.26.
//

import XCTest
import Hyde
@testable import DomainTypes

final class SurfEntryHydeTests: XCTestCase {

    // MARK: SurfEntry.Wave

    func testWaveInitSucceedsWithCompleteDTO() {
        let dto = Hyde.Wave(height: .init(max: 2, middle: 1.2), period: 8, direction: "NV")
        let wave = SurfEntry.Wave(dto: dto)

        XCTAssertEqual(wave?.max, 2)
        XCTAssertEqual(wave?.middle, 1.2)
        XCTAssertEqual(wave?.period, 8)
        XCTAssertEqual(wave?.direction.cardinal, .northWest)
    }

    func testWaveInitFailsWhenDirectionMissing() {
        let dto = Hyde.Wave(height: .init(max: 2, middle: 1.2), period: 8, direction: nil)
        XCTAssertNil(SurfEntry.Wave(dto: dto))
    }

    func testWaveInitFailsWhenHeightMissing() {
        let dto = Hyde.Wave(height: nil, period: 8, direction: "NV")
        XCTAssertNil(SurfEntry.Wave(dto: dto))
    }

    func testWaveInitFailsWhenPeriodMissing() {
        let dto = Hyde.Wave(height: .init(max: 2, middle: 1.2), period: nil, direction: "NV")
        XCTAssertNil(SurfEntry.Wave(dto: dto))
    }

    func testWaveInitFailsWhenDTOIsNil() {
        XCTAssertNil(SurfEntry.Wave(dto: nil))
    }

    // MARK: SurfEntry.Wind.Speed

    func testWindSpeedInitSucceedsWithCompleteDTO() {
        let dto = Hyde.Wind.Speed(gust: 15, middle: 7, current: 8)
        let speed = SurfEntry.Wind.Speed(dto: dto)

        XCTAssertEqual(speed?.gust, 15)
        XCTAssertEqual(speed?.middle, 7)
        XCTAssertEqual(speed?.current, 8)
    }

    func testWindSpeedInitFailsWhenGustMissing() {
        XCTAssertNil(SurfEntry.Wind.Speed(dto: .init(gust: nil, middle: 7, current: 8)))
    }

    func testWindSpeedInitFailsWhenMiddleMissing() {
        XCTAssertNil(SurfEntry.Wind.Speed(dto: .init(gust: 15, middle: nil, current: 8)))
    }

    func testWindSpeedInitFailsWhenCurrentMissing() {
        XCTAssertNil(SurfEntry.Wind.Speed(dto: .init(gust: 15, middle: 7, current: nil)))
    }

    func testWindSpeedInitFailsWhenDTOIsNil() {
        XCTAssertNil(SurfEntry.Wind.Speed(dto: nil))
    }

    // MARK: SurfEntry.Wind

    func testWindInitSucceedsWithCompleteDTO() {
        let dto = Hyde.Wind(speed: .init(gust: 15, middle: 7, current: 8), direction: "SV")
        let wind = SurfEntry.Wind(dto: dto)

        XCTAssertEqual(wind?.direction.cardinal, .southWest)
        XCTAssertEqual(wind?.speed.current, 8)
    }

    func testWindInitFailsWhenDirectionInvalid() {
        let dto = Hyde.Wind(speed: .init(gust: 15, middle: 7, current: 8), direction: "not-a-direction")
        XCTAssertNil(SurfEntry.Wind(dto: dto))
    }

    func testWindInitFailsWhenSpeedIncomplete() {
        let dto = Hyde.Wind(speed: .init(gust: nil, middle: 7, current: 8), direction: "SV")
        XCTAssertNil(SurfEntry.Wind(dto: dto))
    }

    // MARK: SurfEntry

    func testSurfEntryInitSucceedsWithCompleteDTO() {
        let hyde = Hyde(
            place: .hanstholm,
            date: .now,
            wave: .init(height: .init(max: 2, middle: 1.2), period: 8, direction: "NV"),
            wind: .init(speed: .init(gust: 15, middle: 7, current: 8), direction: "SV")
        )

        let entry = SurfEntry(dto: hyde)

        XCTAssertNotNil(entry)
        XCTAssertEqual(entry?.name, "Hanstholm")
        XCTAssertEqual(entry?.status, .ok)
    }

    func testSurfEntryInitFailsWhenDTOIsNil() {
        XCTAssertNil(SurfEntry(dto: nil))
    }

    func testSurfEntryInitFailsWhenWaveIncomplete() {
        let hyde = Hyde(
            place: .hanstholm,
            date: .now,
            wave: .init(height: nil, period: 8, direction: "NV"),
            wind: .init(speed: .init(gust: 15, middle: 7, current: 8), direction: "SV")
        )

        XCTAssertNil(SurfEntry(dto: hyde))
    }

    func testSurfEntryInitFailsWhenWindIncomplete() {
        let hyde = Hyde(
            place: .hanstholm,
            date: .now,
            wave: .init(height: .init(max: 2, middle: 1.2), period: 8, direction: "NV"),
            wind: .init(speed: nil, direction: "SV")
        )

        XCTAssertNil(SurfEntry(dto: hyde))
    }
}
