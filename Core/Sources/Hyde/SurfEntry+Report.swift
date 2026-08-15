import Foundation
import DomainTypes

extension SurfEntry.Wave {
    init?(report: Report.Wave?) {
        guard
            let direction = Direction(danish: report?.direction),
            let max = report?.height?.max,
            let middle = report?.height?.middle,
            let period = report?.period else {
            logger.error("incomplete report: \(String(describing: report))")
            return nil
        }

        self.init(max: max, middle: middle, period: period, direction: direction)
    }
}

extension SurfEntry.Wind {
    init?(report: Report.Wind?) {
        guard
            let direction = Direction(danish: report?.direction),
            let speed = Speed(report: report?.speed) else {
            logger.error("incomplete report: \(String(describing: report))")
            return nil
        }

        self.init(speed: speed, direction: direction)
    }
}

extension SurfEntry.Wind.Speed {
    init?(report: Report.Wind.Speed?) {
        guard
            let current = report?.current,
            let middle = report?.middle else {
            logger.error("incomplete report: \(String(describing: report))")
            return nil
        }

        self.init(gust: report?.gust, middle: middle, current: current)
    }
}

extension SurfEntry {
    init?(report: Report?, place: Place) {
        guard
            let wave = Wave(report: report?.wave),
            let wind = Wind(report: report?.wind),
            let date = report?.date else {
            logger.error("incomplete report: \(String(describing: report))")
            return nil
        }

        self.init(date: date, place: place, status: .ok, wave: wave, wind: wind)
    }
}
