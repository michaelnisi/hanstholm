import XCTest
import DomainTypes
@testable import Conditions

final class DeferredDownloadTokenTests: XCTestCase {
    private let place = Place(pluginID: "test.stub", key: "hanstholm", name: "Hanstholm")

    func testRoundTrip() throws {
        let token = DeferredDownloader.Token(place: place)
        let encoded = try XCTUnwrap(token.encoded())

        XCTAssertEqual(DeferredDownloader.Token(taskDescription: encoded), token)
    }

    func testRoundTripCarriesPluginIdentity() throws {
        let token = DeferredDownloader.Token(place: place)
        let encoded = try XCTUnwrap(token.encoded())

        XCTAssertEqual(DeferredDownloader.Token(taskDescription: encoded)?.place.pluginID, "test.stub")
    }

    func testRoundTripPreservesNonASCIIName() throws {
        let place = Place(pluginID: "test.stub", key: "klitmoller", name: "Klitmøller")
        let encoded = try XCTUnwrap(DeferredDownloader.Token(place: place).encoded())

        XCTAssertEqual(DeferredDownloader.Token(taskDescription: encoded)?.place.name, "Klitmøller")
    }

    func testRejectsNil() {
        XCTAssertNil(DeferredDownloader.Token(taskDescription: nil))
    }

    func testRejectsGarbage() {
        XCTAssertNil(DeferredDownloader.Token(taskDescription: "test.stub|Hanstholm"))
    }

    func testRejectsUnknownVersion() {
        let future = #"{"version":99,"place":{"pluginID":"test.stub","key":"hanstholm","name":"Hanstholm"}}"#

        XCTAssertNil(DeferredDownloader.Token(taskDescription: future))
    }
}
