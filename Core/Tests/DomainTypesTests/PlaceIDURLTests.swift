import Foundation
import XCTest

@testable import DomainTypes

final class PlaceIDURLTests: XCTestCase {
    func testRoundTripPreservesEquality() throws {
        let id = PlaceID(plugin: "test.stub", key: "hanstholm")

        let url = try XCTUnwrap(id.url)

        XCTAssertEqual(PlaceID(url: url), id)
    }

    func testURLNamesPluginAndKeyUnderThePatrolScheme() throws {
        let id = PlaceID(plugin: "test.stub", key: "hanstholm")

        let url = try XCTUnwrap(id.url)

        XCTAssertEqual(url.absoluteString, "patrol://place/test.stub/hanstholm")
    }

    func testKeyWithNonASCIIAndSpaceRoundTrips() throws {
        let id = PlaceID(plugin: "test.stub", key: "klitmøller nord")

        let url = try XCTUnwrap(id.url)

        XCTAssertEqual(PlaceID(url: url), id)
    }

    func testKeyContainingASlashRoundTripsAsOneSegment() throws {
        let id = PlaceID(plugin: "test.stub", key: "north/south")

        let url = try XCTUnwrap(id.url)

        XCTAssertEqual(PlaceID(url: url), id)
    }

    func testForeignSchemeIsRejected() throws {
        let url = try XCTUnwrap(URL(string: "https://place/test.stub/hanstholm"))

        XCTAssertNil(PlaceID(url: url))
    }

    func testForeignHostIsRejected() throws {
        let url = try XCTUnwrap(URL(string: "patrol://settings/test.stub/hanstholm"))

        XCTAssertNil(PlaceID(url: url))
    }

    func testMissingKeyIsRejected() throws {
        let url = try XCTUnwrap(URL(string: "patrol://place/test.stub"))

        XCTAssertNil(PlaceID(url: url))
    }

    func testEmptyKeyIsRejected() throws {
        let url = try XCTUnwrap(URL(string: "patrol://place/test.stub/"))

        XCTAssertNil(PlaceID(url: url))
    }

    func testExtraPathSegmentsAreRejected() throws {
        let url = try XCTUnwrap(URL(string: "patrol://place/test.stub/hanstholm/extra"))

        XCTAssertNil(PlaceID(url: url))
    }
}
