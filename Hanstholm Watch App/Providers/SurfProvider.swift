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
        var cachedEntry: @Sendable () async -> SurfEntry?
        var fetchEntry: @Sendable () async throws -> SurfEntry
    }

    private let dependencies: Dependencies

    nonisolated init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
}

extension SurfProvider {
    func load() async {
        if let stale = await dependencies.cachedEntry() {
            surfEntry = stale
        }

        do {
            surfEntry = try await dependencies.fetchEntry()
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
                cachedEntry: {
                    let place = await cache.place()
                    return try? await cache.conditions(matching: place)
                },
                fetchEntry: {
                    let placeName = await cache.place()
                    let cutoff = Date.now.addingTimeInterval(-5 * 60)

                    if let fresh = try? await cache.conditions(matching: placeName, newer: cutoff) {
                        return fresh
                    }

                    let place = Hyde.Place(name: placeName) ?? .hanstholm
                    let fetched = try await Hyde.fetch(place: place)

                    guard let entry = SurfEntry(dto: fetched) else {
                        throw Hyde.Fault.parsing
                    }

                    try? await cache.setConditions(entry)
                    WidgetCenter.shared.reloadAllTimelines()
                    return entry
                }
            )
        )
    }()
}

extension SurfProvider {
    nonisolated static let mock: SurfProvider = {
        .init(
            dependencies: .init(
                cachedEntry: { nil },
                fetchEntry: {
                    try await Task.sleep(nanoseconds: 500_000_000)
                    return MockData.SurfEntry.makeSurfEntry()
                }
            )
        )
    }()
}
