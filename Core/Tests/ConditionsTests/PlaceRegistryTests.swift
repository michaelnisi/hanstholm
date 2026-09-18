import XCTest
import Foundation
import Cache
import DomainTypes
import ConditionsPlugin
@testable import Conditions

final class PlaceRegistryTests: XCTestCase {
    private var suiteName: String!
    private var userDefaults: UserDefaults!

    override func setUp() {
        super.setUp()

        suiteName = "ink.codes.Patrol.PlaceRegistryTests.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: suiteName)
        userDefaults = nil
        suiteName = nil

        super.tearDown()
    }

    private func makeRegistry(plugin: StubPlugin) -> (PlaceRegistry, Cache) {
        makeRegistry(plugins: [plugin])
    }

    private func makeRegistry(plugins: [StubPlugin]) -> (PlaceRegistry, Cache) {
        let cache = Cache(userDefaults: userDefaults)
        let registry = PlaceRegistry(plugins: plugins, cache: cache)

        return (registry, cache)
    }

    func testFallsBackToTheFirstInstalledPlaceWhenNothingSelected() async throws {
        let plugin = makePlugin()
        let (registry, _) = makeRegistry(plugin: plugin)

        let place = try await registry.selectedPlace()

        XCTAssertEqual(place, makePlace())
    }

    func testFallingBackToTheFirstInstalledPlacePersistsIt() async throws {
        let plugin = makePlugin()
        let (registry, cache) = makeRegistry(plugin: plugin)

        _ = try await registry.selectedPlace()

        let selected = await cache.selectedPlaceID()

        XCTAssertEqual(selected, makePlace().id)
    }

    func testUsesTheSelectedPlace() async throws {
        let second = makePlace(key: "elsewhere", name: "Elsewhere")
        let plugin = makePlugin(places: [makePlace(), second])
        let (registry, cache) = makeRegistry(plugin: plugin)

        await cache.setSelectedPlace(second)

        let place = try await registry.selectedPlace()

        XCTAssertEqual(place, second)
    }

    func testAvailablePlacesReturnsAllConfiguredPluginsPlaces() async throws {
        let second = makePlace(key: "elsewhere", name: "Elsewhere")
        let plugin = makePlugin(places: [makePlace(), second])
        let (registry, _) = makeRegistry(plugin: plugin)

        let places = registry.availablePlaces()

        XCTAssertEqual(places, [makePlace(), second])
    }

    func testSelectedRegionReturnsSelectedPlacesPluginsRegion() async {
        let first = makePlugin(
            id: "test.first",
            places: [Place(pluginID: "test.first", key: "somewhere", name: "Somewhere")],
            region: GeoRegion(latitude: 1, longitude: 1, radius: 1)
        )
        let second = makePlugin(
            id: "test.second",
            places: [Place(pluginID: "test.second", key: "elsewhere", name: "Elsewhere")],
            region: GeoRegion(latitude: 2, longitude: 2, radius: 2)
        )
        let (registry, cache) = makeRegistry(plugins: [first, second])

        await cache.setSelectedPlace(second.places[0])

        let region = await registry.selectedRegion()

        XCTAssertEqual(region, second.region)
    }

    func testSelectedRegionFallsBackToTheFirstInstalledPlaceWhenNothingSelected() async throws {
        let plugin = makePlugin()
        let (registry, _) = makeRegistry(plugin: plugin)

        let region = await registry.selectedRegion()

        XCTAssertEqual(region, plugin.region)
    }

    func testSelectedRegionReturnsNilWhenNoPlacesAreAvailable() async {
        let first = makePlugin(
            id: "test.first",
            places: [],
            region: GeoRegion(latitude: 1, longitude: 1, radius: 1)
        )
        let (registry, _) = makeRegistry(plugin: first)

        let region = await registry.selectedRegion()

        XCTAssertNil(region)
    }

    func testSelectedRegionReturnsNilWhenSelectedPlacesPluginIsGone() async {
        let plugin = makePlugin()
        let (registry, cache) = makeRegistry(plugin: plugin)
        let orphan = Place(pluginID: "test.removed", key: "x", name: "X")

        await cache.setSelectedPlace(orphan)

        let region = await registry.selectedRegion()

        XCTAssertNil(region)
    }

    func testIncludedPlacesDefaultsToAllWhenNothingStored() async throws {
        let second = makePlace(key: "elsewhere", name: "Elsewhere")
        let plugin = makePlugin(places: [makePlace(), second])
        let (registry, _) = makeRegistry(plugin: plugin)

        let places = await registry.includedPlaces()

        XCTAssertEqual(places, [makePlace(), second])
    }

    func testIncludedPlacesReturnsStoredSubsetInStoredOrder() async {
        let second = makePlace(key: "elsewhere", name: "Elsewhere")
        let third = makePlace(key: "thirdville", name: "Thirdville")
        let plugin = makePlugin(places: [makePlace(), second, third])
        let (registry, _) = makeRegistry(plugin: plugin)

        await registry.setIncludedPlaceIDs([third.id, makePlace().id])

        let places = await registry.includedPlaces()

        XCTAssertEqual(places, [third, makePlace()])
    }

    func testIncludedPlacesDropsIDsForPlacesThatNoLongerExist() async {
        let plugin = makePlugin()
        let (registry, _) = makeRegistry(plugin: plugin)

        await registry.setIncludedPlaceIDs([makePlace().id, PlaceID(plugin: "gone.plugin", key: "nowhere")])

        let places = await registry.includedPlaces()

        XCTAssertEqual(places, [makePlace()])
    }

    func testSetIncludedPlaceIDsPersistsThroughCache() async {
        let plugin = makePlugin()
        let (registry, cache) = makeRegistry(plugin: plugin)

        await registry.setIncludedPlaceIDs([makePlace().id])

        let stored = await cache.includedPlaceIDs()

        XCTAssertEqual(stored, [makePlace().id])
    }

    func testSelectPlacePersistsIt() async {
        let second = makePlace(key: "elsewhere", name: "Elsewhere")
        let plugin = makePlugin(places: [makePlace(), second])
        let (registry, cache) = makeRegistry(plugin: plugin)

        await registry.selectPlace(second)

        let selected = await cache.selectedPlaceID()

        XCTAssertEqual(selected, second.id)
    }

    func testSelectPlaceThenSelectedPlaceReturnsIt() async throws {
        let second = makePlace(key: "elsewhere", name: "Elsewhere")
        let plugin = makePlugin(places: [makePlace(), second])
        let (registry, _) = makeRegistry(plugin: plugin)

        await registry.selectPlace(second)

        let place = try await registry.selectedPlace()

        XCTAssertEqual(place, second)
    }

    func testSetIncludedPlaceIDsReselectsWhenSelectedPlaceIsDropped() async {
        let second = makePlace(key: "elsewhere", name: "Elsewhere")
        let third = makePlace(key: "thirdville", name: "Thirdville")
        let plugin = makePlugin(places: [makePlace(), second, third])
        let (registry, cache) = makeRegistry(plugin: plugin)

        await cache.setSelectedPlace(second)

        let selectionChanged = await registry.setIncludedPlaceIDs([third.id, makePlace().id])

        XCTAssertTrue(selectionChanged)

        let selected = await cache.selectedPlaceID()
        XCTAssertEqual(selected, third.id)
    }

    func testSetIncludedPlaceIDsLeavesSelectionWhenStillIncluded() async {
        let second = makePlace(key: "elsewhere", name: "Elsewhere")
        let plugin = makePlugin(places: [makePlace(), second])
        let (registry, cache) = makeRegistry(plugin: plugin)

        await cache.setSelectedPlace(second)

        let selectionChanged = await registry.setIncludedPlaceIDs([second.id, makePlace().id])

        XCTAssertFalse(selectionChanged)

        let selected = await cache.selectedPlaceID()
        XCTAssertEqual(selected, second.id)
    }

    func testSetIncludedPlaceIDsReturnsFalseWhenNothingWasSelected() async {
        let second = makePlace(key: "elsewhere", name: "Elsewhere")
        let plugin = makePlugin(places: [makePlace(), second])
        let (registry, cache) = makeRegistry(plugin: plugin)

        let selectionChanged = await registry.setIncludedPlaceIDs([second.id])

        XCTAssertFalse(selectionChanged)

        let selected = await cache.selectedPlaceID()
        XCTAssertNil(selected)
    }

    func testSelectedPlaceThrowsWhenSelectedPlacesPluginIsGone() async {
        let plugin = makePlugin()
        let (registry, cache) = makeRegistry(plugin: plugin)
        let orphan = Place(pluginID: "test.removed", key: "x", name: "X")

        await cache.setSelectedPlace(orphan)

        do {
            _ = try await registry.selectedPlace()
            XCTFail("expected no plugin for place")
        } catch {
            XCTAssertEqual(error as? ConditionsFault, .noPluginForPlace(orphan.id))
        }
    }
}
