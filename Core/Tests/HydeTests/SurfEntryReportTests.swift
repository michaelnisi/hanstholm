import XCTest
import DomainTypes
@testable import Hyde

final class SurfEntryReportTests: XCTestCase {
    private let place = Hyde.Station.hanstholm.place

    func testWaveInitSucceedsWithCompleteReport() {
        let report = Report.Wave(height: .init(max: 2, middle: 1.2), period: 8, direction: "NV")
        let wave = SurfEntry.Wave(report: report)

        XCTAssertEqual(wave?.max, 2)
        XCTAssertEqual(wave?.middle, 1.2)
        XCTAssertEqual(wave?.period, 8)
        XCTAssertEqual(wave?.direction.cardinal, .northWest)
    }

    func testWaveInitFailsWhenDirectionMissing() {
        let report = Report.Wave(height: .init(max: 2, middle: 1.2), period: 8, direction: nil)
        XCTAssertNil(SurfEntry.Wave(report: report))
    }

    func testWaveInitFailsWhenHeightMissing() {
        let report = Report.Wave(height: nil, period: 8, direction: "NV")
        XCTAssertNil(SurfEntry.Wave(report: report))
    }

    func testWaveInitFailsWhenPeriodMissing() {
        let report = Report.Wave(height: .init(max: 2, middle: 1.2), period: nil, direction: "NV")
        XCTAssertNil(SurfEntry.Wave(report: report))
    }

    func testWaveInitFailsWhenReportIsNil() {
        XCTAssertNil(SurfEntry.Wave(report: nil))
    }

    func testWindSpeedInitSucceedsWithCompleteReport() {
        let report = Report.Wind.Speed(gust: 15, middle: 7, current: 8)
        let speed = SurfEntry.Wind.Speed(report: report)

        XCTAssertEqual(speed?.gust, 15)
        XCTAssertEqual(speed?.middle, 7)
        XCTAssertEqual(speed?.current, 8)
    }

    func testWindSpeedInitFailsWhenGustMissing() {
        XCTAssertNil(SurfEntry.Wind.Speed(report: .init(gust: nil, middle: 7, current: 8)))
    }

    func testWindSpeedInitFailsWhenMiddleMissing() {
        XCTAssertNil(SurfEntry.Wind.Speed(report: .init(gust: 15, middle: nil, current: 8)))
    }

    func testWindSpeedInitFailsWhenCurrentMissing() {
        XCTAssertNil(SurfEntry.Wind.Speed(report: .init(gust: 15, middle: 7, current: nil)))
    }

    func testWindSpeedInitFailsWhenReportIsNil() {
        XCTAssertNil(SurfEntry.Wind.Speed(report: nil))
    }

    func testWindInitSucceedsWithCompleteReport() {
        let report = Report.Wind(speed: .init(gust: 15, middle: 7, current: 8), direction: "SV")
        let wind = SurfEntry.Wind(report: report)

        XCTAssertEqual(wind?.direction.cardinal, .southWest)
        XCTAssertEqual(wind?.speed.current, 8)
    }

    func testWindInitFailsWhenDirectionInvalid() {
        let report = Report.Wind(speed: .init(gust: 15, middle: 7, current: 8), direction: "not-a-direction")
        XCTAssertNil(SurfEntry.Wind(report: report))
    }

    func testWindInitFailsWhenSpeedIncomplete() {
        let report = Report.Wind(speed: .init(gust: nil, middle: 7, current: 8), direction: "SV")
        XCTAssertNil(SurfEntry.Wind(report: report))
    }

    private func makeReport(wave: Report.Wave?, wind: Report.Wind?) -> Report {
        Report(station: .hanstholm, date: .now, wave: wave, wind: wind)
    }

    func testSurfEntryInitSucceedsWithCompleteReport() {
        let report = makeReport(
            wave: .init(height: .init(max: 2, middle: 1.2), period: 8, direction: "NV"),
            wind: .init(speed: .init(gust: 15, middle: 7, current: 8), direction: "SV")
        )

        let entry = SurfEntry(report: report, place: place)

        XCTAssertNotNil(entry)
        XCTAssertEqual(entry?.place, place)
        XCTAssertEqual(entry?.status, .ok)
    }

    func testSurfEntryInitFailsWhenReportIsNil() {
        XCTAssertNil(SurfEntry(report: nil, place: place))
    }

    func testSurfEntryInitFailsWhenWaveIncomplete() {
        let report = makeReport(
            wave: .init(height: nil, period: 8, direction: "NV"),
            wind: .init(speed: .init(gust: 15, middle: 7, current: 8), direction: "SV")
        )

        XCTAssertNil(SurfEntry(report: report, place: place))
    }

    func testSurfEntryInitFailsWhenWindIncomplete() {
        let report = makeReport(
            wave: .init(height: .init(max: 2, middle: 1.2), period: 8, direction: "NV"),
            wind: .init(speed: nil, direction: "SV")
        )

        XCTAssertNil(SurfEntry(report: report, place: place))
    }
}
