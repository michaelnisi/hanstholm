//
//  ParserTests.swift
//
//
//  Created by Michael Nisi on 07.04.24.
//

import XCTest
@testable import Hyde

final class ParserTests: XCTestCase {
    private var parts: [String.SubSequence]!

    override func setUp() async throws {
        try await super.setUp()

        self.parts = try html.stripOutHtml().splitLines()
    }

    func testWave() async throws {
        XCTAssertEqual(String(parts.middleWaveHeight()!), "2,48\u{A0}m")
        XCTAssertEqual(String(parts.maxWaveHeight()!), "3,88\u{A0}m")
        XCTAssertEqual(String(parts.wavePeriod()!), "6\u{A0}sek")
        XCTAssertEqual(String(parts.waveDirection()!), "N")
    }

    func testWind() async throws {
        XCTAssertEqual(String(parts.windGust()!), "22 m/s")
        XCTAssertEqual(String(parts.windMiddle()!), "17 m/s")
        XCTAssertEqual(String(parts.windCurrent()!), "18,6 m/s")
        XCTAssertEqual(String(parts.windDirection()!), "VNV")
    }

    func testSectionScopedLookupDoesNotLeakIntoLaterSections() {
        // "Bølger" is missing its own "middel" row, but "Strøm" — a later,
        // unrelated section — happens to contain a line also named "middel".
        // A section-scoped lookup must not leak across that boundary.
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
