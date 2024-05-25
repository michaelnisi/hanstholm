//
//  SurfEntry.swift
//  Hanstholm
//
//  Created by Michael Nisi on 10.05.24.
//

import WidgetKit
import SwiftUI
import Hyde

public struct SurfEntry: TimelineEntry, Identifiable, Hashable {
    public enum Status: Hashable {
        case ok, error, initial
    }
   
    public struct Wave: Hashable {
        public let max: Double
        public let middle: Double
        public let period: Double
        
        public init(max: Double, middle: Double, period: Double) {
            self.max = max
            self.middle = middle
            self.period = period
        }
    }
    
    public struct Wind: Hashable {
        public struct Speed: Hashable {
            public let gust: Double
            public let middle: Double
            public let current: Double
            
            public init(gust: Double, middle: Double, current: Double) {
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
    public let name: String
    public let status: Status
    public let wave: Wave
    public let wind: Wind

    public var id: String {
        "\(name)-\(date.formatted())"
    }
    
    public init(date: Date, name: String, status: Status, wave: Wave, wind: Wind) {
        self.date = date
        self.name = name
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

extension SurfEntry {
    public init(dto: Hyde?, name: String = "Somewhere") {
        guard let dto, let direction = Direction(danish: dto.wind.direction) else {
            self.date = .now
            self.name = name
            self.status = .initial
            self.wave = .init(max: 2, middle: 1.2, period: 12)
            self.wind = .init(speed: .init(gust: 10, middle: 6, current: 5), direction: .init(cardinal: .southWest))
            return
        }
        
        self.date = dto.date
        self.name = dto.place.name
        self.status = .ok
        self.wave = .init(
            max: dto.wave.height.max,
            middle: dto.wave.height.middle,
            period: dto.wave.period
        )
        
        self.wind = .init(
            speed: .init(
                gust: dto.wind.speed.gust,
                middle: dto.wind.speed.middle,
                current: dto.wind.speed.current
            ),
            direction: direction
        )
    }
}

extension SurfEntry {
    public init(name: String) {
        self.init(dto: nil, name: name)
    }
}
