import WidgetKit
import SwiftUI
import DomainTypes
import Conditions
import Hyde

struct SurfEntryProvider: TimelineProvider {
    private let coordinator = ConditionsCoordinator.widget

    func placeholder(in context: Context) -> SurfEntry {
        .fallback()
    }

    func getSnapshot(in context: Context, completion: @escaping @Sendable (SurfEntry) -> ()) {
        _ = Task {
            let entry = await coordinator.cached()
                ?? .fallback(status: .error)

            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping @Sendable  (Timeline<SurfEntry>) -> ()) {
        Task {
            await coordinator.scheduleDeferredRefresh(after: SurfEntry.cacheTTL)

            let entry: SurfEntry

            if let fetched = try? await coordinator.conditions(
                policy: .cached(maxAge: SurfEntry.cacheTTL),
                trigger: .widgetTimeline
            ) {
                entry = fetched
            } else if let cached = await coordinator.cached() {
                entry = cached
            } else {
                entry = .fallback(status: .error)
            }

            let timeline = Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(SurfEntry.cacheTTL)))

            completion(timeline)
        }
    }
}

extension SurfEntry {
    fileprivate static func fallback(status: Status = .initial) -> SurfEntry {
        SurfEntry(
            date: .now,
            place: Hyde.Station.hanstholm.place,
            status: status,
            wave: Wave(max: 2.0, middle: 1.2, period: 8, direction: .init(cardinal: .northWest)),
            wind: Wind(speed: .init(gust: 10, middle: 7, current: 5), direction: .init(cardinal: .southWest))
        )
    }
}

extension SurfEntryProvider {
    func relevance() async -> WidgetRelevance<Void> {
        guard let region = await coordinator.selectedRegion() else {
            return WidgetRelevance([])
        }

        return WidgetRelevance([WidgetRelevanceAttribute<Void>(context: .location(region.clRegion))])
    }
}
