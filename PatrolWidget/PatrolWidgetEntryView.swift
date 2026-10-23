import DomainTypes
import SwiftUI
import WidgetKit

struct PatrolWidgetEntryView: View {
    @Environment(\.widgetFamily) var widgetFamily
    var entry: SurfEntry

    var body: some View {
        familyView
            .containerBackground(for: .widget) {
                TileBackground(family: widgetFamily)
            }
    }

    @ViewBuilder
    private var familyView: some View {
        switch widgetFamily {
        #if os(watchOS)
        case .accessoryCorner:
            if entry.status == .error {
                ZStack {
                    AccessoryWidgetBackground()
                    Image(systemName: "exclamationmark.triangle")
                }
                .widgetLabel {
                    Text("No Data")
                }
            } else {
                AccessoryCorner(entry: entry)
            }
        #else
        case .systemSmall:
            if entry.status == .error {
                NoDataHomeTile(entry: entry)
            } else {
                HomeSmall(entry: entry)
            }
        case .systemMedium:
            if entry.status == .error {
                NoDataHomeTile(entry: entry)
            } else {
                HomeMedium(entry: entry)
            }
        #endif
        case .accessoryCircular:
            if entry.status == .error {
                ZStack {
                    AccessoryWidgetBackground()
                    Image(systemName: "exclamationmark.triangle")
                }
                .widgetAccentable()
            } else {
                AccessoryCircular(entry: entry)
            }
        case .accessoryInline:
            if entry.status == .error {
                Text("No Data")
            } else {
                AccessoryInline(entry: entry)
            }
        case .accessoryRectangular:
            if entry.status == .error {
                NoDataAccessoryRectangular(entry: entry)
            } else {
                AccessoryRectangular(entry: entry)
            }
        default:
            AccessoryInline(entry: entry)
        }
    }
}

#if DEBUG
#Preview("Every state", as: .accessoryRectangular) {
    PatrolWidget()
} timeline: {
    SurfEntry.typical
    SurfEntry.noData
}

#Preview("Circular", as: .accessoryCircular) {
    PatrolWidget()
} timeline: {
    SurfEntry.typical
    SurfEntry.noData
}

#Preview("Inline", as: .accessoryInline) {
    PatrolWidget()
} timeline: {
    SurfEntry.typical
    SurfEntry.noData
}
#endif
