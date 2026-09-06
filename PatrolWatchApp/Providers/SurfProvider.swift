import Observation
import MockData
import DomainTypes
import Conditions

@Observable final class SurfProvider {
    var surfEntry: SurfEntry?
    var lastError: Error?

    struct Dependencies: Sendable {
        var cachedEntry: @Sendable () async -> SurfEntry?
        var fetchEntry: @Sendable () async throws -> SurfEntry
        var availablePlaces: @Sendable () async -> [Place]
        var selectPlace: @Sendable (Place) async throws -> Void
        var selectedPlace: @Sendable () async throws -> Place
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
        do {
            try await dependencies.selectPlace(place)
            await load()
        } catch {
            logger.error("select place failed: \(error)")
        }
    }

    func selectedPlace() async -> Place? {
        do {
            return try await dependencies.selectedPlace()
        } catch {
            logger.error("selected place failed: \(error)")
            return nil
        }
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
                    try await coordinator.selectPlace(place)
                },
                selectedPlace: {
                    try await coordinator.selectedPlace()
                }
            )
        )
    }()
}

private actor MockSelection {
    private(set) var place = MockData.SurfEntry.makePlace()

    func select(_ place: Place) {
        self.place = place
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
                }
            )
        )
    }()
}
