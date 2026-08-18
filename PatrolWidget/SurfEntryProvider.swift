import WidgetKit
import SwiftUI
import DomainTypes
import Conditions
import MockData

struct SurfEntryProvider: TimelineProvider {
    private let coordinator = ConditionsCoordinator.widget

    func placeholder(in context: Context) -> SurfEntry {
        MockData.SurfEntry.makeSurfEntry()
    }

    func getSnapshot(in context: Context, completion: @escaping @Sendable (SurfEntry) -> ()) {
        _ = Task {
            let entry = await coordinator.cached()
                ?? MockData.SurfEntry.makeSurfEntry(status: .error)

            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping @Sendable  (Timeline<SurfEntry>) -> ()) {
        Task {
            await coordinator.scheduleDeferredRefresh(after: SurfEntry.cacheTTL)

            let entry = (try? await coordinator.conditions(
                policy: .cached(maxAge: SurfEntry.cacheTTL),
                trigger: .widgetTimeline
            )) ?? MockData.SurfEntry.makeSurfEntry(status: .error)

            let timeline = Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(SurfEntry.cacheTTL)))

            completion(timeline)
        }
    }
}
