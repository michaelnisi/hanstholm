//
//  SurfConditionsProvider.swift
//  Hanstholm Watch App
//
//  Created by Michael Nisi on 11.05.24.
//

import Observation
import Hyde
import MockData
import DomainTypes
import Cache
import WidgetKit

@Observable final class SurfProvider {
    struct Dependencies: Sendable {
        var fetchHyde: @Sendable () async throws -> Hyde
    }

    private let dependencies: Dependencies

    nonisolated init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
}

extension SurfProvider {
    func fetch() async throws -> SurfEntry? {
        .init(dto: try await dependencies.fetchHyde())
    }
}

extension SurfProvider {
    nonisolated static let live: SurfProvider = {
        let cache = Cache()
        
        return .init(
            dependencies: .init(
                fetchHyde: {
                    let place = await cache.place()
                    let conditions: Hyde
                    let date: Date = .now.addingTimeInterval(-5 * 60)
                    let cached = try? await cache.conditions(matching: place, newer: date)
                    
                    if let cached {
                        logger.debug("cached: \(cached.date.ISO8601Format())")
                        
                        conditions = cached
                    } else {
                        conditions = try await Hyde.fetch(place: place)
                        
                        try await cache.setConditions(conditions)
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                    
                    return conditions
                }
            )
        )
    }()
}

extension SurfProvider {
    nonisolated static let mock: SurfProvider = {
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
