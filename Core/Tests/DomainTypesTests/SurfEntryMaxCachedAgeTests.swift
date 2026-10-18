import Foundation
import XCTest

@testable import DomainTypes

final class SurfEntryMaxCachedAgeTests: XCTestCase {
    func testOldestUsableDateIsSixHoursBeforeNow() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        let oldest = SurfEntry.oldestUsableDate(now: now)

        XCTAssertEqual(now.timeIntervalSince(oldest), 6 * 60 * 60)
    }
}
