import XCTest
@testable import DomainTypes

final class DirectionTests: XCTestCase {
    func testFormattedRoundTripsToEnglishAbbreviation() {
        XCTAssertEqual(Direction(cardinal: .east).formatted(), "E")
        XCTAssertEqual(Direction(cardinal: .west).formatted(), "W")
    }

    func testSpokenSpellsOutCompoundDirections() {
        XCTAssertEqual(Direction(cardinal: .northNorthEast).spoken(), "north-northeast")
        XCTAssertEqual(Direction(cardinal: .east).spoken(), "east")
        XCTAssertEqual(Direction(cardinal: .west).spoken(), "west")
    }

    func testSouthIsZeroDegreesAndValuesIncreaseClockwise() {
        XCTAssertEqual(Direction(cardinal: .south).degrees, 0)
        XCTAssertEqual(Direction(cardinal: .west).degrees, 90)
        XCTAssertEqual(Direction(cardinal: .north).degrees, 180)
        XCTAssertEqual(Direction(cardinal: .east).degrees, 270)
    }
}
