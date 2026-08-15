import XCTest
@testable import Hyde

final class ParserTests: XCTestCase {
    private var parts: [String.SubSequence]!
    private var hvideSandeParts: [String.SubSequence]!
    private var thorsmindeParts: [String.SubSequence]!

    override func setUp() async throws {
        try await super.setUp()

        self.parts = try html.stripOutHtml().splitLines()
        self.hvideSandeParts = try hvideSandeHTML.stripOutHtml().splitLines()
        self.thorsmindeParts = try thorsmindeHTML.stripOutHtml().splitLines()
    }

    func testWave() async throws {
        XCTAssertEqual(String(parts.middleWaveHeight(for: .hanstholm)!), "2,48\u{A0}m")
        XCTAssertEqual(String(parts.maxWaveHeight(for: .hanstholm)!), "3,88\u{A0}m")
        XCTAssertEqual(String(parts.wavePeriod()!), "6\u{A0}sek")
        XCTAssertEqual(String(parts.waveDirection()!), "N")
    }

    func testWind() async throws {
        XCTAssertEqual(String(parts.windGust()!), "22 m/s")
        XCTAssertEqual(String(parts.windMiddle(for: .hanstholm)!), "17 m/s")
        XCTAssertEqual(String(parts.windCurrent(for: .hanstholm)!), "18,6 m/s")
        XCTAssertEqual(String(parts.windDirection(for: .hanstholm)!), "VNV")
    }

    func testWaveHvideSande() async throws {
        XCTAssertEqual(String(hvideSandeParts.middleWaveHeight(for: .hvideSande)!), "1,59\u{A0}m")
        XCTAssertEqual(String(hvideSandeParts.maxWaveHeight(for: .hvideSande)!), "2,48\u{A0}m")
        XCTAssertEqual(String(hvideSandeParts.wavePeriod()!), "4,3\u{A0}sek")
        XCTAssertEqual(String(hvideSandeParts.waveDirection()!), "VNV")
    }

    func testWindHvideSande() async throws {
        XCTAssertEqual(String(hvideSandeParts.windGust()!), "13 m/s")
        XCTAssertEqual(String(hvideSandeParts.windMiddle(for: .hvideSande)!), "8,8 m/s")
        XCTAssertEqual(String(hvideSandeParts.windCurrent(for: .hvideSande)!), "10,7 m/s")
        XCTAssertEqual(String(hvideSandeParts.windDirection(for: .hvideSande)!), "VNV")
    }

    func testWaveThorsminde() async throws {
        XCTAssertEqual(String(thorsmindeParts.middleWaveHeight(for: .thorsminde)!), "1,69\u{A0}m")
        XCTAssertEqual(String(thorsmindeParts.maxWaveHeight(for: .thorsminde)!), "2,65\u{A0}m")
        XCTAssertEqual(String(thorsmindeParts.wavePeriod()!), "3,6\u{A0}sek")
        XCTAssertEqual(String(thorsmindeParts.waveDirection()!), "V")
    }

    func testWindThorsminde() async throws {
        // The captured page's "vindstød" cell was blank at fetch time — real data, not a fixture bug.
        XCTAssertNil(thorsmindeParts.windGust()?.double())
        XCTAssertEqual(String(thorsmindeParts.windMiddle(for: .thorsminde)!), "11,1 m/s")
        XCTAssertEqual(String(thorsmindeParts.windCurrent(for: .thorsminde)!), "12,3 m/s")
        XCTAssertEqual(String(thorsmindeParts.windDirection(for: .thorsminde)!), "VNV")
    }

    func testSectionScopedLookupDoesNotLeakIntoLaterSectionsForHvideSandeShapedHeadings() {
        let parts: [String.SubSequence] = [
            "Vindhastighed",
            "aktuelt", "10,7 m/s",
            "middel", "8,8 m/s",
            "vindstød", "13 m/s",
            "Vindretning",
            "aktuelt", "VNV",
            "middel", "VNV",
            "Vandstand",
            "Havet", "-0,25 m",
            "Bølger",
            "max", "2,48 m",
            "Slusedrift i dag",
            "Strømningsretning", "neutral",
            "middel", "should not leak into Bølger's scope",
        ]

        XCTAssertNil(parts.middleWaveHeight(for: .hvideSande))
    }

    func testSectionScopedLookupDoesNotLeakIntoLaterSections() {
        let parts: [String.SubSequence] = [
            "Vindhastighed",
            "aktuelt", "18,6 m/s",
            "middel", "17 m/s",
            "vindstød", "22 m/s",
            "Vindretning",
            "aktuelt", "VNV",
            "middel", "VNV",
            "Bølger",
            "max", "3,88 m",
            "Strøm",
            "Retning", "Ø",
            "middel", "should not leak into Bølger's scope",
        ]

        XCTAssertNil(parts.middleWaveHeight())
    }

    func testSectionScopedLookupDoesNotReturnNextSectionHeadingAsValue() {
        let parts: [String.SubSequence] = [
            "Vindhastighed",
            "aktuelt", "18,6 m/s",
            "middel", "17 m/s",
            "vindstød", "22 m/s",
            "Vindretning",
            "aktuelt", "VNV",
            "middel", "VNV",
            "Bølger",
            "max", "3,88 m",
            "middel",
            "Strøm",
            "Retning", "Ø",
        ]

        XCTAssertNil(parts.middleWaveHeight())
    }
}

let html = """
<!DOCTYPE html>
<html lang="da-DK">
<head><meta charset="utf-8" /></head>
<body>
<div class="one-half">
    <div class="one-half block inner30">
        <h2>Vind <span class="floatright">18,6 m/s</span></h2>
        <table>
            <tr><thead><td colspan="2">Vindhastighed</td></thead></tr>
            <tr><td>aktuelt</td><td class="alignright">18,6 m/s</td></tr>
            <tr><td>middel</td><td class="alignright">17 m/s</td></tr>
            <tr><td>vindstød</td><td class="alignright">22 m/s</td></tr>
            <tr><td colspan="2">&nbsp;</td></tr>
            <tr><td>Barometer</td><td class="alignright">1002&nbsp;hPA</td></tr>
        </table>
    </div>
    <div class="one-half block inner30">
        <h2>Retning <span class="floatright">VNV</span></h2>
        <table>
            <tr><thead><td colspan="2">Vindretning</td></thead></tr>
            <tr><td>aktuelt</td><td class="alignright">VNV<br><span>299&deg;</span></td></tr>
            <tr><td>middel</td><td class="alignright">VNV<br><span>296&deg;</span></td></tr>
        </table>
    </div>
</div>
<div class="one-half">
    <div class="one-half block inner30">
        <h2>Bølger<span class="floatright extra-narrow">3,88 m</span></h2>
        <table class="mb0 pb0">
            <tr><thead><td colspan="2">Bølger</td></thead></tr>
            <tr><td>max</td><td class="alignright">3,88&nbsp;m</td></tr>
            <tr><td>middel</td><td class="alignright">2,48&nbsp;m</td></tr>
            <tr><td>Bølgeperiode</td><td class="alignright">6&nbsp;sek</td></tr>
            <tr><td>Bølgeretning</td><td class="alignright">N<br><span>0&deg;</span></td></tr>
            <tr><thead><td colspan="2">Strøm</td></thead></tr>
            <tr><td>Retning</td><td class="alignright">Ø<br><span>96&deg;</span></td></tr>
            <tr><td>Fart</td><td class="alignright">0,74&nbsp;knob</td></tr>
        </table>
    </div>
</div>
</body>
</html>
"""

let hvideSandeHTML = """
<!DOCTYPE html>
<html lang="da-DK">
<head><meta charset="utf-8" /></head>
<body>
<div class="one-half">
    <div class="one-half block inner30">
        <h2>Vind <span class="floatright">10,7 m/s</span></h2>
        <table>
            <tr><thead><td colspan="2">Vindhastighed</td></thead></tr>
            <tr><td>aktuelt</td><td class="alignright">10,7 m/s</td></tr>
            <tr><td>middel</td><td class="alignright">8,8 m/s</td></tr>
            <tr><td>vindstød</td><td class="alignright">13 m/s</td></tr>
            <tr><td colspan="2">&nbsp;</td></tr>
            <tr><td>Barometer</td><td class="alignright">1010&nbsp;hPA</td></tr>
        </table>
    </div>
    <div class="one-half block inner30">
        <h2>Retning <span class="floatright">VNV</span></h2>
        <table>
            <tr><thead><td colspan="2">Vindretning</td></thead></tr>
            <tr><td>aktuelt</td><td class="alignright">VNV<br><span>303&deg;</span></td></tr>
            <tr><td>middel</td><td class="alignright">VNV<br><span>301&deg;</span></td></tr>
        </table>
    </div>
</div>
<div class="one-half">
    <div class="one-half block inner30">
        <h2>Havn <span class="floatright">-0,25&nbsp;m</span></h2>
        <table>
            <tr><thead><td colspan="2">Vandstand</td></thead></tr>
            <tr><td>Havet</td><td class="alignright">-0,25 m</td></tr>
            <tr><td>Havnen</td><td class="alignright">-0,25 m</td></tr>
            <tr><td>Fjorden</td><td class="alignright">0 m</td></tr>
        </table>
    </div>
    <div class="one-half block inner30">
        <h2>Bølger<span class="floatright extra-narrow">2,48 m</span></h2>
        <table class="mb0 pb0">
            <tr><thead><td colspan="2">Bølger</td></thead></tr>
            <tr><td>max</td><td class="alignright">2,48&nbsp;m</td></tr>
            <tr><td>middel</td><td class="alignright">1,59&nbsp;m</td></tr>
            <tr><td>Bølgeperiode</td><td class="alignright">4,3&nbsp;sek</td></tr>
            <tr><td>Bølgeretning</td><td class="alignright">VNV<br><span>291&deg;</span></td></tr>
        </table>
    </div>
</div>
<div class="one-half">
    <div class="full block inner30">
        <h2 class="narrow">Gennemstrømning<span class="floatright">0 m<sup>3</sup>/s</span></h2>
        <table>
            <tr><thead><td colspan="2">Slusedrift i dag</td></thead></tr>
            <tr><td>Strømningsretning</td><td class="alignright">neutral</td></tr>
            <tr><td>Slusedrift</td><td class="alignright">lukket</td></tr>
        </table>
    </div>
</div>
</body>
</html>
"""

let thorsmindeHTML = """
<!DOCTYPE html>
<html lang="da-DK">
<head><meta charset="utf-8" /></head>
<body>
<div class="one-half">
    <div class="one-half block inner30">
        <h2>Vind <span class="floatright">12,3 m/s</span></h2>
        <table>
            <tr><thead><td colspan="2">Vindhastighed</td></thead></tr>
            <tr><td>aktuelt</td><td class="alignright">12,3 m/s</td></tr>
            <tr><td>middel</td><td class="alignright">11,1 m/s</td></tr>
            <tr><td>vindstød</td><td class="alignright"> m/s</td></tr>
            <tr><td colspan="2">&nbsp;</td></tr>
            <tr><td>Barometer</td><td class="alignright">1012&nbsp;hPA</td></tr>
        </table>
    </div>
    <div class="one-half block inner30">
        <h2>Retning <span class="floatright">VNV</span></h2>
        <table>
            <tr><thead><td colspan="2">Vindretning</td></thead></tr>
            <tr><td>aktuelt</td><td class="alignright">VNV<br><span>302&deg;</span></td></tr>
            <tr><td>middel</td><td class="alignright">VNV<br><span>303&deg;</span></td></tr>
        </table>
    </div>
</div>
<div class="one-half">
    <div class="one-half block inner30">
        <h2>Havn <span class="floatright">-0,12&nbsp;m</span></h2>
        <table>
            <tr><thead><td colspan="2">Vandstand</td></thead></tr>
            <tr><td>Havet</td><td class="alignright">-0,12 m</td></tr>
            <tr><td>Havnen</td><td class="alignright">-0,12 m</td></tr>
            <tr><td>Fjorden</td><td class="alignright">0,03 m</td></tr>
        </table>
    </div>
    <div class="one-half block inner30">
        <h2>Bølger<span class="floatright extra-narrow">2,65 m</span></h2>
        <table class="mb0 pb0">
            <tr><thead><td colspan="2">Bølger</td></thead></tr>
            <tr><td>max</td><td class="alignright">2,65&nbsp;m</td></tr>
            <tr><td>middel</td><td class="alignright">1,69&nbsp;m</td></tr>
            <tr><td>Bølgeperiode</td><td class="alignright">3,6&nbsp;sek</td></tr>
            <tr><td>Bølgeretning</td><td class="alignright">V<br><span>281&deg;</span></td></tr>
        </table>
    </div>
</div>
<div class="one-half">
    <div class="full block inner30">
        <h2 class="narrow">Gennemstrømning<span class="floatright">-4 m<sup>3</sup>/s</span></h2>
        <table>
            <tr><thead><td colspan="2">Slusedrift i dag</td></thead></tr>
            <tr><td>Strømningsretning</td><td class="alignright">neutral</td></tr>
            <tr><td>Slusedrift</td><td class="alignright">lukket</td></tr>
        </table>
    </div>
</div>
</body>
</html>
"""
