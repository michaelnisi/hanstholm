import Foundation

struct Report: Equatable, Sendable {
    struct Wave: Equatable, Sendable {
        struct Height: Equatable, Sendable {
            let max: Double?
            let middle: Double?

            init(max: Double?, middle: Double?) {
                self.max = max
                self.middle = middle
            }
        }

        let height: Height?
        let period: Double?
        let direction: String?

        init(height: Height?, period: Double?, direction: String?) {
            self.height = height
            self.period = period
            self.direction = direction
        }
    }

    struct Wind: Equatable, Sendable {
        struct Speed: Equatable, Sendable {
            let gust: Double?
            let middle: Double?
            let current: Double?

            init(gust: Double?, middle: Double?, current: Double?) {
                self.gust = gust
                self.middle = middle
                self.current = current
            }
        }

        let speed: Speed?
        let direction: String?

        init(speed: Speed?, direction: String?) {
            self.speed = speed
            self.direction = direction
        }
    }

    let station: Hyde.Station
    let date: Date
    let wave: Wave?
    let wind: Wind?

    init(station: Hyde.Station, date: Date, wave: Wave?, wind: Wind?) {
        self.station = station
        self.date = date
        self.wave = wave
        self.wind = wind
    }
}

extension Report {
    init(station: Hyde.Station, data: Data) throws {
        let parts = try data.parsed()

        logger.debug("data parsed: \(parts)")

        let wave = Wave(
            height: .init(
                max: parts.maxWaveHeight(for: station)?.double(),
                middle: parts.middleWaveHeight(for: station)?.double()
            ),
            period: parts.wavePeriod()?.double(),
            direction: String(parts.waveDirection() ?? "")
        )

        let wind = Wind(
            speed: .init(
                gust: parts.windGust()?.double(),
                middle: parts.windMiddle(for: station)?.double(),
                current: parts.windCurrent(for: station)?.double()
            ),
            direction: String(parts.windDirection(for: station) ?? "")
        )

        self.init(station: station, date: .now, wave: wave, wind: wind)
    }
}
