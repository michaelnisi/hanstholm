import DomainTypes
import SwiftUI
import WidgetKit

struct AccessoryRectangular: View {
    var entry: SurfEntry

    var body: some View {
        VStack(alignment: .leading) {
            Text(
                "\(Image(systemName: "water.waves")) \(Text(entry.wave.middle.feet()).fontWeight(.black)) @ \(entry.wave.period.seconds())"
            )

            Text(
                "\(Image(systemName: "wind")) \(Text(entry.wind.direction.formatted()).fontWeight(.black)) \(entry.wind.speed.current.knots())"
            )

            footer
        }
        .widgetAccentable()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(entry.spokenSummary)
    }

    private var footer: some View {
        Text("\(entry.place.name), \(entry.date.formatted(date: .omitted, time: .shortened))")
            .font(.caption)
    }
}

#if DEBUG
#Preview("Rectangular", as: .accessoryRectangular) {
    PreviewWidget { AccessoryRectangular(entry: $0) }
} timeline: {
    SurfEntry.typical
    SurfEntry.longPlaceName
    SurfEntry.noGust
    SurfEntry.highSurf
}
#endif
