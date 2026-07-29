//
//  Cache.swift
//
//
//  Created by Michael Nisi on 20.05.24.
//

import Foundation
import DomainTypes

// UserDefaults is documented as thread-safe but isn't marked Sendable by the SDK,
// so passing an injected instance across the Cache actor boundary needs this.
extension UserDefaults: @retroactive @unchecked Sendable {}

public actor Cache {
    struct Key {
        static let surfEntry = "ink.codes.Hanstholm.Cache.Hyde"
    }

    private let db: UserDefaults?
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    public init(userDefaults: UserDefaults? = UserDefaults(suiteName: "group.ink.codes.Hanstholm")) {
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

    /// Files the entry under its own place, which is why the coordinator checks that a
    /// plugin returned conditions for the place it was asked about — otherwise a write
    /// could land under a key nothing ever reads.
    public func setConditions(_ value: SurfEntry) throws {
        let data = try encoder.encode(value)

        db?.setValue(data, forKey: .makePlaceKey(place: value.place))
    }
}

extension Cache {
    /// Stores only the identifier: the plugin stays the source of truth for a place's
    /// display name, so renaming one doesn't leave a stale copy here.
    public func setSelectedPlace(_ place: Place) throws {
        let data = try encoder.encode(place.id)

        db?.setValue(data, forKey: .selectedPlaceKey)
    }

    /// `nil` when nothing has been selected yet. Resolving that to an actual place needs
    /// the installed plugins, which is the coordinator's job, not storage's.
    public func selectedPlaceID() -> String? {
        guard let data = db?.data(forKey: .selectedPlaceKey) else {
            return nil
        }

        return try? decoder.decode(String.self, from: data)
    }

    /// Conditions for whatever place is selected, for read-only consumers that have no
    /// plugins linked and so can't resolve a `Place` themselves.
    public func selectedConditions() throws -> SurfEntry? {
        guard let id = selectedPlaceID(), let data = db?.data(forKey: .makeKey(placeID: id)) else {
            return nil
        }

        return try decoder.decode(SurfEntry.self, from: data)
    }
}

extension String {
    fileprivate static let selectedPlaceKey = "\(Cache.Key.surfEntry)-selected"

    fileprivate static func makePlaceKey(place: Place) -> String {
        makeKey(placeID: place.id)
    }

    fileprivate static func makeKey(placeID: String) -> String {
        "\(Cache.Key.surfEntry)-id-\(placeID)"
    }
}
