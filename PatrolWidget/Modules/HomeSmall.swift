#if !os(watchOS)
import DomainTypes
import SurfUI
import SwiftUI
import WidgetKit

struct HomeSmall: View {
    var entry: SurfEntry

    var body: some View {
        VStack(spacing: 4) {
            SurfGauge(value: entry.wave.middle, total: entry.wave.max, tint: .blue) {
                VStack {
                    entry.wave.middle.feetText()
                        .font(.title2)
                        .fontWeight(.black)

                    Text(entry.wave.period.seconds())
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .cappedDynamicType()
                }
            }
            .overlay(alignment: .bottom) {
                DirectionIndicator(direction: entry.wave.direction)
            }
            Text(entry.place.name)
                .font(.caption)
                .fontWeight(.semibold)
                .cappedDynamicType()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("At \(entry.place.name), \(entry.wave.spoken).")
    }
}

#if DEBUG
#Preview("Small", as: .systemSmall) {
    PreviewWidget { HomeSmall(entry: $0) }
} timeline: {
    SurfEntry.typical
    SurfEntry.longPlaceName
    SurfEntry.noGust
    SurfEntry.highSurf
}
#endif
#endif
