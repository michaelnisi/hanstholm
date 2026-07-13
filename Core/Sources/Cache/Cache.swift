//
//  Cache.swift
//
//
//  Created by Michael Nisi on 20.05.24.
//

import Foundation
import Hyde

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
    public func conditions(matching place: Hyde.Place) throws -> Hyde? {
        guard let data = db?.data(forKey: .makePlaceKey(place: place)) else {
            return nil
        }
        
        return try decoder.decode(Hyde.self, from: data)
    }
    
    public func conditions(matching place: Hyde.Place, newer: Date) throws -> Hyde? {
        guard let data = try conditions(matching: place), data.date >= newer else {
            return nil
        }
        
        return data
    }
    
    public func setConditions(_ value: Hyde) throws {
        let data = try encoder.encode(value)
        
        db?.setValue(data, forKey: .makePlaceKey(place: value.place))
    }
}

extension Cache {
    public func setPlace(_ place: Hyde.Place) throws {
        let data = try encoder.encode(place)
        
        db?.setValue(data, forKey: .selectedPlaceKey)
    }
    
    public func place() -> Hyde.Place {
        guard let data = db?.data(forKey: .selectedPlaceKey),
              let place = try? decoder.decode(Hyde.Place.self, from: data) else {
            return .hanstholm
        }
        
        return place
    }
}

extension String {
    fileprivate static let selectedPlaceKey = "\(Cache.Key.surfEntry)-selected"
    
    fileprivate static func makePlaceKey(place: Hyde.Place) -> String {
        "\(Cache.Key.surfEntry)-id-\(place.name)"
    }
}
