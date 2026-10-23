#if os(watchOS)
import DomainTypes
import SwiftUI
import WidgetKit

struct AccessoryCorner: View {
    var entry: SurfEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            Image(systemName: "water.waves")
                .font(.title.bold())
                .widgetAccentable()
        }
        .widgetLabel {
            Text(entry.wave.middle.feet() + " @ " + entry.wave.period.seconds())
                .accessibilityLabel(entry.wave.spoken)
        }
    }
}

#if DEBUG
#Preview("Corner", as: .accessoryCorner) {
    PreviewWidget { AccessoryCorner(entry: $0) }
} timeline: {
    SurfEntry.typical
    SurfEntry.longPlaceName
    SurfEntry.noGust
    SurfEntry.highSurf
}
#endif
#endif
