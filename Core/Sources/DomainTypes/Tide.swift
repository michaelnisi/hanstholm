import Foundation

public struct Tide: Hashable, Sendable, Codable {
    public let high: Date
    public let low: Date

    public init(high: Date, low: Date) {
        self.high = high
        self.low = low
    }

    public func next(after date: Date) -> Date? {
        [high, low]
            .filter { $0 > date }
            .min()
    }
}
