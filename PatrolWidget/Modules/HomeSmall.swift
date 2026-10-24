#if !os(watchOS)
import DomainTypes
import SurfUI
import SwiftUI
import WidgetKit

struct HomeSmall: View {
    var entry: SurfEntry

    var body: some View {
        SurfGauge(value: entry.wave.middle, total: entry.wave.max, tint: .blue) {
            GaugeReadout(
                symbol: "water.waves",
                value: entry.wave.middle.feet(),
                caption: entry.wave.period.seconds(),
                direction: entry.wave.direction
            )
        }
        .overlay(alignment: .bottom) {
            Text("\(entry.wind.direction.formatted()) \(entry.wind.speed.current.knots())")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .cappedDynamicType()
        }
        .fontDesign(.rounded)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(entry.wave.spoken), and \(entry.wind.spoken).")
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
