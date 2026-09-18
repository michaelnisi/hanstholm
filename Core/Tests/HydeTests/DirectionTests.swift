import XCTest
import DomainTypes
@testable import Hyde

final class DirectionTests: XCTestCase {
    func testValidDanishDirectionsMapToExpectedCardinal() {
        XCTAssertEqual(Direction(danish: "N")?.cardinal, .north)
        XCTAssertEqual(Direction(danish: "NNØ")?.cardinal, .northNorthEast)
        XCTAssertEqual(Direction(danish: "Ø")?.cardinal, .east)
        XCTAssertEqual(Direction(danish: "S")?.cardinal, .south)
        XCTAssertEqual(Direction(danish: "V")?.cardinal, .west)
        XCTAssertEqual(Direction(danish: "NV")?.cardinal, .northWest)
    }

    func testInvalidOrMissingDanishDirectionReturnsNil() {
        XCTAssertNil(Direction(danish: "XX"))
        XCTAssertNil(Direction(danish: ""))
        XCTAssertNil(Direction(danish: nil))
    }
}
