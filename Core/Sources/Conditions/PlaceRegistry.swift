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

            await cache.setSelectedPlace(first)

            return first
        }

        guard let place = all.first(where: { $0.id == id }) else {
            throw ConditionsFault.noPluginForPlace(id)
        }

        return place
    }

    func selectPlace(_ place: Place) async {
        await cache.setSelectedPlace(place)
    }

    func includedPlaces() async -> [Place] {
        let all = availablePlaces()

        guard let ids = await cache.includedPlaceIDs() else {
            return all
        }

        let byID = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })

        return ids.compactMap { byID[$0] }
    }

    @discardableResult
    func setIncludedPlaceIDs(_ ids: [PlaceID]) async -> Bool {
        await cache.setIncludedPlaceIDs(ids)

        guard let selected = await cache.selectedPlaceID(), !ids.contains(selected) else {
            return false
        }

        guard let fallbackID = ids.first,
              let fallback = availablePlaces().first(where: { $0.id == fallbackID }) else {
            return false
        }

        await cache.setSelectedPlace(fallback)

        return true
    }

    func selectedRegion() async -> GeoRegion? {
        guard let selected = try? await selectedPlace() else {
            return nil
        }

        return plugin(for: selected)?.region
    }

    func plugin(for place: Place) -> (any ConditionsPlugin)? {
        plugins.first(where: { $0.owns(place) })
    }
}
