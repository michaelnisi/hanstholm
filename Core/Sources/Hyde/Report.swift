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
}

extension Report {
    init(station: Hyde.Station, data: Data) throws {
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

        self.init(station: station, date: .now, wave: wave, wind: wind)
    }
}
