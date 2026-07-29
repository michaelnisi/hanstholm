//
//  SurfEntry+Hyde.swift
//
//
//  Created by Michael Nisi on 26.05.24.
//

import Foundation
import Hyde
import DomainTypes

// These initializers delegate to the memberwise ones rather than assigning stored
// properties: they live outside the module that declares `SurfEntry` now, and cross-module
// extension initializers aren't allowed to assign directly.

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

        self.init(max: max, middle: middle, period: period, direction: direction)
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

        self.init(speed: speed, direction: direction)
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

        self.init(gust: gust, middle: middle, current: current)
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

        self.init(date: date, name: name, status: .ok, wave: wave, wind: wind)
    }
}
