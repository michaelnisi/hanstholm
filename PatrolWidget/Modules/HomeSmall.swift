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
            Text(entry.place.name)
                .font(.caption)
                .fontWeight(.semibold)
                .cappedDynamicType()
        }
        .fontDesign(.rounded)
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
