import XCTest
@testable import SurfUI

final class ContrastRatioTests: XCTestCase {
    func testPureWhiteAgainstPureBlackIsMaximumContrast() {
        let white = ContrastColor(red: 1, green: 1, blue: 1)
        let black = ContrastColor(red: 0, green: 0, blue: 0)

        XCTAssertEqual(WCAGContrast.ratio(white, black), 21.0, accuracy: 0.01)
    }

    func testIdenticalColorsHaveNoContrast() {
        let gray = ContrastColor(red: 0.5, green: 0.5, blue: 0.5)

        XCTAssertEqual(WCAGContrast.ratio(gray, gray), 1.0, accuracy: 0.001)
    }
}
