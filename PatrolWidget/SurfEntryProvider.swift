import Conditions
import DomainTypes
import Hyde
import SwiftUI
import WidgetKit

struct SurfEntryProvider: TimelineProvider {
    private let coordinator = ConditionsCoordinator.widget

    func placeholder(in context: Context) -> SurfEntry {
        .fallback()
    }

    func getSnapshot(in context: Context, completion: @escaping @Sendable (SurfEntry) -> Void) {
        if context.isPreview {
            completion(.fallback())
            return
        }

        _ = Task {
            let cached = await coordinator.cached()
            let entry: SurfEntry

            if let cached {
                entry = cached
            } else {
                entry = await noDataEntry()
            }

            completion(entry)
        }
    }

    func getTimeline(
        in context: Context, completion: @escaping @Sendable (Timeline<SurfEntry>) -> Void
    ) {
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
                entry = await noDataEntry()
            }

            let timeline = Timeline(
                entries: [entry], policy: .after(.now.addingTimeInterval(SurfEntry.cacheTTL)))

            completion(timeline)
        }
    }
}

extension SurfEntryProvider {
    fileprivate func noDataEntry() async -> SurfEntry {
        let selected = try? await coordinator.selectedPlace()

        return .fallback(place: selected ?? Hyde.Station.hanstholm.place, status: .error)
    }
}

extension SurfEntry {
    fileprivate static func fallback(
        place: Place = Hyde.Station.hanstholm.place,
        status: Status = .placeholder
    ) -> SurfEntry {
        SurfEntry(
            date: .now,
            place: place,
            status: status,
            wave: Wave(max: 2.0, middle: 1.2, period: 8, direction: .init(cardinal: .northWest)),
            wind: Wind(
                speed: .init(gust: 10, middle: 7, current: 5),
                direction: .init(cardinal: .southWest))
        )
    }
}

extension SurfEntryProvider {
    func relevance() async -> WidgetRelevance<Void> {
        guard let region = await coordinator.selectedRegion() else {
            return WidgetRelevance([])
        }

        return WidgetRelevance([WidgetRelevanceAttribute<Void>(context: .location(region.clRegion))]
        )
    }
}
