import SwiftUI

@MainActor
public struct WindInfo: View {
    let date: Date
    let speed: Double
    let directionDegrees: Double
    let directionLabel: String

    public init(date: Date, speed: Double, directionDegrees: Double, directionLabel: String) {
        self.date = date
        self.speed = speed
        self.directionDegrees = directionDegrees
        self.directionLabel = directionLabel
    }

    public var body: some View {
        VStack {
            DirectionIndicator(
                degrees: directionDegrees,
                formatted: directionLabel
            )

            speed.knotsText()
                .font(.title2)
                .fontWeight(.bold)

            TimestampCaption(date: date)
        }
        .cappedDynamicType()
    }
}
