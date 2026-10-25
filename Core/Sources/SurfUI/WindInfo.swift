import DomainTypes
import SwiftUI

@MainActor
public struct WindInfo: View {
    let date: Date
    let speed: Double
    let direction: Direction

    public init(date: Date, speed: Double, direction: Direction) {
        self.date = date
        self.speed = speed
        self.direction = direction
    }

    public var body: some View {
        VStack {
            DirectionIndicator(
                degrees: direction.degrees,
                formatted: direction.formatted()
            )

            speed.knotsText()
                .font(.title2)
                .fontWeight(.bold)

            TimestampCaption(date: date)
        }
        .cappedDynamicType()
    }
}
