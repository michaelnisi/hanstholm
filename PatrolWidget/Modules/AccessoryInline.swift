import DomainTypes
import SwiftUI
import WidgetKit

struct AccessoryInline: View {
    var entry: SurfEntry

    var body: some View {
        Text("\(entry.wave.middle.feet()) @ \(entry.wave.period.seconds())")
    }
}

#if DEBUG
#Preview("Inline", as: .accessoryInline) {
    PreviewWidget { AccessoryInline(entry: $0) }
} timeline: {
    SurfEntry.typical
    SurfEntry.longPlaceName
    SurfEntry.noGust
    SurfEntry.highSurf
}
#endif
