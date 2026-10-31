import XCTest

@testable import Hyde

final class ParserTests: XCTestCase {
    private var hanstholmParts: [String.SubSequence]!
    private var hvideSandeParts: [String.SubSequence]!
    private var thorsmindeParts: [String.SubSequence]!

    override func setUp() async throws {
        try await super.setUp()

        self.hanstholmParts = try hanstholmHTML.stripOutHtml().splitLines()
        self.hvideSandeParts = try hvideSandeHTML.stripOutHtml().splitLines()
        self.thorsmindeParts = try thorsmindeHTML.stripOutHtml().splitLines()
    }

    func testWaveHvideSande() {
        XCTAssertEqual(hvideSandeParts.middleWaveHeight()?.double(), 1.14)
        XCTAssertEqual(hvideSandeParts.maxWaveHeight()?.double(), 2.84)
        XCTAssertEqual(hvideSandeParts.wavePeriod()?.double(), 4.6)
        XCTAssertEqual(hvideSandeParts.waveDirection(), "SV")
    }

    func testWindHvideSande() {
        XCTAssertEqual(hvideSandeParts.windGust()?.double(), 20.9)
        XCTAssertEqual(hvideSandeParts.windMiddle()?.double(), 10.6)
        XCTAssertEqual(hvideSandeParts.windCurrent()?.double(), 12.2)
        XCTAssertEqual(hvideSandeParts.windDirection(), "S")
    }

    func testWindHanstholm() {
        XCTAssertEqual(hanstholmParts.windGust()?.double(), 13.2)
        XCTAssertEqual(hanstholmParts.windMiddle()?.double(), 9.2)
        XCTAssertEqual(hanstholmParts.windCurrent()?.double(), 9.2)
        XCTAssertEqual(hanstholmParts.windDirection(), "S")
    }

    func testWindThorsminde() {
        XCTAssertEqual(thorsmindeParts.windGust()?.double(), 15.6)
        XCTAssertEqual(thorsmindeParts.windMiddle()?.double(), 9.5)
        XCTAssertEqual(thorsmindeParts.windCurrent()?.double(), 10.2)
        XCTAssertEqual(thorsmindeParts.windDirection(), "SSØ")
    }

    func testWaveReadingsAreNotNumbersWhileHanstholmPublishesDashes() {
        XCTAssertNil(hanstholmParts.maxWaveHeight()?.double())
        XCTAssertNil(hanstholmParts.middleWaveHeight()?.double())
        XCTAssertNil(hanstholmParts.wavePeriod()?.double())
        XCTAssertEqual(hanstholmParts.waveDirection(), "-")
    }

    func testWaveReadingsAreNotNumbersWhileThorsmindePublishesDashes() {
        XCTAssertNil(thorsmindeParts.maxWaveHeight()?.double())
        XCTAssertNil(thorsmindeParts.middleWaveHeight()?.double())
        XCTAssertNil(thorsmindeParts.wavePeriod()?.double())
        XCTAssertEqual(thorsmindeParts.waveDirection(), "-")
    }

    func testValueIsReadFromTheLineAfterItsLabel() {
        let parts: [String.SubSequence] = ["Vindstød", "13,2m/s", "Barometer", "1007hPa"]

        XCTAssertEqual(parts.windGust()?.double(), 13.2)
    }

    func testLabelOnTheLastLineHasNoValue() {
        let parts: [String.SubSequence] = ["Barometer", "1007hPa", "Vindstød"]

        XCTAssertNil(parts.windGust())
    }

    func testMissingLabelHasNoValue() {
        let parts: [String.SubSequence] = ["Barometer", "1007hPa"]

        XCTAssertNil(parts.windGust())
    }

    func testNumberIsReadWithoutItsAttachedUnit() {
        XCTAssertEqual(Substring("12,2m/s").double(), 12.2)
        XCTAssertEqual(Substring("4,6sek").double(), 4.6)
    }

    func testDegreeSignIsNotPartOfTheDirection() {
        XCTAssertEqual(Substring("SSØ°").withoutBearing(), "SSØ")
    }

    func testBearingIsNotPartOfTheDirection() {
        XCTAssertEqual(Substring("V276°").withoutBearing(), "V")
        XCTAssertEqual(Substring("VNV297°").withoutBearing(), "VNV")
    }

    func testPlaceholderDirectionKeepsItsDash() {
        XCTAssertEqual(Substring("-°").withoutBearing(), "-")
    }
}

let hanstholmHTML = """
    <div class="dash-grid">
    <div class="dash-cell">
        <div class="cell-label">Aktuel vindhastighed</div>
        <div class="cell-body"><span class="cell-value">9,2</span><span class="cell-unit">m/s</span></div>
    </div>
    <div class="dash-cell">
        <div class="cell-label">Middel vindhastighed</div>
        <div class="cell-body"><span class="cell-value">9,2</span><span class="cell-unit">m/s</span></div>
    </div>
    <div class="dash-cell">
        <div class="cell-label">Vindretning middel</div>
        <div class="cell-body"><span class="cell-value">S</span><span class="cell-unit">180°</span></div>
    </div>
    <div class="dash-cell">
        <div class="cell-label">Vindstød</div>
        <div class="cell-body"><span class="cell-value">13,2</span><span class="cell-unit">m/s</span></div>
    </div>
    <div class="dash-cell">
        <div class="cell-label">Max Bølgehøjde</div>
        <div class="cell-body"><span class="cell-value">-</span><span class="cell-unit">m</span></div>
    </div>
    <div class="dash-cell">
        <div class="cell-label">Middel Bølgehøjde</div>
        <div class="cell-body"><span class="cell-value">-</span><span class="cell-unit">m</span></div>
    </div>
    <div class="dash-cell">
        <div class="cell-label">Bølgeperiode</div>
        <div class="cell-body"><span class="cell-value">-</span><span class="cell-unit">sek</span></div>
    </div>
    <div class="dash-cell">
        <div class="cell-label">Bølgeretning</div>
        <div class="cell-body"><span class="cell-value">-</span><span class="cell-unit">°</span></div>
    </div>
    </div>
    """

let hvideSandeHTML = """
    <div class="dash-grid">
    <div class="dash-cell">
        <div class="cell-label">Aktuel vindhastighed</div>
        <div class="cell-body"><span class="cell-value">12,2</span><span class="cell-unit">m/s</span></div>
    </div>
    <div class="dash-cell">
        <div class="cell-label">Middel vindhastighed</div>
        <div class="cell-body"><span class="cell-value">10,6</span><span class="cell-unit">m/s</span></div>
    </div>
    <div class="dash-cell">
        <div class="cell-label">Vindretning middel</div>
        <div class="cell-body"><span class="cell-value">S</span><span class="cell-unit">180°</span></div>
    </div>
    <div class="dash-cell">
        <div class="cell-label">Vindstød</div>
        <div class="cell-body"><span class="cell-value">20,9</span><span class="cell-unit">m/s</span></div>
    </div>
    <div class="dash-cell">
        <div class="cell-label">Max Bølgehøjde</div>
        <div class="cell-body"><span class="cell-value">2,84</span><span class="cell-unit">m</span></div>
    </div>
    <div class="dash-cell">
        <div class="cell-label">Middel Bølgehøjde</div>
        <div class="cell-body"><span class="cell-value">1,14</span><span class="cell-unit">m</span></div>
    </div>
    <div class="dash-cell">
        <div class="cell-label">Bølgeperiode</div>
        <div class="cell-body"><span class="cell-value">4,6</span><span class="cell-unit">sek</span></div>
    </div>
    <div class="dash-cell">
        <div class="cell-label">Bølgeretning</div>
        <div class="cell-body"><span class="cell-value">SV</span><span class="cell-unit">225°</span></div>
    </div>
    </div>
    """

let thorsmindeHTML = """
    <div class="dash-grid">
    <div class="dash-cell">
        <div class="cell-label">Aktuel vindhastighed</div>
        <div class="cell-body"><span class="cell-value">10,2</span><span class="cell-unit">m/s</span></div>
    </div>
    <div class="dash-cell">
        <div class="cell-label">Middel vindhastighed</div>
        <div class="cell-body"><span class="cell-value">9,5</span><span class="cell-unit">m/s</span></div>
    </div>
    <div class="dash-cell">
        <div class="cell-label">Vindretning middel</div>
        <div class="cell-body"><span class="cell-value">SSØ</span><span class="cell-unit">158°</span></div>
    </div>
    <div class="dash-cell">
        <div class="cell-label">Vindstød</div>
        <div class="cell-body"><span class="cell-value">15,6</span><span class="cell-unit">m/s</span></div>
    </div>
    <div class="dash-cell">
        <div class="cell-label">Max Bølgehøjde</div>
        <div class="cell-body"><span class="cell-value">-</span><span class="cell-unit">m</span></div>
    </div>
    <div class="dash-cell">
        <div class="cell-label">Middel Bølgehøjde</div>
        <div class="cell-body"><span class="cell-value">-</span><span class="cell-unit">m</span></div>
    </div>
    <div class="dash-cell">
        <div class="cell-label">Bølgeperiode</div>
        <div class="cell-body"><span class="cell-value">-</span><span class="cell-unit">sek</span></div>
    </div>
    <div class="dash-cell">
        <div class="cell-label">Bølgeretning</div>
        <div class="cell-body"><span class="cell-value">-</span><span class="cell-unit">°</span></div>
    </div>
    </div>
    """
