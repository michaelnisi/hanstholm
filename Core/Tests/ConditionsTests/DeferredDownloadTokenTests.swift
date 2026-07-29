//
//  DeferredDownloadTokenTests.swift
//
//
//  Created by Michael Nisi on 29.07.26.
//

import XCTest
@testable import Conditions

// The token is the only thing tying a download that outlived its process back to the plugin
// and place that asked for it, so malformed input has to fail closed rather than misparse.
final class DeferredDownloadTokenTests: XCTestCase {
    func testRoundTrip() throws {
        let token = DeferredDownloader.Token(pluginID: "test.stub", place: "Hanstholm")
        let encoded = try XCTUnwrap(token.encoded())

        XCTAssertEqual(DeferredDownloader.Token(taskDescription: encoded), token)
    }

    func testRoundTripPreservesNonASCIIPlace() throws {
        let token = DeferredDownloader.Token(pluginID: "test.stub", place: "Klitmøller")
        let encoded = try XCTUnwrap(token.encoded())

        XCTAssertEqual(DeferredDownloader.Token(taskDescription: encoded)?.place, "Klitmøller")
    }

    func testRejectsNil() {
        XCTAssertNil(DeferredDownloader.Token(taskDescription: nil))
    }

    func testRejectsGarbage() {
        XCTAssertNil(DeferredDownloader.Token(taskDescription: "test.stub|Hanstholm"))
    }

    func testRejectsUnknownVersion() throws {
        let future = #"{"version":99,"pluginID":"test.stub","place":"Hanstholm"}"#

        XCTAssertNil(DeferredDownloader.Token(taskDescription: future))
    }
}
