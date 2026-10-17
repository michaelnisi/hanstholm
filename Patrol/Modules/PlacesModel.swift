import Conditions
import DomainTypes
import MockData
import Observation

@Observable final class PlacesModel {
    struct Dependencies: Sendable {
        var availablePlaces: @Sendable () -> [Place]
        var selectedPlace: @Sendable () async -> Place?
        var cached: @Sendable (Place) async -> SurfEntry?
        var selectPlace: @Sendable (Place) async -> Void
    }

    private(set) var places: [Place] = []
    private(set) var entries: [PlaceID: SurfEntry] = [:]
    var selection: PlaceID?

    private let dependencies: Dependencies

    nonisolated init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    var selectedPlace: Place? {
        places.first { $0.id == selection }
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

    func preselectAppSelection() async {
        guard selection == nil else {
            return
        }

        selection = await dependencies.selectedPlace()?.id
    }

    func persistSelection() async {
        guard let selectedPlace else {
            return
        }

        await dependencies.selectPlace(selectedPlace)
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
            selectPlace: { place in
                await ConditionsCoordinator.shared.selectPlace(place)
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
                selectPlace: { _ in }
            )
        )
    }
}
