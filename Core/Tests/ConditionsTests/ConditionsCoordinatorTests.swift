//
//  ConditionsCoordinatorTests.swift
//
//
//  Created by Michael Nisi on 29.07.26.
//

import XCTest
import Foundation
import Cache
import DomainTypes
import SurfConditions
@testable import Conditions

private final class Counter: @unchecked Sendable {
    private let lock = NSLock()
    private var value = 0

    func increment() {
        lock.lock()
        value += 1
        lock.unlock()
    }

    var count: Int {
        lock.lock()

        defer {
            lock.unlock()
        }

        return value
    }
}

private func makeEntry(date: Date = .now, name: String = "Hanstholm") -> SurfEntry {
    SurfEntry(
        date: date,
        name: name,
        status: .ok,
        wave: .init(max: 1.2, middle: 0.8, period: 8, direction: .init(cardinal: .west)),
        wind: .init(speed: .init(gust: 12, middle: 9, current: 10), direction: .init(cardinal: .west))
    )
}

private struct StubPlugin: SurfConditionsPlugin, DeferredDownloadable {
    let id: String
    let places: [String]
    let fetches = Counter()
    let decodes = Counter()
    let entry: @Sendable (String) async throws -> SurfEntry

    func conditions(for place: String, using session: URLSession) async throws -> SurfEntry {
        fetches.increment()

        return try await entry(place)
    }

    func deferredRequest(for place: String) throws -> URLRequest {
        URLRequest(url: URL(string: "https://example.invalid/\(place)")!)
    }

    func decodeDeferred(_ data: Data, mimeType: String?, for place: String) async throws -> SurfEntry {
        decodes.increment()

        return try await entry(place)
    }
}

private struct StubFault: Error {}

private func makePlugin(
    places: [String] = ["Hanstholm"],
    entry: (@Sendable (String) async throws -> SurfEntry)? = nil
) -> StubPlugin {
    StubPlugin(
        id: "test.stub",
        places: places,
        entry: entry ?? { place in makeEntry(name: place) }
    )
}

final class ConditionsCoordinatorTests: XCTestCase {
    private var suiteName: String!
    private var userDefaults: UserDefaults!

    override func setUp() {
        super.setUp()

        suiteName = "ink.codes.Hanstholm.ConditionsTests.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: suiteName)
        userDefaults = nil
        suiteName = nil

        super.tearDown()
    }

    private func makeCoordinator(
        plugin: StubPlugin,
        now: @escaping @Sendable () -> Date = { .now },
        reload: Counter? = nil
    ) -> (ConditionsCoordinator, Cache) {
        let cache = Cache(userDefaults: userDefaults)

        let coordinator = ConditionsCoordinator(
            configuration: .init(
                plugins: [plugin],
                cache: cache,
                // deferredDownloads stays nil, so no background session is ever created.
                reloadWidgetTimelines: { reload?.increment() },
                now: now
            )
        )

        return (coordinator, cache)
    }

    // MARK: Freshness

    func testCachedOnlyReturnsCachedWithoutFetching() async throws {
        let plugin = makePlugin()
        let (coordinator, cache) = makeCoordinator(plugin: plugin)
        let stored = makeEntry()

        try await cache.setConditions(stored)

        let entry = try await coordinator.conditions(policy: .cachedOnly, trigger: .userInterface)

        XCTAssertEqual(entry, stored)
        XCTAssertEqual(plugin.fetches.count, 0)
    }

    func testCachedOnlyThrowsWhenNothingCached() async {
        let plugin = makePlugin()
        let (coordinator, _) = makeCoordinator(plugin: plugin)

        do {
            _ = try await coordinator.conditions(policy: .cachedOnly, trigger: .userInterface)
            XCTFail("expected a cache miss")
        } catch {
            XCTAssertEqual(error as? SurfConditionsFault, .noCachedConditions("Hanstholm"))
        }

        XCTAssertEqual(plugin.fetches.count, 0)
    }

    func testCachedSkipsFetchWhenFresh() async throws {
        let plugin = makePlugin()
        let (coordinator, cache) = makeCoordinator(plugin: plugin)
        let stored = makeEntry()

        try await cache.setConditions(stored)

        let entry = try await coordinator.conditions(
            policy: .cached(maxAge: 5 * 60),
            trigger: .userInterface
        )

        XCTAssertEqual(entry, stored)
        XCTAssertEqual(plugin.fetches.count, 0)
    }

    func testCachedFetchesWhenStaleAndWritesThrough() async throws {
        let plugin = makePlugin()
        let (coordinator, cache) = makeCoordinator(plugin: plugin)

        try await cache.setConditions(makeEntry(date: .now.addingTimeInterval(-3600)))

        let entry = try await coordinator.conditions(
            policy: .cached(maxAge: 5 * 60),
            trigger: .userInterface
        )

        XCTAssertEqual(plugin.fetches.count, 1)

        let written = try await cache.conditions(matching: "Hanstholm")
        XCTAssertEqual(written, entry)
    }

    func testReloadFetchesEvenWithFreshCache() async throws {
        let plugin = makePlugin()
        let (coordinator, cache) = makeCoordinator(plugin: plugin)

        try await cache.setConditions(makeEntry())

        _ = try await coordinator.conditions(policy: .reload, trigger: .userInterface)

        XCTAssertEqual(plugin.fetches.count, 1)
    }

    func testFreshnessBoundaryUsesInjectedClock() async throws {
        let plugin = makePlugin()
        let stored = makeEntry()
        // Ten minutes after the entry was stored, a five minute window is stale.
        let later = stored.date.addingTimeInterval(600)
        let (coordinator, cache) = makeCoordinator(plugin: plugin, now: { later })

        try await cache.setConditions(stored)

        _ = try await coordinator.conditions(
            policy: .cached(maxAge: 5 * 60),
            trigger: .userInterface
        )

        XCTAssertEqual(plugin.fetches.count, 1)
    }

    // MARK: Failure handling

    func testUnknownPlaceThrows() async throws {
        let plugin = makePlugin()
        let (coordinator, cache) = makeCoordinator(plugin: plugin)

        try await cache.setPlace("Klitmøller")

        do {
            _ = try await coordinator.conditions(policy: .reload, trigger: .userInterface)
            XCTFail("expected no plugin for place")
        } catch {
            XCTAssertEqual(error as? SurfConditionsFault, .noPluginForPlace("Klitmøller"))
        }
    }

    func testFetchFailureLeavesCacheIntact() async throws {
        let plugin = makePlugin(entry: { _ in throw StubFault() })
        let (coordinator, cache) = makeCoordinator(plugin: plugin)
        let stored = makeEntry(date: .now.addingTimeInterval(-3600))

        try await cache.setConditions(stored)

        do {
            _ = try await coordinator.conditions(policy: .reload, trigger: .userInterface)
            XCTFail("expected the plugin's error to propagate")
        } catch {
            XCTAssertTrue(error is StubFault)
        }

        let survived = try await cache.conditions(matching: "Hanstholm")
        XCTAssertEqual(survived, stored)
    }

    // MARK: Timeline reloads

    func testWidgetTimelineTriggerDoesNotReloadTimelines() async throws {
        let plugin = makePlugin()
        let reloads = Counter()
        let (coordinator, _) = makeCoordinator(plugin: plugin, reload: reloads)

        _ = try await coordinator.conditions(policy: .reload, trigger: .widgetTimeline)

        XCTAssertEqual(reloads.count, 0)
    }

    func testOtherTriggersReloadTimelines() async throws {
        for trigger in [Trigger.userInterface, .appBackgroundRefresh] {
            let plugin = makePlugin()
            let reloads = Counter()
            let (coordinator, _) = makeCoordinator(plugin: plugin, reload: reloads)

            _ = try await coordinator.conditions(policy: .reload, trigger: trigger)

            XCTAssertEqual(reloads.count, 1, "\(trigger) should reload timelines")
        }
    }

    // MARK: Coalescing

    func testConcurrentReloadsFetchOnce() async throws {
        let plugin = makePlugin(entry: { place in
            // Long enough that the second caller arrives while the first is in flight.
            try await Task.sleep(nanoseconds: 50_000_000)

            return makeEntry(name: place)
        })
        let (coordinator, _) = makeCoordinator(plugin: plugin)

        async let first = coordinator.conditions(policy: .reload, trigger: .userInterface)
        async let second = coordinator.conditions(policy: .reload, trigger: .userInterface)

        _ = try await (first, second)

        XCTAssertEqual(plugin.fetches.count, 1)
    }

    // MARK: Deferred download ingest

    func testIngestWritesThroughAndReloads() async throws {
        let plugin = makePlugin()
        let reloads = Counter()
        let (coordinator, cache) = makeCoordinator(plugin: plugin, reload: reloads)

        await coordinator.ingest(
            data: Data("payload".utf8),
            mimeType: "text/html",
            token: .init(pluginID: plugin.id, place: "Hanstholm")
        )

        let written = try await cache.conditions(matching: "Hanstholm")

        XCTAssertNotNil(written)
        XCTAssertEqual(plugin.decodes.count, 1)
        XCTAssertEqual(reloads.count, 1)
    }

    func testIngestDropsUnknownPlugin() async throws {
        let plugin = makePlugin()
        let (coordinator, cache) = makeCoordinator(plugin: plugin)

        await coordinator.ingest(
            data: Data("payload".utf8),
            mimeType: "text/html",
            token: .init(pluginID: "test.removed", place: "Hanstholm")
        )

        let written = try await cache.conditions(matching: "Hanstholm")

        XCTAssertNil(written)
        XCTAssertEqual(plugin.decodes.count, 0)
    }

    func testIngestDropsMismatchedPlace() async throws {
        let plugin = makePlugin()
        let (coordinator, cache) = makeCoordinator(plugin: plugin)

        // Scheduled before the selected place changed.
        await coordinator.ingest(
            data: Data("payload".utf8),
            mimeType: "text/html",
            token: .init(pluginID: plugin.id, place: "Klitmøller")
        )

        let written = try await cache.conditions(matching: "Klitmøller")

        XCTAssertNil(written)
        XCTAssertEqual(plugin.decodes.count, 0)
    }

    func testIngestWithoutTokenFallsBackToSelectedPlace() async throws {
        let plugin = makePlugin()
        let (coordinator, cache) = makeCoordinator(plugin: plugin)

        await coordinator.ingest(data: Data("payload".utf8), mimeType: "text/html", token: nil)

        let written = try await cache.conditions(matching: "Hanstholm")

        XCTAssertNotNil(written)
        XCTAssertEqual(plugin.decodes.count, 1)
    }
}
