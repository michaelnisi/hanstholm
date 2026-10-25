import DomainTypes
import SwiftUI

@MainActor
public struct WaveInfo: View {
    let date: Date
    let max: Double
    let middle: Double
    let period: Double
    let direction: Direction

    public init(date: Date, max: Double, middle: Double, period: Double, direction: Direction) {
        self.date = date
        self.max = max
        self.middle = middle
        self.period = period
        self.direction = direction
    }

    public var body: some View {
        VStack {
            DirectionIndicator(
                degrees: direction.degrees,
                formatted: direction.formatted()
            )

            middle.feetText()
                .font(.title2)
                .fontWeight(.bold)

            TimestampCaption(date: date)
        }
        .cappedDynamicType()
    }
}
