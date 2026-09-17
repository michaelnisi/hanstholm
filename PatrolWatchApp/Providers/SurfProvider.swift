import Observation
import DomainTypes
import Conditions
#if DEBUG
import MockData
#endif

@Observable final class SurfProvider {
    var surfEntry: SurfEntry?
    var lastError: Error?

    struct Dependencies: Sendable {
        var cachedEntry: @Sendable () async -> SurfEntry?
        var fetchEntry: @Sendable () async throws -> SurfEntry
        var availablePlaces: @Sendable () async -> [Place]
        var selectPlace: @Sendable (Place) async -> Void
        var selectedPlace: @Sendable () async throws -> Place
        var includedPlaces: @Sendable () async -> [Place]
        var setIncludedPlaceIDs: @Sendable ([PlaceID]) async -> Void
    }

    private let dependencies: Dependencies

    nonisolated init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
}

extension SurfProvider {
    func load() async {
        if let stale = await dependencies.cachedEntry() {
            surfEntry = stale
        }

        do {
            surfEntry = try await dependencies.fetchEntry()
            lastError = nil
        } catch {
            logger.error("fetch failed: \(error)")
            lastError = error
        }
    }

    func availablePlaces() async -> [Place] {
        await dependencies.availablePlaces()
    }

    func selectPlace(_ place: Place) async {
        await dependencies.selectPlace(place)
        await load()
    }

    func selectedPlace() async -> Place? {
        do {
            return try await dependencies.selectedPlace()
        } catch {
            logger.error("selected place failed: \(error)")
            return nil
        }
    }

    func includedPlaces() async -> [Place] {
        await dependencies.includedPlaces()
    }

    func setIncludedPlaceIDs(_ ids: [PlaceID]) async {
        await dependencies.setIncludedPlaceIDs(ids)
        await load()
    }
}

extension SurfProvider {
    nonisolated static let live: SurfProvider = {
        let coordinator = ConditionsCoordinator.app

        return .init(
            dependencies: .init(
                cachedEntry: {
                    await coordinator.cached()
                },
                fetchEntry: {
                    try await coordinator.conditions(
                        policy: .cached(maxAge: 5 * 60),
                        trigger: .userInterface
                    )
                },
                availablePlaces: {
                    await coordinator.availablePlaces()
                },
                selectPlace: { place in
                    await coordinator.selectPlace(place)
                },
                selectedPlace: {
                    try await coordinator.selectedPlace()
                },
                includedPlaces: {
                    await coordinator.includedPlaces()
                },
                setIncludedPlaceIDs: { ids in
                    await coordinator.setIncludedPlaceIDs(ids)
                }
            )
        )
    }()
}

#if DEBUG
private actor MockSelection {
    private(set) var place = MockData.SurfEntry.makePlace()
    private(set) var includedIDs: [PlaceID]?

    func select(_ place: Place) {
        self.place = place
    }

    func setIncludedIDs(_ ids: [PlaceID]) {
        includedIDs = ids
    }
}

extension SurfProvider {
    nonisolated static let mock: SurfProvider = {
        let selection = MockSelection()

        return .init(
            dependencies: .init(
                cachedEntry: { nil },
                fetchEntry: {
                    try await Task.sleep(nanoseconds: 500_000_000)
                    return MockData.SurfEntry.makeSurfEntry(place: await selection.place)
                },
                availablePlaces: {
                    MockData.SurfEntry.makePlaces()
                },
                selectPlace: { place in
                    await selection.select(place)
                },
                selectedPlace: {
                    await selection.place
                },
                includedPlaces: {
                    let all = MockData.SurfEntry.makePlaces()

                    guard let ids = await selection.includedIDs else {
                        return all
                    }

                    let byID = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })

                    return ids.compactMap { byID[$0] }
                },
                setIncludedPlaceIDs: { ids in
                    await selection.setIncludedIDs(ids)
                }
            )
        )
    }()
}
#endif
