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
    var surfEntry: SurfEntry?

    struct Dependencies: Sendable {
        var cachedHyde: @Sendable () async -> Hyde?
        var fetchHyde: @Sendable () async throws -> Hyde
    }

    private let dependencies: Dependencies

    nonisolated init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
}

extension SurfProvider {
    func load() async {
        if let stale = await dependencies.cachedHyde() {
            surfEntry = .init(dto: stale)
        }

        do {
            let fresh = try await dependencies.fetchHyde()
            surfEntry = .init(dto: fresh)
        } catch {
            logger.error("fetch failed: \(error)")
        }
    }
}

extension SurfProvider {
    nonisolated static let live: SurfProvider = {
        let cache = Cache()

        return .init(
            dependencies: .init(
                cachedHyde: {
                    let place = await cache.place()
                    return try? await cache.conditions(matching: place)
                },
                fetchHyde: {
                    let place = await cache.place()
                    let cutoff = Date.now.addingTimeInterval(-5 * 60)

                    if let fresh = try? await cache.conditions(matching: place, newer: cutoff) {
                        return fresh
                    }

                    let fetched = try await Hyde.fetch(place: place)
                    try? await cache.setConditions(fetched)
                    WidgetCenter.shared.reloadAllTimelines()
                    return fetched
                }
            )
        )
    }()
}

extension SurfProvider {
    nonisolated static let mock: SurfProvider = {
        .init(
            dependencies: .init(
                cachedHyde: { nil },
                fetchHyde: {
                    try await Task.sleep(nanoseconds: 500_000_000)
                    return MockData.HydeAPI.makeHyde()
                }
            )
        )
    }()
}
