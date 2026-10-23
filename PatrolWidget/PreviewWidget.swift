#if DEBUG
import DomainTypes
import SwiftUI
import WidgetKit

struct PreviewWidget: Widget {
    let kind = "PreviewWidget"
    let content: (SurfEntry) -> AnyView

    init() {
        self.init { PatrolWidgetEntryView(entry: $0) }
    }

    init<Content: View>(@ViewBuilder content: @escaping (SurfEntry) -> Content) {
        self.content = { AnyView(content($0)) }
    }

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PreviewEntryProvider()) { entry in
            PreviewTile {
                content(entry)
            }
        }
    }
}

private struct PreviewTile<Content: View>: View {
    @Environment(\.widgetFamily) private var family

    @ViewBuilder var content: Content

    var body: some View {
        content
            .containerBackground(for: .widget) {
                TileBackground(family: family)
            }
    }
}

private struct PreviewEntryProvider: TimelineProvider {
    func placeholder(in context: Context) -> SurfEntry {
        PreviewState.typical.entry
    }

    func getSnapshot(in context: Context, completion: @escaping (SurfEntry) -> Void) {
        completion(PreviewState.typical.entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SurfEntry>) -> Void) {
        completion(Timeline(entries: [PreviewState.typical.entry], policy: .never))
    }
}
#endif
