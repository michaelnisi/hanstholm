//
//  SurfEntry.swift
//  Hanstholm
//
//  Created by Michael Nisi on 10.05.24.
//

import WidgetKit
import SwiftUI

public struct SurfEntry: TimelineEntry, Identifiable, Hashable {
    public enum Status: Hashable {
        case ok, error, initial
    }
   
    public struct Wave: Hashable {
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

