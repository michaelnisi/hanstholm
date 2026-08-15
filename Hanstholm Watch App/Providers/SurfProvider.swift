import Observation
import MockData
import DomainTypes
import Conditions

@Observable final class SurfProvider {
    var surfEntry: SurfEntry?

    struct Dependencies: Sendable {
        var cachedEntry: @Sendable () async -> SurfEntry?
        var fetchEntry: @Sendable () async throws -> SurfEntry
        var availablePlaces: @Sendable () async -> [Place]
        var selectPlace: @Sendable (Place) async throws -> Void
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
        } catch {
            logger.error("fetch failed: \(error)")
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
}

extension SurfProvider {
    nonisolated static let live: SurfProvider = {
        let coordinator = ConditionsCoordinator.watchApp

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
                }
            )
        )
    }()
}

extension SurfProvider {
    nonisolated static let mock: SurfProvider = {
        .init(
            dependencies: .init(
                cachedEntry: { nil },
                fetchEntry: {
                    try await Task.sleep(nanoseconds: 500_000_000)
                    return MockData.SurfEntry.makeSurfEntry()
                },
                availablePlaces: {
                    [MockData.SurfEntry.makePlace()]
                },
                selectPlace: { _ in }
            )
        )
    }()
}
