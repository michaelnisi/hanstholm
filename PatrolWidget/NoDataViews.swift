import DomainTypes
import SwiftUI
import WidgetKit

#if !os(watchOS)
struct NoDataHomeTile: View {
    var entry: SurfEntry

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title2)
            Text("No Data")
                .font(.caption)
            Text(entry.place.name)
                .font(.caption2)
        }
        .foregroundStyle(.secondary)
    }
}

#Preview("No Data Tile", as: .systemSmall) {
    PatrolWidget()
} timeline: {
    SurfEntry.noData
}
#endif

struct NoDataAccessoryRectangular: View {
    var entry: SurfEntry

    var body: some View {
        VStack(alignment: .leading) {
            Label("No Data", systemImage: "exclamationmark.triangle")

            Text(entry.place.name)
                .font(.caption)
        }
        .widgetAccentable()
    }
}

#Preview("No Data Rectangular", as: .accessoryRectangular) {
    PatrolWidget()
} timeline: {
    SurfEntry.noData
}
