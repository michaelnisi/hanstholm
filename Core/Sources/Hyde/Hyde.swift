//
//  Hyde.swift
//
//
//  Created by Michael Nisi on 07.04.24.
//

import os.log
import Foundation

let logger = Logger(subsystem: "ink.codes.Hanstholm", category: "Hyde")

public struct Hyde: Equatable, Codable, Sendable {
    public enum Place: Codable, CaseIterable, Sendable {
        case hanstholm
    }
    
    public struct Wave: Equatable, Codable, Sendable {
        public struct Height: Equatable, Codable, Sendable {
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
    
    public struct Wind: Equatable, Codable, Sendable {
        public struct Speed: Equatable, Codable, Sendable {
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
        case unexpectedMediaType
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

extension Hyde {
    public static func fetch(place: Place) async throws -> Hyde {
        try .init(place: place, data: try await Fetcher.shared.retrieve())
    }
    
    public static func backgroundFetch(place: Place) async {
        await Fetcher.shared.background()
    }
    
    public static func backgroundResult(place: Place) async -> Hyde? {
        guard let data = await Fetcher.shared.cached else {
            return nil
        }
        
        return try? .init(place: place, data: data)
    }
    
 
    
    public static func setCompletion(_ completion: @escaping BackgroundCompletion) async {
        await Fetcher.shared.setCompletion {
            await MainActor.run {
                completion()
            }
        }
        
    }
}

public typealias BackgroundCompletion = @Sendable @MainActor () -> Void
