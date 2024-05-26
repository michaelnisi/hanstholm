//
//  Direction.swift
//
//
//  Created by Michael Nisi on 24.05.24.
//

import Foundation

public struct Direction: Hashable, Equatable {
    public enum Cardinal {
        case north
        case northNorthEast
        case northEast
        case eastNorthEast
        case east
        case eastSouthEast
        case southEast
        case southSouthEast
        case south
        case southSouthWest
        case southWest
        case westSouthWest
        case west
        case westNorthWest
        case northWest
        case northNorthWest
    }
    
    public init(cardinal: Cardinal) {
        self.cardinal = cardinal
        
        switch cardinal {
        case .north:
            degrees = 180
        case .northNorthEast:
            degrees = 202.5
        case .northEast:
            degrees = 225
        case .eastNorthEast:
            degrees = 247.5
        case .east:
            degrees = 270
        case .eastSouthEast:
            degrees = 292.5
        case .southEast:
            degrees = 315
        case .southSouthEast:
            degrees = 337.5
        case .south:
            degrees = 0
        case .southSouthWest:
            degrees = 22.5
        case .southWest:
            degrees = 45
        case .westSouthWest:
            degrees = 67.5
        case .west:
            degrees = 90
        case .westNorthWest:
            degrees = 112.5
        case .northWest:
            degrees = 135
        case .northNorthWest:
            degrees = 157.5
        }
    }
    
    public let cardinal: Cardinal
    public let degrees: Double
}

extension Direction {
    static let danishToCardinal: [String: Cardinal] = [
        "N": .north,
        "NNØ": .northNorthEast,
        "NØ": .northEast,
        "ØNØ": .eastNorthEast,
        "Ø": .east,
        "ØSØ": .eastSouthEast,
        "SØ": .southEast,
        "SSØ": .southSouthEast,
        "S": .south,
        "SSV": .southSouthWest,
        "SV": .southWest,
        "VSV": .westSouthWest,
        "V": .west,
        "VNV": .westNorthWest,
        "NV": .northWest,
        "NNV": .northNorthWest
    ]
    
    public init?(danish string: String?) {
        guard let string, let cardinal = Direction.danishToCardinal[string] else {
            return nil
        }
        
        self.init(cardinal: cardinal)
    }
}

extension Direction {
    static let cardinalToEnglish: [Cardinal: String] = [
        .north: "N",
        .northNorthEast: "NNE",
        .northEast: "NE",
        .eastNorthEast: "ENE",
        .east: "E",
        .eastSouthEast: "ESE",
        .southEast: "SE",
        .southSouthEast: "SSE",
        .south: "S",
        .southSouthWest: "SSW",
        .southWest: "SW",
        .westSouthWest: "WSW",
        .west: "W",
        .westNorthWest: "WNW",
        .northWest: "NW",
        .northNorthWest: "NNW"
    ]
    
    public func formatted() -> String {
        Direction.cardinalToEnglish[cardinal]!
    }
}
