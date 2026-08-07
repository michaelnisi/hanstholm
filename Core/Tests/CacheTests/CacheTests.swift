//
//  CacheTests.swift
//
//
//  Created by Michael Nisi on 11.07.26.
//

import XCTest
import DomainTypes
@testable import Cache

final class CacheTests: XCTestCase {
    private var suiteName: String!
    private var userDefaults: UserDefaults!

    override func setUp() {
        super.setUp()

        suiteName = "ink.codes.Hanstholm.CacheTests.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: suiteName)
        userDefaults = nil
        suiteName = nil

        super.tearDown()
    }

    private func makePlace(key: String = "hanstholm", name: String = "Hanstholm") -> Place {
        Place(pluginID: "test.stub", key: key, name: name)
    }

    private func makeSurfEntry(date: Date = .now, place: Place? = nil) -> SurfEntry {
        SurfEntry(
            date: date,
            place: place ?? makePlace(),
            status: .ok,
            wave: .init(max: 1.2, middle: 0.8, period: 8, direction: .init(cardinal: .west)),
            wind: .init(speed: .init(gust: 12, middle: 9, current: 10), direction: .init(cardinal: .west))
        )
    }

    func testSetConditionsRoundTripsThroughConditionsMatching() async throws {
        let cache = Cache(userDefaults: userDefaults)
        let entry = makeSurfEntry()

        try await cache.setConditions(entry)
        let fetched = try await cache.conditions(matching: entry.place)

        XCTAssertEqual(fetched, entry)
    }

    func testConditionsMatchingNewerReturnsValueWhenFresh() async throws {
        let cache = Cache(userDefaults: userDefaults)
        let now = Date.now
        let entry = makeSurfEntry(date: now)

        try await cache.setConditions(entry)
        let fresh = try await cache.conditions(matching: entry.place, newer: now.addingTimeInterval(-60))

        XCTAssertEqual(fresh, entry)
    }

    func testConditionsMatchingNewerReturnsNilWhenStale() async throws {
        let cache = Cache(userDefaults: userDefaults)
        let staleDate = Date.now.addingTimeInterval(-3600)
        let entry = makeSurfEntry(date: staleDate)

        try await cache.setConditions(entry)
        let result = try await cache.conditions(matching: entry.place, newer: Date.now.addingTimeInterval(-60))

        XCTAssertNil(result)
    }

    /// Two places that share a display name but differ in identity must not share storage.
    func testPlacesWithTheSameNameAreStoredSeparately() async throws {
        let cache = Cache(userDefaults: userDefaults)
        let one = makeSurfEntry(place: makePlace(key: "hanstholm", name: "Hanstholm"))
        let two = makeSurfEntry(place: makePlace(key: "hanstholm-pier", name: "Hanstholm"))

        try await cache.setConditions(one)
        try await cache.setConditions(two)

        let first = try await cache.conditions(matching: one.place)
        let second = try await cache.conditions(matching: two.place)

        XCTAssertEqual(first?.place.key, "hanstholm")
        XCTAssertEqual(second?.place.key, "hanstholm-pier")
    }

    func testSelectedPlaceIDIsNilBeforeAnythingIsSelected() async {
        let cache = Cache(userDefaults: userDefaults)

        let selected = await cache.selectedPlaceID()

        XCTAssertNil(selected)
    }

    func testSetSelectedPlaceStoresItsIdentifier() async throws {
        let cache = Cache(userDefaults: userDefaults)
        let place = makePlace()

        try await cache.setSelectedPlace(place)
        let selected = await cache.selectedPlaceID()

        XCTAssertEqual(selected, place.id)
    }

    func testSelectedConditionsReadsTheSelectedPlacesEntry() async throws {
        let cache = Cache(userDefaults: userDefaults)
        let entry = makeSurfEntry()

        try await cache.setConditions(entry)
        try await cache.setSelectedPlace(entry.place)

        let selected = try await cache.selectedConditions()

        XCTAssertEqual(selected, entry)
    }

    func testSelectedConditionsIsNilWhenNothingSelected() async throws {
        let cache = Cache(userDefaults: userDefaults)

        try await cache.setConditions(makeSurfEntry())

        let selected = try await cache.selectedConditions()

        XCTAssertNil(selected)
    }
}
