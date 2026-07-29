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
// plugin's own contract — the places it vends, request construction, and the guards around
// decoding.
final class HydePluginTests: XCTestCase {
    private let plugin = HydePlugin()

    private var hanstholm: Place {
        HydePlugin.place(for: .hanstholm)
    }

    private var foreign: Place {
        Place(pluginID: "some.other.plugin", key: "hanstholm", name: "Hanstholm")
    }

    func testVendsOnePlaceCarryingItsOwnPluginIdentity() {
        XCTAssertEqual(plugin.places.count, 1)
        XCTAssertEqual(plugin.places.first?.pluginID, plugin.id)
        XCTAssertEqual(plugin.places.first?.name, "Hanstholm")
    }

    /// The key is what cached conditions are filed under, so it must not be the display name.
    func testPlaceKeyIsStableAndDistinctFromTheDisplayName() {
        XCTAssertEqual(hanstholm.key, "hanstholm")
        XCTAssertEqual(hanstholm.name, "Hanstholm")
        XCTAssertEqual(hanstholm.id, "ink.codes.Hanstholm.plugin.hyde/hanstholm")
    }

    func testOwnsOnlyItsOwnPlaces() {
        XCTAssertTrue(plugin.owns(hanstholm))
        XCTAssertFalse(plugin.owns(foreign))
    }

    func testDeferredRequestUsesPlaceURL() throws {
        let request = try plugin.deferredRequest(for: hanstholm)

        XCTAssertEqual(request.url, Hyde.Place.hanstholm.url)
    }

    /// Another plugin's place must be refused even when the key happens to match.
    func testDeferredRequestThrowsForAnotherPluginsPlace() {
        XCTAssertThrowsError(try plugin.deferredRequest(for: foreign)) { error in
            XCTAssertEqual(error as? SurfConditionsFault, .unknownPlace(foreign.id))
        }
    }

    func testDecodeRejectsUnexpectedMediaType() async {
        do {
            _ = try await plugin.decodeDeferred(Data(), mimeType: "application/json", for: hanstholm)
            XCTFail("expected a media type failure")
        } catch {
            XCTAssertEqual(error as? SurfConditionsFault, .unexpectedMediaType("application/json"))
        }
    }

    func testDecodeThrowsForAnotherPluginsPlace() async {
        do {
            _ = try await plugin.decodeDeferred(Data(), mimeType: "text/html", for: foreign)
            XCTFail("expected an unknown place failure")
        } catch {
            XCTAssertEqual(error as? SurfConditionsFault, .unknownPlace(foreign.id))
        }
    }

    func testDecodeThrowsOnUnparseablePayload() async {
        do {
            _ = try await plugin.decodeDeferred(Data("nope".utf8), mimeType: "text/html", for: hanstholm)
            XCTFail("expected a decoding failure")
        } catch {
            // Either the parser rejects it or the DTO comes back incomplete; both are fine,
            // what matters is that nothing fabricates an entry.
            XCTAssertTrue(error is SurfConditionsFault || error is Hyde.Fault)
        }
    }
}
