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
    struct Dependencies {
        var fetchHyde: () async throws -> Hyde
    }
    
    private let dependencies: Dependencies
    
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
}

extension SurfProvider {
    func fetch() async throws -> SurfEntry? {
        .init(dto: try await dependencies.fetchHyde())
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
                        logger.debug("cached: \(cached.date.ISO8601Format())")
                        
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
