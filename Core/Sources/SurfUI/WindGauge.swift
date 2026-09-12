import SwiftUI
import DomainTypes
import MockData

@MainActor
public struct WindGauge: View {
    public var wind: SurfEntry.Wind
    public var strokeWidth: Double

    public init(wind: SurfEntry.Wind, strokeWidth: Double = 14) {
        self.wind = wind
        self.strokeWidth = strokeWidth
    }

    public var body: some View {
        SurfGauge(
            value: wind.speed.middle,
            total: wind.speed.gust ?? wind.speed.middle,
            tint: .teal,
            strokeWidth: strokeWidth
        ) {
            GaugeReadout(
                symbol: "wind",
                value: wind.speed.current.knots(),
                caption: wind.speed.gust.knots(),
                degrees: wind.direction.degrees
            )
        }
        .padding(strokeWidth / 2)
    }
}

#Preview {
    WindGauge(wind: MockData.SurfEntry.makeWind())
        .padding()
}
