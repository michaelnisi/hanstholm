import Foundation
import DomainTypes

extension UserDefaults: @retroactive @unchecked Sendable {}

public protocol PlaceSettings: Codable, Sendable {}

public actor Cache {
    struct Key {
        static let conditions = "ink.codes.Patrol.Cache.conditions"
        static let settings = "ink.codes.Patrol.Cache.settings"
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
    public func conditions(matching place: Place) throws -> SurfEntry? {
        guard let data = db?.data(forKey: .makePlaceKey(place: place)) else {
            return nil
        }

        return try decoder.decode(SurfEntry.self, from: data)
    }

    public func conditions(matching place: Place, newer: Date) throws -> SurfEntry? {
        guard let data = try conditions(matching: place), data.date >= newer else {
            return nil
        }

        return data
    }

    public func setConditions(_ value: SurfEntry) throws {
        let data = try encoder.encode(value)

        db?.setValue(data, forKey: .makePlaceKey(place: value.place))
    }
}

extension Cache {
    public func settings<T: PlaceSettings>(for place: Place) throws -> T? {
        guard let data = db?.data(forKey: .makeSettingsKey(place: place, type: T.self)) else {
            return nil
        }

        return try decoder.decode(T.self, from: data)
    }

    public func setSettings<T: PlaceSettings>(_ value: T, for place: Place) throws {
        let data = try encoder.encode(value)

        db?.setValue(data, forKey: .makeSettingsKey(place: place, type: T.self))
    }
}

extension Cache {
    public func setSelectedPlace(_ place: Place) throws {
        let data = try encoder.encode(place.id)

        db?.setValue(data, forKey: .selectedPlaceKey)
    }

    public func selectedPlaceID() -> String? {
        guard let data = db?.data(forKey: .selectedPlaceKey) else {
            return nil
        }

        return try? decoder.decode(String.self, from: data)
    }

    public func selectedConditions() throws -> SurfEntry? {
        guard let id = selectedPlaceID(), let data = db?.data(forKey: .makeKey(placeID: id)) else {
            return nil
        }

        return try decoder.decode(SurfEntry.self, from: data)
    }
}

extension String {
    fileprivate static let selectedPlaceKey = "\(Cache.Key.conditions)-selected"

    fileprivate static func makePlaceKey(place: Place) -> String {
        makeKey(placeID: place.id)
    }

    fileprivate static func makeKey(placeID: String) -> String {
        "\(Cache.Key.conditions)-id-\(placeID)"
    }

    // Disambiguates by both place and settings type, so unrelated Codable
    // structs (e.g. a view-mode setting and a widget-config setting) can
    // each be stored per place without colliding.
    fileprivate static func makeSettingsKey<T>(place: Place, type: T.Type) -> String {
        "\(Cache.Key.settings)-id-\(place.id)-\(String(describing: type))"
    }
}
