//
//  DirectionTests.swift
//
//
//  Created by Michael Nisi on 11.07.26.
//

import XCTest
@testable import DomainTypes

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

    func testFormattedRoundTripsToEnglishAbbreviation() {
        XCTAssertEqual(Direction(danish: "Ø")?.formatted(), "E")
        XCTAssertEqual(Direction(danish: "V")?.formatted(), "W")
    }

    func testSouthIsZeroDegreesAndValuesIncreaseClockwise() {
        // South = 0°, per the "arrow points toward origin" quirk documented in CLAUDE.md.
        XCTAssertEqual(Direction(cardinal: .south).degrees, 0)
        XCTAssertEqual(Direction(cardinal: .west).degrees, 90)
        XCTAssertEqual(Direction(cardinal: .north).degrees, 180)
        XCTAssertEqual(Direction(cardinal: .east).degrees, 270)
    }
}
