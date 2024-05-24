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
        public init(max: Double, middle: Double, period: Double) {
            self.max = max
            self.middle = middle
            self.period = period
        }
        
        public let max: Double
        public let middle: Double
        public let period: Double
    }
    
    public struct Wind: Hashable {
        public init(speed: Double, direction: Direction) {
            self.speed = speed
            self.direction = direction
        }
        
        public let speed: Double
        public let direction: Direction
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
    public init(dto: Hyde?) {
        guard let dto, let direction = Direction(danish: dto.wind.direction) else {
            self.date = .now
            self.name = "Somewhere"
            self.status = .initial
            self.wave = .init(max: 0, middle: 0, period: 0)
            self.wind = .init(speed: 0, direction: .init(cardinal: .southWest))
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
        self.wind = .init(speed: dto.wind.speed, direction: direction)
    }
}

extension SurfEntry {
    public init(name: String) {
        self.date = .distantPast
        self.name = name
        self.status = .initial
        self.wave = .init(max: 0, middle: 0, period: 0)
        self.wind = .init(speed: 0, direction: .init(cardinal: .southWest))
    }
}
