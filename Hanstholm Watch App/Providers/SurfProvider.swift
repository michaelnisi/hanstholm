//
//  SurfConditionsProvider.swift
//  Hanstholm Watch App
//
//  Created by Michael Nisi on 11.05.24.
//

import Foundation
import Hyde
import MockData
import DomainTypes
import Cache
import WidgetKit

@MainActor final class SurfProvider: ObservableObject {
    @Published var entries = Hyde.Place.allCases.map(\.name).map(SurfEntry.init)
    @Published var selected: SurfEntry?
    
    struct Dependencies {
        var fetchHyde: () async throws -> Hyde
    }
    
    private let dependencies: Dependencies
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
}

extension SurfProvider {
    func update() async throws {
        let hyde = try await dependencies.fetchHyde()
        let new = SurfEntry(dto: hyde)
        var acc = [SurfEntry]()
        for entry in entries {
            acc.append(new.name == entry.name ? new : entry)
        }
        
        entries = acc
        selected = new
    }
}

extension SurfProvider {
    static var live: SurfProvider = {
        let cache = Cache()
        
        return .init(
            dependencies: .init(
                fetchHyde: {
                    let place: Hyde.Place = .hanstholm
                    let conditions: Hyde
                    let date: Date = .now.addingTimeInterval(-5 * 60)
                    let cached = try cache.cachedConditions(matching: place, newer: date)
                    
                    if let cached {
                        conditions = cached
                    } else {
                        conditions = try await Hyde.fetch()
                        
                        try cache.cacheConditions(conditions)
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                        
                    return conditions
                }
            )
        )
    }()
}

extension SurfProvider {
    static var mock: SurfProvider = {
        .init(
            dependencies: .init(
                fetchHyde: {
                    try await Task.sleep(nanoseconds: 500_000_000)
                    
                    return MockData.HydeAPI.makeHyde()
                }
            )
        )
    }()
}
