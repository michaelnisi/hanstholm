import AppIntents
import Conditions
import DomainTypes

nonisolated struct PlaceEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Surf Spot"
    static let defaultQuery = PlaceEntityQuery()

    let place: Place

    var id: String {
        place.id.description
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(place.name)", image: .init(systemName: place.icon))
    }
}

nonisolated struct PlaceEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [PlaceEntity] {
        let wanted = Set(identifiers)
        let places = ConditionsCoordinator.shared.availablePlaces()

        return
            places
            .filter { wanted.contains($0.id.description) }
            .map(PlaceEntity.init(place:))
    }

    func suggestedEntities() async throws -> [PlaceEntity] {
        await ConditionsCoordinator.shared.includedPlaces().map(PlaceEntity.init(place:))
    }
}
