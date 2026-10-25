import SwiftUI

@MainActor
public struct WaveInfo: View {
    let date: Date
    let max: Double
    let middle: Double
    let period: Double
    let directionDegrees: Double
    let directionLabel: String

    public init(
        date: Date,
        max: Double,
        middle: Double,
        period: Double,
        directionDegrees: Double,
        directionLabel: String
    ) {
        self.date = date
        self.max = max
        self.middle = middle
        self.period = period
        self.directionDegrees = directionDegrees
        self.directionLabel = directionLabel
    }

    public var body: some View {
        VStack {
            DirectionIndicator(
                degrees: directionDegrees,
                formatted: directionLabel
            )

            middle.feetText()
                .font(.title2)
                .fontWeight(.bold)

            TimestampCaption(date: date)
        }
        .cappedDynamicType()
    }
}
