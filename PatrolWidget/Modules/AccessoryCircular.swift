import DomainTypes
import SwiftUI
import WidgetKit

struct AccessoryCircular: View {
    var entry: SurfEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack {
                Text(entry.wave.middle.feet(width: .narrow))
                Text(entry.wave.period.seconds(width: .narrow))
            }
            .widgetAccentable()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(entry.wave.spoken)
    }
}

#if DEBUG
#Preview("Circular", as: .accessoryCircular) {
    PreviewWidget { AccessoryCircular(entry: $0) }
} timeline: {
    SurfEntry.typical
    SurfEntry.longPlaceName
    SurfEntry.noGust
    SurfEntry.highSurf
}
#endif
