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
                    VStack {
                        wave.middle.feetText()
                            .font(.title2)
                            .fontWeight(.black)

                        Text(wave.period.seconds())
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .cappedDynamicType()
                    }
                }
                .overlay(alignment: .bottom) {
                    DirectionIndicator(direction: wave.direction)
                }
                Spacer()
                SurfGauge(
                    value: wind.speed.middle,
                    total: wind.speed.gust ?? wind.speed.middle,
                    tint: .teal
                ) {
                    wind.speed.middle.knotsText()
                        .font(.title2)
                        .fontWeight(.black)
                }
                .overlay(alignment: .bottom) {
                    DirectionIndicator(direction: wind.direction)
                }
                Spacer()
            }

            HomeFooter(entry: entry)
        }
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
