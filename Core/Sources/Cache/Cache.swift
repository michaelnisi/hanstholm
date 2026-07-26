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
    public func conditions(matching place: String) throws -> SurfEntry? {
        guard let data = db?.data(forKey: .makePlaceKey(place: place)) else {
            return nil
        }

        return try decoder.decode(SurfEntry.self, from: data)
    }

    public func conditions(matching place: String, newer: Date) throws -> SurfEntry? {
        guard let data = try conditions(matching: place), data.date >= newer else {
            return nil
        }

        return data
    }

    public func setConditions(_ value: SurfEntry) throws {
        let data = try encoder.encode(value)

        db?.setValue(data, forKey: .makePlaceKey(place: value.name))
    }
}

extension Cache {
    public func setPlace(_ place: String) throws {
        let data = try encoder.encode(place)

        db?.setValue(data, forKey: .selectedPlaceKey)
    }

    public func place() -> String {
        guard let data = db?.data(forKey: .selectedPlaceKey),
              let place = try? decoder.decode(String.self, from: data) else {
            return "Hanstholm"
        }

        return place
    }
}

extension String {
    fileprivate static let selectedPlaceKey = "\(Cache.Key.surfEntry)-selected"

    fileprivate static func makePlaceKey(place: String) -> String {
        "\(Cache.Key.surfEntry)-id-\(place)"
    }
}
