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
        Task {
            let conditions = try await cache.conditions(matching: cache.place(), newer: .distantPast)
            let entry = SurfEntry(dto: conditions) ?? MockData.SurfEntry.makeSurfEntry()
            
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping @Sendable  (Timeline<SurfEntry>) -> ()) {
        Task {
            await Hyde.backgroundFetch(place: cache.place())
            
            let hyde = try await getHyde()
            
            if let hyde {
                try await cache.setConditions(hyde)
            }
            
            let entry = SurfEntry(dto: hyde) ?? MockData.SurfEntry.makeSurfEntry()
         
            let entries = [entry]
            let timeline = Timeline(entries: entries, policy: .never)
            
            completion(timeline)
        }
    }
}

extension SurfEntryProvider {
    private func getHyde() async throws -> Hyde? {
        let conditions: Hyde?
        let place = await cache.place()
        let date: Date = .now.addingTimeInterval(-15 * 60)
        let cached = try await cache.conditions(matching: place, newer: date)
        let background = await Hyde.backgroundResult(place: place)

        if let cached {
            conditions = cached
        } else if let background {
            conditions = background
        } else {
            conditions = try? await Hyde.fetch(place: place)
        }
        
        return conditions
    }
}

