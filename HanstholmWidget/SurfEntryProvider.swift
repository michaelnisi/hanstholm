//
//  SurfEntryProvider.swift
//  HanstholmWidgetExtension
//
//  Created by Michael Nisi on 28.04.24.
//

import WidgetKit
import SwiftUI
import Hyde
import DomainTypes
import Cache
import MockData

struct SurfEntryProvider: TimelineProvider {
    private let cache = Cache()

    func placeholder(in context: Context) -> SurfEntry {
        MockData.SurfEntry.makeSurfEntry()
    }

    func getSnapshot(in context: Context, completion: @escaping @Sendable (SurfEntry) -> ()) {
        _ = Task {
            let place = await cache.place()
            let entry = (try? await cache.conditions(matching: place, newer: .distantPast))
                ?? MockData.SurfEntry.makeSurfEntry(status: .error)

            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping @Sendable  (Timeline<SurfEntry>) -> ()) {
        Task {
            let placeName = await cache.place()
            let place = Hyde.Place(name: placeName) ?? .hanstholm

            await Hyde.backgroundFetch(place: place)

            let entry = await getEntry(place: place)

            if let entry {
                try? await cache.setConditions(entry)
            }

            let entries = [entry ?? MockData.SurfEntry.makeSurfEntry(status: .error)]
            let timeline = Timeline(entries: entries, policy: .after(.now.addingTimeInterval(SurfEntry.cacheTTL)))

            completion(timeline)
        }
    }
}

extension SurfEntryProvider {
    private func getEntry(place: Hyde.Place) async -> SurfEntry? {
        let date: Date = .now.addingTimeInterval(-SurfEntry.cacheTTL)

        if let cached = try? await cache.conditions(matching: place.name, newer: date) {
            return cached
        }

        if let background = await Hyde.backgroundResult(place: place) {
            return SurfEntry(dto: background)
        }

        let fetched = try? await Hyde.fetch(place: place)
        return SurfEntry(dto: fetched)
    }
}
