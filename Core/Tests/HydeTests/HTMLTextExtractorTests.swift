import XCTest

@testable import Hyde

final class HTMLTextExtractorTests: XCTestCase {
    private func lines(_ html: String) -> [String] {
        HTMLTextExtractor.text(from: html).split(separator: "\n").map(String.init)
    }

    func testInlineElementsAreConcatenatedSoAValueAndItsUnitShareALine() {
        XCTAssertEqual(lines("<span>S</span><span>180°</span>"), ["S180°"])
    }

    func testBlockElementsSplitLinesSoALabelAndItsValueSitOnSeparateLines() {
        XCTAssertEqual(
            lines("<div>Vindstød</div><div><span>13,2</span><span>m/s</span></div>"),
            ["Vindstød", "13,2m/s"]
        )
    }

    func testLineBreaksSplitLines() {
        XCTAssertEqual(lines("one<br>two<br/>three"), ["one", "two", "three"])
    }

    func testWhitespaceRunsCollapseAndLinesAreTrimmed() {
        XCTAssertEqual(lines("<div>\n    Max   Bølgehøjde \n</div>"), ["Max Bølgehøjde"])
    }

    func testEntitiesAreDecoded() {
        XCTAssertEqual(
            lines("<div>Vandstand &amp; Flow &#176; &#xB0; &lt;&gt;&quot;&apos;</div>"),
            ["Vandstand & Flow ° ° <>\"'"]
        )
    }

    func testUnknownEntitiesAndBareAmpersandsStayLiteral() {
        XCTAssertEqual(lines("<div>a &unknown; b & c</div>"), ["a &unknown; b & c"])
    }

    func testScriptStyleAndTitleContentsAreDropped() {
        XCTAssertEqual(
            lines(
                """
                <title>Vejrstation</title><style>.a > .b { color: red }</style>
                <script>if (a < b && c > d) { x() }</script><div>9,2</div>
                """),
            ["9,2"]
        )
    }

    func testCommentsAndDeclarationsAreDropped() {
        XCTAssertEqual(
            lines("<!DOCTYPE html><!-- <div>hidden</div> --><div>shown</div>"), ["shown"])
    }

    func testQuotedAttributesMayContainClosingBrackets() {
        XCTAssertEqual(lines("<div data-x=\"a > b\">text</div>"), ["text"])
    }

    func testBareLessThanIsKeptAsText() {
        XCTAssertEqual(lines("<div>1 < 2</div>"), ["1 < 2"])
    }

    func testUnterminatedMarkupDoesNotCrash() {
        XCTAssertEqual(lines("<div>kept</div><div class=\"x"), ["kept"])
        XCTAssertEqual(lines("<!-- never closed"), [])
        XCTAssertEqual(lines("<script>never closed"), [])
    }
}
