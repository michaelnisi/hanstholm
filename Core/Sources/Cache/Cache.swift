import Foundation
import DomainTypes

extension UserDefaults: @retroactive @unchecked Sendable {}

public struct PlaceSettings: Hashable, Sendable, Codable {
    public init() {}
}

public actor Cache {
    struct Key {
        static let conditions = "ink.codes.Patrol.Cache.conditions"
        static let settings = "ink.codes.Patrol.Cache.settings"
        static let includedPlaces = "ink.codes.Patrol.Cache.includedPlaces"
    }

    private let db: UserDefaults?
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    public init(userDefaults: UserDefaults? = UserDefaults(suiteName: "group.ink.codes.Patrol")) {
        self.db = userDefaults
    }

    public func dump() -> [String : Any] {
        db?.dictionaryRepresentation() ?? [:]
    }
}

extension Cache {
    public func conditions(matching place: Place) -> SurfEntry? {
        guard let data = db?.data(forKey: .makePlaceKey(place: place)) else {
            return nil
        }

        return try? decoder.decode(SurfEntry.self, from: data)
    }

    public func conditions(matching place: Place, newer: Date) -> SurfEntry? {
        guard let data = conditions(matching: place), data.date >= newer else {
            return nil
        }

        return data
    }

    @discardableResult
    public func setConditions(_ value: SurfEntry) -> Bool {
        guard let data = try? encoder.encode(value) else {
            return false
        }

        db?.setValue(data, forKey: .makePlaceKey(place: value.place))

        return true
    }
}

extension Cache {
    public func settings(for place: Place) -> PlaceSettings? {
        guard let data = db?.data(forKey: .makeSettingsKey(place: place)) else {
            return nil
        }

        return (try? decoder.decode(PlaceSettings.self, from: data)) ?? PlaceSettings()
    }

    @discardableResult
    public func setSettings(_ value: PlaceSettings, for place: Place) -> Bool {
        guard let data = try? encoder.encode(value) else {
            return false
        }

        db?.setValue(data, forKey: .makeSettingsKey(place: place))

        return true
    }
}

extension Cache {
    public func includedPlaceIDs() -> [PlaceID]? {
        guard let data = db?.data(forKey: Cache.Key.includedPlaces) else {
            return nil
        }

        return try? decoder.decode([PlaceID].self, from: data)
    }

    @discardableResult
    public func setIncludedPlaceIDs(_ ids: [PlaceID]) -> Bool {
        guard let data = try? encoder.encode(ids) else {
            return false
        }

        db?.setValue(data, forKey: Cache.Key.includedPlaces)

        return true
    }
}

extension Cache {
    @discardableResult
    public func setSelectedPlace(_ place: Place) -> Bool {
        guard let data = try? encoder.encode(place.id) else {
            return false
        }

        db?.setValue(data, forKey: .selectedPlaceKey)

        return true
    }

    public func selectedPlaceID() -> PlaceID? {
        guard let data = db?.data(forKey: .selectedPlaceKey) else {
            return nil
        }

        return try? decoder.decode(PlaceID.self, from: data)
    }

    public func selectedConditions() -> SurfEntry? {
        guard let id = selectedPlaceID(), let data = db?.data(forKey: .makeKey(placeID: id)) else {
            return nil
        }

        return try? decoder.decode(SurfEntry.self, from: data)
    }
}

extension PlaceID {
    var cacheComponent: String {
        "\(plugin.rawValue.count).\(plugin.rawValue)-\(key.count).\(key)"
    }
}

extension String {
    fileprivate static let selectedPlaceKey = "\(Cache.Key.conditions)-selected"

    fileprivate static func makePlaceKey(place: Place) -> String {
        makeKey(placeID: place.id)
    }

    fileprivate static func makeKey(placeID: PlaceID) -> String {
        "\(Cache.Key.conditions)-id-\(placeID.cacheComponent)"
    }

    fileprivate static func makeSettingsKey(place: Place) -> String {
        "\(Cache.Key.settings)-id-\(place.id.cacheComponent)"
    }
}
