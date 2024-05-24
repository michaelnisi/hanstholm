//
//  Hyde.swift
//
//
//  Created by Michael Nisi on 07.04.24.
//

import WidgetKit
import os.log

private let logger = Logger(subsystem: "ink.codes.Hyde", category: "Hyde")

public struct Hyde: Equatable, Codable, Identifiable, TimelineEntry {
    public enum Place: Codable, CaseIterable {
        case hanstholm
    }
    
    public struct Wave: Equatable, Codable {
        public struct Height: Equatable, Codable {
            public let max: Double
            public let middle: Double
            
            public init(max: Double, middle: Double) {
                self.max = max
                self.middle = middle
            }
        }
        
        public let height: Height
        public let period: Double
        
        public init(height: Height, period: Double) {
            self.height = height
            self.period = period
        }
    }
    
    public struct Wind: Equatable, Codable {
        public struct Speed: Equatable, Codable {
            public init(gust: Double, middle: Double, current: Double) {
                self.gust = gust
                self.middle = middle
                self.current = current
            }
            
            public let gust: Double
            public let middle: Double
            public let current: Double
        }
        
        public let speed: Speed
        public let direction: String
        
        public init(speed: Speed, direction: String) {
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
    
    public let date: Date
    public let place: Place
    public let wave: Wave
    public let wind: Wind
    
    public var id: String {
        date.ISO8601Format()
    }
    
    public init(date: Date, place: Place, wave: Wave, wind: Wind) {
        self.date = date
        self.place = place
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
        
        guard let middleWaveHeightSubstring = parts.middleWaveHeight() else {
            throw Fault.missing("middle wave height")
        }
        
        guard let maxWaveHeightSubstring = parts.maxWaveHeight() else {
            throw Fault.missing("max wave height")
        }
        
        guard let wavePeriodSubstring = parts.wavePeriod() else {
            throw Fault.missing("wave period")
        }
        
        guard let windGustSubstring = parts.windGust() else {
            throw Fault.missing("wind gust")
        }
        
        guard let windMiddleSubstring = parts.windMiddle() else {
            throw Fault.missing("wind middle")
        }
        
        guard let windCurrentSubstring = parts.windCurrent() else {
            throw Fault.missing("wind current")
        }
        
        guard let windDirectionSubstring = parts.windDirection() else {
            throw Fault.missing("wind direction")
        }
        
        guard let middleWaveHeight = middleWaveHeightSubstring.double() else {
            throw Fault.transform("middle wave height")
        }
        
        guard let maxWaveHeight = maxWaveHeightSubstring.double() else {
            throw Fault.transform("max wave height")
        }
        
        guard let wavePeriod = wavePeriodSubstring.double() else {
            throw Fault.transform("wave period")
        }
        
        guard let windGust = windGustSubstring.double() else {
            throw Fault.transform("wind gust")
        }
        
        guard let windCurrent = windCurrentSubstring.double() else {
            throw Fault.transform("wind current")
        }
        
        guard let windMiddle = windMiddleSubstring.double() else {
            throw Fault.transform("wind middle")
        }
        
        let waveHeight = Wave.Height(max: maxWaveHeight, middle: middleWaveHeight)
        let wave = Wave(height: waveHeight, period: wavePeriod)
        let windSpeed = Wind.Speed(gust: windGust, middle: windMiddle, current: windCurrent)
        let wind = Wind(speed: windSpeed, direction: String(windDirectionSubstring))
        
        self.init(date: .now, place: place, wave: wave, wind: wind)
    }
}

extension Hyde {
    public static func fetch(place: Place = .hanstholm) async throws -> Hyde {
        try .init(place: place, data: try await Fetcher.shared.retrieve())
    }
    
    public static func backgroundFetch(place: Place = .hanstholm) {
        Fetcher.shared.background()
    }
    
    public static func backgroundResult(place: Place = .hanstholm) -> Hyde? {
        guard let data = Fetcher.shared.cached else {
            return nil
        }
        
        return try? .init(place: place, data: data)
    }
    
    @discardableResult
    public static func setCompletion(_ completion: @escaping () -> Void) -> String {
        Fetcher.shared.setCompletion(completion)
    }
}

