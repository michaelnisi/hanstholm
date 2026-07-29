//
//  Hyde.swift
//
//
//  Created by Michael Nisi on 07.04.24.
//

import os.log
import Foundation

let logger = Logger(subsystem: "ink.codes.Hanstholm", category: "Hyde")

public struct Hyde: Equatable, Sendable {
    public enum Place: CaseIterable, Equatable, Sendable {
        case hanstholm
    }

    public struct Wave: Equatable, Sendable {
        public struct Height: Equatable, Sendable {
            public let max: Double?
            public let middle: Double?
            
            public init(max: Double?, middle: Double?) {
                self.max = max
                self.middle = middle
            }
        }
        
        public let height: Height?
        public let period: Double?
        public let direction: String?
        
        public init(height: Height?, period: Double?, direction: String?) {
            self.height = height
            self.period = period
            self.direction = direction
        }
    }
    
    public struct Wind: Equatable, Sendable {
        public struct Speed: Equatable, Sendable {
            public init(gust: Double?, middle: Double?, current: Double?) {
                self.gust = gust
                self.middle = middle
                self.current = current
            }
            
            public let gust: Double?
            public let middle: Double?
            public let current: Double?
        }
        
        public let speed: Speed?
        public let direction: String?
        
        public init(speed: Speed?, direction: String?) {
            self.speed = speed
            self.direction = direction
        }
    }
   
    public enum Fault: Error {
        case parsing
        case missing(String)
        case transform(String)
    }
    
    public let place: Place
    public let date: Date
    public let wave: Wave?
    public let wind: Wind?
    
    public init(place: Place, date: Date, wave: Wave?, wind: Wind?) {
        self.place = place
        self.date = date
        self.wave = wave
        self.wind = wind
    }
}

extension Hyde.Place {
    public var name: String {
        switch self {
        case .hanstholm:
            return "Hanstholm"
        }
    }

    /// Stable identity, kept apart from `name` so the displayed label can change without
    /// orphaning anything filed under it.
    public var key: String {
        switch self {
        case .hanstholm:
            return "hanstholm"
        }
    }

    public init?(key: String) {
        switch key {
        case "hanstholm":
            self = .hanstholm
        default:
            return nil
        }
    }

    /// Where this place's conditions are published.
    ///
    /// Lives with the place rather than with whatever happens to be fetching it, so the
    /// source description stays in one piece.
    public var url: URL {
        switch self {
        case .hanstholm:
            return URL(string: "https://hyde.dk/default_hanstholm.asp")!
        }
    }
}

extension Hyde {
    public init(place: Place, data: Data) throws {
        let parts = try data.parsed()
        
        logger.debug("data parsed: \(parts)")
        
        let wave = Wave(
            height: .init(
                max: parts.maxWaveHeight()?.double(),
                middle: parts.middleWaveHeight()?.double()
            ),
            period: parts.wavePeriod()?.double(),
            direction: String(parts.waveDirection() ?? "")
        )
        
        let wind = Wind(
            speed: .init(
                gust: parts.windGust()?.double(),
                middle: parts.windMiddle()?.double(),
                current: parts.windCurrent()?.double()
            ),
            direction: String(parts.windDirection() ?? "")
        )
        
        self.init(place: place, date: .now, wave: wave, wind: wind)
    }
}

