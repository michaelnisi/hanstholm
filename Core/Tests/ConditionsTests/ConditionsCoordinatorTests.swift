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

private let stubPluginID = "test.stub"

private func makePlace(key: String = "testville", name: String = "Testville") -> Place {
    Place(pluginID: stubPluginID, key: key, name: name)
}

private func makeEntry(date: Date = .now, place: Place = makePlace()) -> SurfEntry {
    SurfEntry(
        date: date,
        place: place,
        status: .ok,
        wave: .init(max: 1.2, middle: 0.8, period: 8, direction: .init(cardinal: .west)),
        wind: .init(speed: .init(gust: 12, middle: 9, current: 10), direction: .init(cardinal: .west))
    )
}

private struct StubPlugin: SurfConditionsPlugin, DeferredDownloadable {
    let id = stubPluginID
    let places: [Place]
    let fetches = Counter()
    let decodes = Counter()
    let entry: @Sendable (Place) async throws -> SurfEntry

    func conditions(for place: Place, using session: URLSession) async throws -> SurfEntry {
        fetches.increment()

        return try await entry(place)
    }

    func deferredRequest(for place: Place) throws -> URLRequest {
        URLRequest(url: URL(string: "https://example.invalid/\(place.key)")!)
    }

    func decodeDeferred(_ data: Data, mimeType: String?, for place: Place) async throws -> SurfEntry {
        decodes.increment()

        return try await entry(place)
    }
}

private struct StubFault: Error {}

private func makePlugin(
    places: [Place] = [makePlace()],
    entry: (@Sendable (Place) async throws -> SurfEntry)? = nil
) -> StubPlugin {
    StubPlugin(
        places: places,
        entry: entry ?? { place in makeEntry(place: place) }
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
                reloadWidgetTimelines: { reload?.increment() },
                now: now
            )
        )

        return (coordinator, cache)
    }

    func testFallsBackToTheFirstInstalledPlaceWhenNothingSelected() async throws {
        let plugin = makePlugin()
        let (coordinator, _) = makeCoordinator(plugin: plugin)

        let place = try await coordinator.selectedPlace()

        XCTAssertEqual(place, makePlace())
    }

    func testFallingBackToTheFirstInstalledPlacePersistsIt() async throws {
        let plugin = makePlugin()
        let (coordinator, cache) = makeCoordinator(plugin: plugin)

        _ = try await coordinator.selectedPlace()

        let selected = await cache.selectedPlaceID()

        XCTAssertEqual(selected, makePlace().id)
    }

    func testUsesTheSelectedPlace() async throws {
        let second = makePlace(key: "elsewhere", name: "Elsewhere")
        let plugin = makePlugin(places: [makePlace(), second])
        let (coordinator, cache) = makeCoordinator(plugin: plugin)

        try await cache.setSelectedPlace(second)

        let place = try await coordinator.selectedPlace()

        XCTAssertEqual(place, second)
    }

    func testAvailablePlacesReturnsAllConfiguredPluginsPlaces() async throws {
        let second = makePlace(key: "elsewhere", name: "Elsewhere")
        let plugin = makePlugin(places: [makePlace(), second])
        let (coordinator, _) = makeCoordinator(plugin: plugin)

        let places = await coordinator.availablePlaces()

        XCTAssertEqual(places, [makePlace(), second])
    }

    func testSelectPlacePersistsIt() async throws {
        let second = makePlace(key: "elsewhere", name: "Elsewhere")
        let plugin = makePlugin(places: [makePlace(), second])
        let (coordinator, cache) = makeCoordinator(plugin: plugin)

        try await coordinator.selectPlace(second)

        let selected = await cache.selectedPlaceID()

        XCTAssertEqual(selected, second.id)
    }

    func testSelectPlaceThenSelectedPlaceReturnsIt() async throws {
        let second = makePlace(key: "elsewhere", name: "Elsewhere")
        let plugin = makePlugin(places: [makePlace(), second])
        let (coordinator, _) = makeCoordinator(plugin: plugin)

        try await coordinator.selectPlace(second)

        let place = try await coordinator.selectedPlace()

        XCTAssertEqual(place, second)
    }

    func testThrowsWhenSelectedPlacesPluginIsGone() async throws {
        let plugin = makePlugin()
        let (coordinator, cache) = makeCoordinator(plugin: plugin)
        let orphan = Place(pluginID: "test.removed", key: "x", name: "X")

        try await cache.setSelectedPlace(orphan)

        do {
            _ = try await coordinator.conditions(policy: .reload, trigger: .userInterface)
            XCTFail("expected no plugin for place")
        } catch {
            XCTAssertEqual(error as? SurfConditionsFault, .noPluginForPlace(orphan.id))
        }

        XCTAssertEqual(plugin.fetches.count, 0)
    }

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
            XCTAssertEqual(error as? SurfConditionsFault, .noCachedConditions(makePlace().id))
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

        let written = try await cache.conditions(matching: makePlace())
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
        let later = stored.date.addingTimeInterval(600)
        let (coordinator, cache) = makeCoordinator(plugin: plugin, now: { later })

        try await cache.setConditions(stored)

        _ = try await coordinator.conditions(
            policy: .cached(maxAge: 5 * 60),
            trigger: .userInterface
        )

        XCTAssertEqual(plugin.fetches.count, 1)
    }

    func testAnswerForTheWrongPlaceIsRejected() async throws {
        let elsewhere = makePlace(key: "elsewhere", name: "Elsewhere")
        let plugin = makePlugin(entry: { _ in makeEntry(place: elsewhere) })
        let (coordinator, cache) = makeCoordinator(plugin: plugin)

        do {
            _ = try await coordinator.conditions(policy: .reload, trigger: .userInterface)
            XCTFail("expected a place mismatch")
        } catch {
            XCTAssertEqual(
                error as? SurfConditionsFault,
                .placeMismatch(expected: makePlace().id, actual: elsewhere.id)
            )
        }

        let leaked = try await cache.conditions(matching: elsewhere)
        XCTAssertNil(leaked)
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

        let survived = try await cache.conditions(matching: makePlace())
        XCTAssertEqual(survived, stored)
    }

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

    func testConcurrentReloadsFetchOnce() async throws {
        let plugin = makePlugin(entry: { place in
            try await Task.sleep(nanoseconds: 50_000_000)

            return makeEntry(place: place)
        })
        let (coordinator, _) = makeCoordinator(plugin: plugin)

        async let first = coordinator.conditions(policy: .reload, trigger: .userInterface)
        async let second = coordinator.conditions(policy: .reload, trigger: .userInterface)

        _ = try await (first, second)

        XCTAssertEqual(plugin.fetches.count, 1)
    }

    func testIngestWritesThroughAndReloads() async throws {
        let plugin = makePlugin()
        let reloads = Counter()
        let (coordinator, cache) = makeCoordinator(plugin: plugin, reload: reloads)

        await coordinator.ingest(
            data: Data("payload".utf8),
            mimeType: "text/html",
            token: .init(place: makePlace())
        )

        let written = try await cache.conditions(matching: makePlace())

        XCTAssertNotNil(written)
        XCTAssertEqual(plugin.decodes.count, 1)
        XCTAssertEqual(reloads.count, 1)
    }

    func testIngestDropsUnknownPlugin() async throws {
        let plugin = makePlugin()
        let (coordinator, cache) = makeCoordinator(plugin: plugin)
        let orphan = Place(pluginID: "test.removed", key: "testville", name: "Testville")

        await coordinator.ingest(
            data: Data("payload".utf8),
            mimeType: "text/html",
            token: .init(place: orphan)
        )

        let written = try await cache.conditions(matching: orphan)

        XCTAssertNil(written)
        XCTAssertEqual(plugin.decodes.count, 0)
    }

    func testIngestDropsMismatchedPlace() async throws {
        let second = makePlace(key: "elsewhere", name: "Elsewhere")
        let plugin = makePlugin(places: [makePlace(), second])
        let (coordinator, cache) = makeCoordinator(plugin: plugin)

        try await cache.setSelectedPlace(makePlace())

        await coordinator.ingest(
            data: Data("payload".utf8),
            mimeType: "text/html",
            token: .init(place: second)
        )

        let written = try await cache.conditions(matching: second)

        XCTAssertNil(written)
        XCTAssertEqual(plugin.decodes.count, 0)
    }

    func testIngestWithoutTokenIsDropped() async throws {
        let plugin = makePlugin()
        let (coordinator, cache) = makeCoordinator(plugin: plugin)

        await coordinator.ingest(data: Data("payload".utf8), mimeType: "text/html", token: nil)

        let written = try await cache.conditions(matching: makePlace())

        XCTAssertNil(written)
        XCTAssertEqual(plugin.decodes.count, 0)
    }

    func testIngestDropsEntryForWrongPlace() async throws {
        let elsewhere = makePlace(key: "elsewhere", name: "Elsewhere")
        let plugin = makePlugin(entry: { _ in makeEntry(place: elsewhere) })
        let (coordinator, cache) = makeCoordinator(plugin: plugin)

        await coordinator.ingest(
            data: Data("payload".utf8),
            mimeType: "text/html",
            token: .init(place: makePlace())
        )

        let written = try await cache.conditions(matching: makePlace())
        let leaked = try await cache.conditions(matching: elsewhere)

        XCTAssertNil(written)
        XCTAssertNil(leaked)
        XCTAssertEqual(plugin.decodes.count, 1)
    }
}
