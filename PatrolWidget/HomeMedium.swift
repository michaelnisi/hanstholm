#if !os(watchOS)
import DomainTypes
import SurfUI
import SwiftUI
import WidgetKit

struct HomeMedium: View {
    var entry: SurfEntry

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 24) {
                Spacer()
                SurfGauge(value: entry.wave.middle, total: entry.wave.max, tint: .blue) {
                    GaugeReadout(
                        symbol: "water.waves",
                        value: entry.wave.middle.feet(),
                        caption: entry.wave.period.seconds(),
                        direction: entry.wave.direction
                    )
                }
                Spacer()
                SurfGauge(
                    value: entry.wind.speed.middle,
                    total: entry.wind.speed.gust ?? entry.wind.speed.middle,
                    tint: .teal
                ) {
                    GaugeReadout(
                        symbol: "wind",
                        value: entry.wind.speed.current.knots(),
                        caption: entry.wind.speed.gust.knots(),
                        direction: entry.wind.direction
                    )
                }
                Spacer()
            }

            HomeFooter(entry: entry)
        }
        .fontDesign(.rounded)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(entry.spokenSummary)
    }
}

#Preview("Medium", as: .systemMedium) {
    PatrolWidget()
} timeline: {
    SurfEntry.typical
    SurfEntry.highSurf
    SurfEntry.noGust
    SurfEntry.longPlaceName
}
#endif
