#if !os(watchOS)
import DomainTypes
import SwiftUI
import WidgetKit

struct HomeFooter: View {
    var entry: SurfEntry

    var body: some View {
        Text("\(entry.place.name), \(entry.date.formatted(date: .omitted, time: .shortened))")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}

#Preview("Footer", as: .systemMedium) {
    PatrolWidget()
} timeline: {
    SurfEntry.typical
    SurfEntry.longPlaceName
}
#endif
