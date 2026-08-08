import XCTest
import DomainTypes
import SurfConditions
@testable import Hyde

final class HydeTests: XCTestCase {
    private let plugin = Hyde()

    private var hanstholm: Place {
        Hyde.Station.hanstholm.place
    }

    private var foreign: Place {
        Place(pluginID: "some.other.plugin", key: "hanstholm", name: "Hanstholm")
    }

    func testVendsAPlaceForEveryStation() {
        XCTAssertEqual(plugin.places.count, Hyde.Station.allCases.count)
        XCTAssertEqual(Set(plugin.places.map(\.pluginID)), [plugin.id])
        XCTAssertEqual(plugin.places.map(\.name), ["Hanstholm"])
    }

    func testPlaceKeyIsStableAndDistinctFromTheDisplayName() {
        XCTAssertEqual(hanstholm.key, "hanstholm")
        XCTAssertEqual(hanstholm.name, "Hanstholm")
        XCTAssertEqual(hanstholm.id, "ink.codes.Hanstholm.plugin.hyde/hanstholm")
    }

    func testStationRoundTripsThroughItsKey() {
        for station in Hyde.Station.allCases {
            XCTAssertEqual(Hyde.Station(key: station.key), station)
        }
    }

    func testStationRoundTripsThroughItsPlace() {
        for station in Hyde.Station.allCases {
            XCTAssertEqual(Hyde.Station(place: station.place), station)
        }
    }

    func testStationRejectsAnotherPluginsPlace() {
        XCTAssertNil(Hyde.Station(place: foreign))
    }

    func testOwnsOnlyItsOwnPlaces() {
        XCTAssertTrue(plugin.owns(hanstholm))
        XCTAssertFalse(plugin.owns(foreign))
    }

    func testDeferredRequestUsesTheStationURL() throws {
        let request = try plugin.deferredRequest(for: hanstholm)

        XCTAssertEqual(request.url, Hyde.Station.hanstholm.url)
    }

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
            XCTAssertTrue(error is SurfConditionsFault || error is Hyde.Fault)
        }
    }
}
