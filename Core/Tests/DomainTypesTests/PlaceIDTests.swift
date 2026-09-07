import XCTest
import Foundation
@testable import DomainTypes

final class PlaceIDTests: XCTestCase {
    func testEqualPluginAndKeyAreEqual() {
        let first = PlaceID(plugin: "test.stub", key: "hanstholm")
        let second = PlaceID(plugin: "test.stub", key: "hanstholm")

        XCTAssertEqual(first, second)
    }

    func testDifferingKeyIsNotEqual() {
        let first = PlaceID(plugin: "test.stub", key: "hanstholm")
        let second = PlaceID(plugin: "test.stub", key: "hvide-sande")

        XCTAssertNotEqual(first, second)
    }

    func testDifferingPluginIsNotEqual() {
        let first = PlaceID(plugin: "test.stub", key: "hanstholm")
        let second = PlaceID(plugin: "test.other", key: "hanstholm")

        XCTAssertNotEqual(first, second)
    }

    func testCodableRoundTripPreservesEquality() throws {
        let id = PlaceID(plugin: "test.stub", key: "hanstholm")

        let data = try JSONEncoder().encode(id)
        let decoded = try JSONDecoder().decode(PlaceID.self, from: data)

        XCTAssertEqual(decoded, id)
    }

    func testPluginEncodesAsABareStringNotANestedObject() throws {
        let id = PlaceID(plugin: "test.stub", key: "hanstholm")

        let data = try JSONEncoder().encode(id)
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(object?["plugin"] as? String, "test.stub")
        XCTAssertEqual(object?["key"] as? String, "hanstholm")
    }

    func testDescriptionJoinsPluginAndKey() {
        let id = PlaceID(plugin: "test.stub", key: "hanstholm")

        XCTAssertEqual(id.description, "test.stub/hanstholm")
    }
}
