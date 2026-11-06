import Foundation

public struct Light: Hashable, Sendable, Codable {
    public let first: Date
    public let last: Date

    public init(first: Date, last: Date) {
        self.first = first
        self.last = last
    }

    public func next(after date: Date) -> Date? {
        [first, last]
            .filter { $0 > date }
            .min()
    }
}
