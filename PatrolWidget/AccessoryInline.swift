import DomainTypes
import SwiftUI
import WidgetKit

struct AccessoryInline: View {
    var entry: SurfEntry

    var body: some View {
        Text("\(entry.wave.middle.feet()) @ \(entry.wave.period.seconds())")
    }
}

#Preview("Wave and period", as: .accessoryInline) {
    PatrolWidget()
} timeline: {
    SurfEntry.typical
    SurfEntry.highSurf
}
