#if !os(watchOS)
import DomainTypes
import SurfUI
import SwiftUI
import WidgetKit

struct HomeMedium: View {
    var entry: SurfEntry

    var wave: SurfEntry.Wave {
        entry.wave
    }

    var wind: SurfEntry.Wind {
        entry.wind
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 24) {
                Spacer()
                SurfGauge(value: wave.middle, total: wave.max, tint: .blue) {
                    GaugeReadout(
                        element: .wave,
                        value: entry.wave.middle,
                        direction: entry.wave.direction
                    )
                }
                .overlay(alignment: .bottom) {
                    Text(entry.wave.period.seconds())
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .cappedDynamicType()
                }
                Spacer()
                SurfGauge(
                    value: entry.wind.speed.middle,
                    total: entry.wind.speed.gust ?? entry.wind.speed.middle,
                    tint: .teal
                ) {
                    GaugeReadout(
                        element: .wind,
                        value: entry.wind.speed.current,
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

#if DEBUG
#Preview("Medium", as: .systemMedium) {
    PreviewWidget { HomeMedium(entry: $0) }
} timeline: {
    SurfEntry.typical
    SurfEntry.longPlaceName
    SurfEntry.noGust
    SurfEntry.highSurf
}
#endif
#endif
