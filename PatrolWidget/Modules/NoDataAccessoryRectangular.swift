import DomainTypes
import SwiftUI
import WidgetKit

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

#if DEBUG
#Preview("No Data", as: .accessoryRectangular) {
    PreviewWidget { NoDataAccessoryRectangular(entry: $0) }
} timeline: {
    SurfEntry.noData
}
#endif
