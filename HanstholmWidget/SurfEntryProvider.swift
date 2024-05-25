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

struct SurfEntryProvider: TimelineProvider {
    private let cache = Cache()
    
    func placeholder(in context: Context) -> SurfEntry {
        .init(name: "Hanstholm")
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SurfEntry) -> ()) {
        Task {
            let hyde = try await getHyde()
            let entry = SurfEntry(dto: hyde)
            
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SurfEntry>) -> ()) {
        Hyde.backgroundFetch()
        
        Task {
            let hyde = try await getHyde()
            let entry = SurfEntry(dto: hyde)
            let entries = [entry]
            let timeline = Timeline(entries: entries, policy: .never)
            
            completion(timeline)
        }
    }
}

extension SurfEntryProvider {
    private func getHyde() async throws -> Hyde? {
        let conditions: Hyde?
        let place: Hyde.Place = .hanstholm
        let date: Date = .now.addingTimeInterval(-15 * 60)
        let cached = try cache.cachedConditions(matching: place, newer: date)
        let background = Hyde.backgroundResult()

        if let cached {
            conditions = cached
        } else if let background {
            conditions = background
        } else {
            conditions = try? await Hyde.fetch()
        }
        
        return conditions
    }
}

