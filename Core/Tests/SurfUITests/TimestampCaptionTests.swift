import XCTest
@testable import SurfUI

final class TimestampCaptionTests: XCTestCase {
    func testTextAndScrimColorsClearWCAGAAContrast() {
        let ratio = WCAGContrast.ratio(TimestampCaption.textColor, TimestampCaption.scrimColor)

        XCTAssertGreaterThanOrEqual(ratio, 4.5)
    }
}
