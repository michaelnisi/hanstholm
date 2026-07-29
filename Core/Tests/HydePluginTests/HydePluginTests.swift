//
//  HydePluginTests.swift
//
//
//  Created by Michael Nisi on 29.07.26.
//

import XCTest
import Hyde
import DomainTypes
import SurfConditions
@testable import HydePlugin

// Parsing itself is covered by `ParserTests` against its HTML fixture; these cover the
// plugin's own contract — request construction and the guards around decoding.
final class HydePluginTests: XCTestCase {
    private let plugin = HydePlugin()

    func testPlacesMatchesHydePlaces() {
        XCTAssertEqual(plugin.places, ["Hanstholm"])
    }

    func testDeferredRequestUsesPlaceURL() throws {
        let request = try plugin.deferredRequest(for: "Hanstholm")

        XCTAssertEqual(request.url, Hyde.Place.hanstholm.url)
    }

    func testDeferredRequestThrowsForUnknownPlace() {
        XCTAssertThrowsError(try plugin.deferredRequest(for: "Klitmøller")) { error in
            XCTAssertEqual(error as? SurfConditionsFault, .unknownPlace("Klitmøller"))
        }
    }

    func testDecodeRejectsUnexpectedMediaType() async {
        do {
            _ = try await plugin.decodeDeferred(Data(), mimeType: "application/json", for: "Hanstholm")
            XCTFail("expected a media type failure")
        } catch {
            XCTAssertEqual(error as? SurfConditionsFault, .unexpectedMediaType("application/json"))
        }
    }

    func testDecodeThrowsForUnknownPlace() async {
        do {
            _ = try await plugin.decodeDeferred(Data(), mimeType: "text/html", for: "Klitmøller")
            XCTFail("expected an unknown place failure")
        } catch {
            XCTAssertEqual(error as? SurfConditionsFault, .unknownPlace("Klitmøller"))
        }
    }

    func testDecodeThrowsOnUnparseablePayload() async {
        do {
            _ = try await plugin.decodeDeferred(Data("nope".utf8), mimeType: "text/html", for: "Hanstholm")
            XCTFail("expected a decoding failure")
        } catch {
            // Either the parser rejects it or the DTO comes back incomplete; both are fine,
            // what matters is that nothing fabricates an entry.
            XCTAssertTrue(error is SurfConditionsFault || error is Hyde.Fault)
        }
    }
}
