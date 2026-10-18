import Conditions
import DomainTypes
import Hyde
import SwiftUI
import WidgetKit

struct SurfEntryProvider: AppIntentTimelineProvider {
    private let coordinator = ConditionsCoordinator.shared

    func placeholder(in context: Context) -> SurfEntry {
        .fallback()
    }

    func snapshot(for configuration: SurfPlaceConfigurationIntent, in context: Context) async
        -> SurfEntry
    {
        if context.isPreview {
            return .fallback()
        }

        guard let place = await resolvedPlace(for: configuration) else {
            return .fallback(status: .error)
        }

        return await coordinator.cached(for: place) ?? .fallback(place: place, status: .error)
    }

    func timeline(for configuration: SurfPlaceConfigurationIntent, in context: Context) async
        -> Timeline<SurfEntry>
    {
        let reloadPolicy = TimelineReloadPolicy.after(.now.addingTimeInterval(SurfEntry.cacheTTL))

        guard let place = await resolvedPlace(for: configuration) else {
            return Timeline(entries: [.fallback(status: .error)], policy: reloadPolicy)
        }

        await coordinator.scheduleDeferredRefresh(for: place, after: SurfEntry.cacheTTL)

        let entry: SurfEntry

        if let fetched = try? await coordinator.conditions(
            for: place,
            policy: .cached(maxAge: SurfEntry.cacheTTL),
            trigger: .widgetTimeline
        ) {
            entry = fetched
        } else if let cached = await coordinator.cached(for: place) {
            entry = cached
        } else {
            entry = .fallback(place: place, status: .error)
        }

        return Timeline(entries: [entry], policy: reloadPolicy)
    }

    func recommendations() -> [AppIntentRecommendation<SurfPlaceConfigurationIntent>] {
        coordinator.availablePlaces().map { place in
            AppIntentRecommendation(
                intent: SurfPlaceConfigurationIntent(place: PlaceEntity(place: place)),
                description: place.name
            )
        }
    }

    func relevance() async -> WidgetRelevance<SurfPlaceConfigurationIntent> {
        let places = await coordinator.includedPlaces()

        let attributes = places.compactMap { place in
            coordinator.region(for: place).map { region in
                WidgetRelevanceAttribute(
                    configuration: SurfPlaceConfigurationIntent(place: PlaceEntity(place: place)),
                    context: .location(region.clRegion)
                )
            }
        }

        return WidgetRelevance(attributes)
    }
}

extension SurfEntryProvider {
    fileprivate func resolvedPlace(for configuration: SurfPlaceConfigurationIntent) async -> Place?
    {
        if let configured = configuration.place?.place {
            return configured
        }

        return try? await coordinator.selectedPlace()
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
