//
//  SurfEntry+Hyde.swift
//
//
//  Created by Michael Nisi on 26.05.24.
//

import Foundation
import Hyde
import os.log

private let logger = Logger(subsystem: "ink.codes.Hanstholm", category: "DomainTypes")

extension SurfEntry.Wave {
    public init?(dto: Hyde.Wave?) {
        guard 
            let direction = Direction(danish: dto?.direction),
            let max = dto?.height?.max,
            let middle = dto?.height?.middle,
            let period = dto?.period else {
            logger.error("incomplete DTO: \(String(describing: dto))")
            return nil
        }
        
        self.max = max
        self.middle = middle
        self.direction = direction
        self.period = period
    }
}

extension SurfEntry.Wind {
    public init?(dto: Hyde.Wind?) {
        guard
            let direction = Direction(danish: dto?.direction),
            let speed = Speed(dto: dto?.speed) else {
            logger.error("incomplete DTO: \(String(describing: dto))")
            return nil
        }
        
        self.direction = direction
        self.speed = speed
    }
}

extension SurfEntry.Wind.Speed {
    public init?(dto: Hyde.Wind.Speed?) {
        guard 
            let current = dto?.current,
            let gust = dto?.gust,
            let middle = dto?.middle else {
            logger.error("incomplete DTO: \(String(describing: dto))")
            return nil
        }
        
        self.current = current
        self.gust = gust
        self.middle = middle
    }
}

extension SurfEntry {
    public init?(dto: Hyde?) {
        guard 
            let wave = Wave(dto: dto?.wave),
            let wind = Wind(dto: dto?.wind),
            let date = dto?.date,
            let name = dto?.place.name else {
            logger.error("incomplete DTO: \(String(describing: dto))")
            return nil
        }
        
        self.date = date
        self.name = name
        self.status = .ok
        self.wave = wave
        self.wind = wind
    }
}
