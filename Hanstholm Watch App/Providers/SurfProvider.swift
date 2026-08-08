import Observation
import MockData
import DomainTypes
import Conditions

@Observable final class SurfProvider {
    var surfEntry: SurfEntry?

    struct Dependencies: Sendable {
        var cachedEntry: @Sendable () async -> SurfEntry?
        var fetchEntry: @Sendable () async throws -> SurfEntry
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
                }
            )
        )
    }()
}
