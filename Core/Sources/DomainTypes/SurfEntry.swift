import WidgetKit
import SwiftUI

public struct SurfEntry: TimelineEntry, Identifiable, Hashable, Sendable, Codable {
    public enum Status: Hashable, Sendable, Codable {
        case ok, error, initial
    }

    public struct Wave: Hashable, Sendable, Codable {
        public let max: Double
        public let middle: Double
        public let period: Double
        public let direction: Direction
        
        public init(max: Double, middle: Double, period: Double, direction: Direction) {
            self.max = max
            self.middle = middle
            self.period = period
            self.direction = direction
        }
    }
    
    public struct Wind: Hashable, Sendable, Codable {
        public struct Speed: Hashable, Sendable, Codable {
            public let gust: Double?
            public let middle: Double
            public let current: Double

            public init(gust: Double?, middle: Double, current: Double) {
                self.gust = gust
                self.middle = middle
                self.current = current
            }
        }
        
        public let speed: Speed
        public let direction: Direction
        
        public init(speed: Speed, direction: Direction) {
            self.speed = speed
            self.direction = direction
        }
    }
    
    public let date: Date
    public let place: Place
    public let status: Status
    public let wave: Wave
    public let wind: Wind

    public var id: String {
        "\(place.id)-\(date.formatted())"
    }

    public static let cacheTTL: TimeInterval = 15 * 60

    public var relevance: TimelineEntryRelevance? {
        switch status {
        case .ok:
            TimelineEntryRelevance(score: 50, duration: Self.cacheTTL)
        case .error, .initial:
            TimelineEntryRelevance(score: 0)
        }
    }

    public init(date: Date, place: Place, status: Status, wave: Wave, wind: Wind) {
        self.date = date
        self.place = place
        self.status = status
        self.wave = wave
        self.wind = wind
    }
}

extension SurfEntry: Equatable {
    public static func == (lhs: SurfEntry, rhs: SurfEntry) -> Bool {
        lhs.id == rhs.id && lhs.date == rhs.date
    }
}

