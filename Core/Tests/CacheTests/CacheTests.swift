//
//  CacheTests.swift
//
//
//  Created by Michael Nisi on 11.07.26.
//

import XCTest
import Hyde
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

    func testSetConditionsRoundTripsThroughConditionsMatching() async throws {
        let cache = Cache(userDefaults: userDefaults)
        let hyde = Hyde(place: .hanstholm, date: .now, wave: nil, wind: nil)

        try await cache.setConditions(hyde)
        let fetched = try await cache.conditions(matching: .hanstholm)

        XCTAssertEqual(fetched, hyde)
    }

    func testConditionsMatchingNewerReturnsValueWhenFresh() async throws {
        let cache = Cache(userDefaults: userDefaults)
        let now = Date.now
        let hyde = Hyde(place: .hanstholm, date: now, wave: nil, wind: nil)

        try await cache.setConditions(hyde)
        let fresh = try await cache.conditions(matching: .hanstholm, newer: now.addingTimeInterval(-60))

        XCTAssertEqual(fresh, hyde)
    }

    func testConditionsMatchingNewerReturnsNilWhenStale() async throws {
        let cache = Cache(userDefaults: userDefaults)
        let staleDate = Date.now.addingTimeInterval(-3600)
        let hyde = Hyde(place: .hanstholm, date: staleDate, wave: nil, wind: nil)

        try await cache.setConditions(hyde)
        let result = try await cache.conditions(matching: .hanstholm, newer: Date.now.addingTimeInterval(-60))

        XCTAssertNil(result)
    }

    func testSetPlaceRoundTripsThroughPlace() async throws {
        let cache = Cache(userDefaults: userDefaults)

        try await cache.setPlace(.hanstholm)
        let place = await cache.place()

        XCTAssertEqual(place, .hanstholm)
    }
}
