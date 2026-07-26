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

    private func makeSurfEntry(date: Date = .now, name: String = "Hanstholm") -> SurfEntry {
        SurfEntry(
            date: date,
            name: name,
            status: .ok,
            wave: .init(max: 1.2, middle: 0.8, period: 8, direction: .init(cardinal: .west)),
            wind: .init(speed: .init(gust: 12, middle: 9, current: 10), direction: .init(cardinal: .west))
        )
    }

    func testSetConditionsRoundTripsThroughConditionsMatching() async throws {
        let cache = Cache(userDefaults: userDefaults)
        let entry = makeSurfEntry()

        try await cache.setConditions(entry)
        let fetched = try await cache.conditions(matching: entry.name)

        XCTAssertEqual(fetched, entry)
    }

    func testConditionsMatchingNewerReturnsValueWhenFresh() async throws {
        let cache = Cache(userDefaults: userDefaults)
        let now = Date.now
        let entry = makeSurfEntry(date: now)

        try await cache.setConditions(entry)
        let fresh = try await cache.conditions(matching: entry.name, newer: now.addingTimeInterval(-60))

        XCTAssertEqual(fresh, entry)
    }

    func testConditionsMatchingNewerReturnsNilWhenStale() async throws {
        let cache = Cache(userDefaults: userDefaults)
        let staleDate = Date.now.addingTimeInterval(-3600)
        let entry = makeSurfEntry(date: staleDate)

        try await cache.setConditions(entry)
        let result = try await cache.conditions(matching: entry.name, newer: Date.now.addingTimeInterval(-60))

        XCTAssertNil(result)
    }

    func testSetPlaceRoundTripsThroughPlace() async throws {
        let cache = Cache(userDefaults: userDefaults)

        try await cache.setPlace("Hanstholm")
        let place = await cache.place()

        XCTAssertEqual(place, "Hanstholm")
    }
}
