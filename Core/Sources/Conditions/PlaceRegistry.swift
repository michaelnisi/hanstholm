import Cache
import DomainTypes
import ConditionsPlugin

struct PlaceRegistry: Sendable {
    let plugins: [any ConditionsPlugin]
    let cache: Cache

    func availablePlaces() -> [Place] {
        plugins.flatMap(\.places)
    }

    func selectedPlace() async throws -> Place {
        let all = availablePlaces()

        guard let id = await cache.selectedPlaceID() else {
            guard let first = all.first else {
                throw ConditionsFault.noPlaceSelected
            }

            try? await cache.setSelectedPlace(first)

            return first
        }

        guard let place = all.first(where: { $0.id == id }) else {
            throw ConditionsFault.noPluginForPlace(id)
        }

        return place
    }

    func selectPlace(_ place: Place) async throws {
        try await cache.setSelectedPlace(place)
    }

    func includedPlaces() async -> [Place] {
        let all = availablePlaces()

        guard let ids = await cache.includedPlaceIDs() else {
            return all
        }

        let byID = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })

        return ids.compactMap { byID[$0] }
    }

    func setIncludedPlaceIDs(_ ids: [PlaceID]) async throws {
        try await cache.setIncludedPlaceIDs(ids)
    }

    func regions() async -> [GeoRegion] {
        guard let selected = try? await selectedPlace(),
              let index = plugins.firstIndex(where: { $0.owns(selected) }) else {
            return plugins.map(\.region)
        }

        var ordered = plugins
        ordered.insert(ordered.remove(at: index), at: 0)

        return ordered.map(\.region)
    }

    func plugin(for place: Place) -> (any ConditionsPlugin)? {
        plugins.first(where: { $0.owns(place) })
    }
}
