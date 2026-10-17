import Conditions
import DomainTypes
import MockData
import Observation
import os.log

nonisolated private let placesLogger = Logger(subsystem: "ink.codes.Patrol", category: "Places")

@Observable final class PlacesModel {
    struct Dependencies: Sendable {
        var availablePlaces: @Sendable () -> [Place]
        var selectedPlace: @Sendable () async -> Place?
        var cached: @Sendable (Place) async -> SurfEntry?
        var fetch: @Sendable (Place, FreshnessPolicy) async throws -> SurfEntry
    }

    static let automaticPolicy = FreshnessPolicy.cached(maxAge: 5 * 60)
    static let pullToRefreshPolicy = FreshnessPolicy.cached(maxAge: 60)

    enum Phase {
        case idle
        case loading
        case failed
    }

    private(set) var places: [Place] = []
    private(set) var entries: [PlaceID: SurfEntry] = [:]
    private(set) var phases: [PlaceID: Phase] = [:]
    var selection: PlaceID?

    private let dependencies: Dependencies

    nonisolated init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    var selectedPlace: Place? {
        places.first { $0.id == selection }
    }

    func phase(for place: Place) -> Phase {
        phases[place.id] ?? .idle
    }
}

extension PlacesModel {
    func load() async {
        let available = dependencies.availablePlaces()
        var loaded: [PlaceID: SurfEntry] = [:]

        for place in available {
            loaded[place.id] = await dependencies.cached(place)
        }

        places = available
        entries = loaded
    }

    func refresh(_ place: Place, policy: FreshnessPolicy = PlacesModel.automaticPolicy) async {
        phases[place.id] = .loading

        do {
            entries[place.id] = try await dependencies.fetch(place, policy)
            phases[place.id] = .idle
        } catch is CancellationError {
            phases[place.id] = .idle
        } catch {
            placesLogger.error("fetch failed for \(place.id): \(error)")
            phases[place.id] = .failed
        }
    }

    func preselectAppSelection() async {
        guard selection == nil else {
            return
        }

        selection = await dependencies.selectedPlace()?.id
    }
}

extension PlacesModel {
    nonisolated static let live = PlacesModel(
        dependencies: .init(
            availablePlaces: {
                ConditionsCoordinator.shared.availablePlaces()
            },
            selectedPlace: {
                try? await ConditionsCoordinator.shared.selectedPlace()
            },
            cached: { place in
                await ConditionsCoordinator.shared.cached(for: place)
            },
            fetch: { place, policy in
                try await ConditionsCoordinator.shared.conditions(
                    for: place,
                    policy: policy,
                    trigger: .userInterface
                )
            }
        )
    )

    static var mock: PlacesModel {
        let places = MockData.SurfEntry.makePlaces()

        return PlacesModel(
            dependencies: .init(
                availablePlaces: { places },
                selectedPlace: { places.first },
                cached: { place in
                    place == places.last
                        ? nil : MockData.SurfEntry.makeSurfEntry(place: place)
                },
                fetch: { place, _ in
                    guard place != places.last else {
                        throw MockFault()
                    }

                    return MockData.SurfEntry.makeSurfEntry(place: place)
                }
            )
        )
    }
}

private struct MockFault: Error {}
