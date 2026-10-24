#if !os(watchOS)
import DomainTypes
import SwiftUI
import WidgetKit

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

#if DEBUG
#Preview("No Data", as: .systemSmall) {
    PreviewWidget { NoDataHomeTile(entry: $0) }
} timeline: {
    SurfEntry.noData
}
#endif
#endif
