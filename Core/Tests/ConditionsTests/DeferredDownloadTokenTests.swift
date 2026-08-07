//
//  DeferredDownloadTokenTests.swift
//
//
//  Created by Michael Nisi on 29.07.26.
//

import XCTest
import DomainTypes
@testable import Conditions

// The token is the only thing tying a download that outlived its process back to the plugin
// and place that asked for it, so malformed input has to fail closed rather than misparse.
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
