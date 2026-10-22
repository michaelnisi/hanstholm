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

#Preview("Wave and period", as: .accessoryCircular) {
    PatrolWidget()
} timeline: {
    SurfEntry.typical
    SurfEntry.highSurf
}
