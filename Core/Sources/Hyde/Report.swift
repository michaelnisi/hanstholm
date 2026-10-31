import ConditionsPlugin
import DomainTypes
import Foundation

struct Report: Equatable, Sendable {
    struct Wave: Equatable, Sendable {
        struct Height: Equatable, Sendable {
            let max: Double?
            let middle: Double?
        }

        let height: Height?
        let period: Double?
        let direction: String?
    }

    struct Wind: Equatable, Sendable {
        struct Speed: Equatable, Sendable {
            let gust: Double?
            let middle: Double?
            let current: Double?
        }

        let speed: Speed?
        let direction: String?
    }

    let station: Hyde.Station
    let date: Date
    let wave: Wave?
    let wind: Wind?
    var withheld: Set<Part> = []
}

extension Report {
    enum Part: String, Hashable, Sendable {
        case wave
        case wind
    }

    var fault: ConditionsFault {
        guard !withheld.isEmpty, isComplete(except: withheld) else {
            return .decoding
        }

        return .unavailable(withheld.map(\.rawValue).sorted().joined(separator: ", "))
    }

    private func isComplete(except withheld: Set<Part>) -> Bool {
        let waveIsComplete = withheld.contains(.wave) || SurfEntry.Wave(report: wave) != nil
        let windIsComplete = withheld.contains(.wind) || SurfEntry.Wind(report: wind) != nil

        return waveIsComplete && windIsComplete
    }
}

extension Report {
    init(station: Hyde.Station, data: Data) throws {
        let parts = try data.parsed()

        logger.debug("data parsed: \(parts)")

        let maxHeight = try parts.required(Hyde.Label.maxWaveHeight)
        let middleHeight = try parts.required(Hyde.Label.middleWaveHeight)
        let period = try parts.required(Hyde.Label.wavePeriod)
        let waveDirection = try parts.required(Hyde.Label.waveDirection).withoutBearing()
        let windCurrent = try parts.required(Hyde.Label.windCurrent)
        let windMiddle = try parts.required(Hyde.Label.windMiddle)
        let windDirection = try parts.required(Hyde.Label.windDirection).withoutBearing()

        let wave = Wave(
            height: .init(max: maxHeight.double(), middle: middleHeight.double()),
            period: period.double(),
            direction: String(waveDirection)
        )

        let wind = Wind(
            speed: .init(
                gust: parts.windGust()?.double(),
                middle: windMiddle.double(),
                current: windCurrent.double()
            ),
            direction: String(windDirection)
        )

        var withheld: Set<Part> = []

        if ![maxHeight, middleHeight, period].contains(where: \.containsDigit) {
            withheld.insert(.wave)
        }

        if ![windCurrent, windMiddle].contains(where: \.containsDigit) {
            withheld.insert(.wind)
        }

        self.init(station: station, date: .now, wave: wave, wind: wind, withheld: withheld)
    }
}
