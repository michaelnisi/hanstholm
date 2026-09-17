import XCTest
import DomainTypes
@testable import Cache

final class CacheTests: XCTestCase {
    private var suiteName: String!
    private var userDefaults: UserDefaults!

    override func setUp() {
        super.setUp()

        suiteName = "ink.codes.Patrol.CacheTests.\(UUID().uuidString)"
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

    func testSetConditionsRoundTripsThroughConditionsMatching() async {
        let cache = Cache(userDefaults: userDefaults)
        let entry = makeSurfEntry()

        await cache.setConditions(entry)
        let fetched = await cache.conditions(matching: entry.place)

        XCTAssertEqual(fetched, entry)
    }

    func testConditionsMatchingNewerReturnsValueWhenFresh() async {
        let cache = Cache(userDefaults: userDefaults)
        let now = Date.now
        let entry = makeSurfEntry(date: now)

        await cache.setConditions(entry)
        let fresh = await cache.conditions(matching: entry.place, newer: now.addingTimeInterval(-60))

        XCTAssertEqual(fresh, entry)
    }

    func testConditionsMatchingNewerReturnsNilWhenStale() async {
        let cache = Cache(userDefaults: userDefaults)
        let staleDate = Date.now.addingTimeInterval(-3600)
        let entry = makeSurfEntry(date: staleDate)

        await cache.setConditions(entry)
        let result = await cache.conditions(matching: entry.place, newer: Date.now.addingTimeInterval(-60))

        XCTAssertNil(result)
    }

    func testPlacesWithTheSameNameAreStoredSeparately() async {
        let cache = Cache(userDefaults: userDefaults)
        let one = makeSurfEntry(place: makePlace(key: "hanstholm", name: "Hanstholm"))
        let two = makeSurfEntry(place: makePlace(key: "hanstholm-pier", name: "Hanstholm"))

        await cache.setConditions(one)
        await cache.setConditions(two)

        let first = await cache.conditions(matching: one.place)
        let second = await cache.conditions(matching: two.place)

        XCTAssertEqual(first?.place.key, "hanstholm")
        XCTAssertEqual(second?.place.key, "hanstholm-pier")
    }

    func testSelectedPlaceIDIsNilBeforeAnythingIsSelected() async {
        let cache = Cache(userDefaults: userDefaults)

        let selected = await cache.selectedPlaceID()

        XCTAssertNil(selected)
    }

    func testSetSelectedPlaceStoresItsIdentifier() async {
        let cache = Cache(userDefaults: userDefaults)
        let place = makePlace()

        await cache.setSelectedPlace(place)
        let selected = await cache.selectedPlaceID()

        XCTAssertEqual(selected, place.id)
    }

    func testSelectedConditionsReadsTheSelectedPlacesEntry() async {
        let cache = Cache(userDefaults: userDefaults)
        let entry = makeSurfEntry()

        await cache.setConditions(entry)
        await cache.setSelectedPlace(entry.place)

        let selected = await cache.selectedConditions()

        XCTAssertEqual(selected, entry)
    }

    func testSelectedConditionsIsNilWhenNothingSelected() async {
        let cache = Cache(userDefaults: userDefaults)

        await cache.setConditions(makeSurfEntry())

        let selected = await cache.selectedConditions()

        XCTAssertNil(selected)
    }

    func testSetSettingsRoundTripsThroughSettingsFor() async {
        let cache = Cache(userDefaults: userDefaults)
        let place = makePlace()

        await cache.setSettings(PlaceSettings(), for: place)
        let fetched = await cache.settings(for: place)

        XCTAssertEqual(fetched, PlaceSettings())
    }

    func testSettingsForIsNilWhenNothingStored() async throws {
        let cache = Cache(userDefaults: userDefaults)

        let fetched = await cache.settings(for: makePlace())

        XCTAssertNil(fetched)
    }

    func testSettingsForFallsBackToDefaultsWhenStoredBlobDoesNotDecode() async {
        let cache = Cache(userDefaults: userDefaults)
        let place = makePlace()

        let corrupt = Data("not a PlaceSettings".utf8)
        userDefaults.set(corrupt, forKey: "\(Cache.Key.settings)-id-\(place.id.cacheComponent)")

        let fetched = await cache.settings(for: place)

        XCTAssertEqual(fetched, PlaceSettings())
    }

    func testIncludedPlaceIDsIsNilBeforeAnythingIsSet() async {
        let cache = Cache(userDefaults: userDefaults)

        let ids = await cache.includedPlaceIDs()

        XCTAssertNil(ids)
    }

    func testIncludedPlaceIDsRoundTripsThroughSetIncludedPlaceIDs() async {
        let cache = Cache(userDefaults: userDefaults)
        let ids = [PlaceID(plugin: "test.stub", key: "hanstholm"), PlaceID(plugin: "test.stub", key: "hvide-sande")]

        await cache.setIncludedPlaceIDs(ids)
        let fetched = await cache.includedPlaceIDs()

        XCTAssertEqual(fetched, ids)
    }

    func testIncludedPlaceIDsIsIndependentOfSelectedPlaceAndSettings() async {
        let cache = Cache(userDefaults: userDefaults)
        let place = makePlace()

        await cache.setSelectedPlace(place)
        await cache.setSettings(PlaceSettings(), for: place)
        await cache.setIncludedPlaceIDs([place.id])

        let selected = await cache.selectedPlaceID()
        let settings = await cache.settings(for: place)
        let included = await cache.includedPlaceIDs()

        XCTAssertEqual(selected, place.id)
        XCTAssertEqual(settings, PlaceSettings())
        XCTAssertEqual(included, [place.id])
    }

    func testSettingsAreIsolatedByPlace() async {
        let cache = Cache(userDefaults: userDefaults)
        let one = makePlace(key: "hanstholm", name: "Hanstholm")
        let two = makePlace(key: "hvide-sande", name: "Hvide Sande")

        await cache.setSettings(PlaceSettings(), for: one)

        let first = await cache.settings(for: one)
        let second = await cache.settings(for: two)

        XCTAssertEqual(first, PlaceSettings())
        XCTAssertNil(second)
    }
}
