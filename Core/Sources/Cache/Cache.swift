//
//  Cache.swift
//
//
//  Created by Michael Nisi on 20.05.24.
//

import Foundation
import Hyde
import MockData

public struct Cache {
    struct Key {
        static let surfEntry = "ink.codes.Hanstholm.Cache.Hyde"
    }
    
    private let db = UserDefaults(suiteName: "group.ink.codes.Hanstholm")
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    public init() {}
    
    public func dump() -> [String : Any] {
        db?.dictionaryRepresentation() ?? [:]
    }
    
    public func cachedConditions(matching place: Hyde.Place) throws -> Hyde? {
        guard let data = db?.data(forKey: Key.makePlaceKey(place: place)) else {
            return nil
        }
        
        return try decoder.decode(Hyde.self, from: data)
    }
    
    public func cachedConditions(matching place: Hyde.Place, newer: Date) throws -> Hyde? {
        guard let data = try cachedConditions(matching: place), data.date >= newer else {
            return nil
        }
        
        return data
    }
    
    public func cacheConditions(_ value: Hyde) throws {
        let data = try encoder.encode(value)
        
        db?.setValue(data, forKey: Key.makePlaceKey(place: value.place))
    }
}

extension Cache.Key {
    static func makePlaceKey(place: Hyde.Place) -> String {
        "\(surfEntry)-id-\(place.name)"
    }
}
