import Foundation
import os.log
import Cache
import DomainTypes
import ConditionsPlugin

let logger = Logger(subsystem: "ink.codes.Patrol", category: "Conditions")

public enum FreshnessPolicy: Sendable, Equatable {
    case cachedOnly
    case cached(maxAge: TimeInterval)
    case reload
}

public enum Trigger: Sendable, Equatable {
    case userInterface
    case appBackgroundRefresh
    case widgetTimeline
    case deferredDownload
}

public actor ConditionsCoordinator {
    public struct Configuration: Sendable {
        public var cache: Cache
        public var session: URLSession
        public var deferredDownloads: DeferredDownloadConfiguration?
        public var reloadWidgetTimelines: @Sendable () -> Void
        public var now: @Sendable () -> Date

        let registry: PlaceRegistry

        public init(
            plugins: [any ConditionsPlugin],
            cache: Cache = Cache(),
            session: URLSession = .conditionsDefault,
            deferredDownloads: DeferredDownloadConfiguration? = nil,
            reloadWidgetTimelines: @escaping @Sendable () -> Void = {},
            now: @escaping @Sendable () -> Date = { .now }
        ) {
            self.registry = PlaceRegistry(plugins: plugins, cache: cache)
            self.cache = cache
            self.session = session
            self.deferredDownloads = deferredDownloads
            self.reloadWidgetTimelines = reloadWidgetTimelines
            self.now = now
        }
    }

    private let configuration: Configuration

    nonisolated let downloader: DeferredDownloader?

    private var inFlight: [PlaceID: Task<SurfEntry, Error>] = [:]

    public init(configuration: Configuration) {
        self.configuration = configuration
        self.downloader = configuration.deferredDownloads.map(DeferredDownloader.init(configuration:))

        let plugins = configuration.registry.plugins
        let cache = configuration.cache
        let reloadWidgetTimelines = configuration.reloadWidgetTimelines

        self.downloader?.setIngest { data, mimeType, token in
            await ConditionsCoordinator.ingest(
                data: data,
                mimeType: mimeType,
                token: token,
                plugins: plugins,
                cache: cache,
                reloadWidgetTimelines: reloadWidgetTimelines
            )
        }
    }
}

extension ConditionsCoordinator {
    public func selectedPlace() async throws -> Place {
        try await configuration.registry.selectedPlace()
    }
}

extension ConditionsCoordinator {
    public func cached() async -> SurfEntry? {
        await configuration.cache.selectedConditions()
    }

    public func availablePlaces() -> [Place] {
        configuration.registry.availablePlaces()
    }

    public func selectedRegion() async -> GeoRegion? {
        await configuration.registry.selectedRegion()
    }

    public func selectPlace(_ place: Place) async {
        await configuration.registry.selectPlace(place)
    }

    public func includedPlaces() async -> [Place] {
        await configuration.registry.includedPlaces()
    }

    public func setIncludedPlaceIDs(_ ids: [PlaceID]) async {
        let selectionChanged = await configuration.registry.setIncludedPlaceIDs(ids)

        if selectionChanged {
            configuration.reloadWidgetTimelines()
        }
    }

    public func conditions(policy: FreshnessPolicy, trigger: Trigger) async throws -> SurfEntry {
        let place = try await selectedPlace()

        switch policy {
        case .cachedOnly:
            guard let entry = await configuration.cache.conditions(matching: place) else {
                throw ConditionsFault.noCachedConditions(place.id)
            }

            return entry

        case .cached(let maxAge):
            let cutoff = configuration.now().addingTimeInterval(-maxAge)

            if let fresh = await configuration.cache.conditions(matching: place, newer: cutoff) {
                return fresh
            }

            return try await fetch(place: place, trigger: trigger)

        case .reload:
            return try await fetch(place: place, trigger: trigger)
        }
    }

    private func fetch(place: Place, trigger: Trigger) async throws -> SurfEntry {
        if let existing = inFlight[place.id] {
            return try await existing.value
        }

        guard let plugin = configuration.registry.plugin(for: place) else {
            throw ConditionsFault.noPluginForPlace(place.id)
        }

        let session = configuration.session
        let cache = configuration.cache

        let task = Task<SurfEntry, Error> {
            let entry = try await plugin.conditions(for: place, using: session)

            guard entry.place.id == place.id else {
                throw ConditionsFault.placeMismatch(expected: place.id, actual: entry.place.id)
            }

            await cache.setConditions(entry)

            return entry
        }

        inFlight[place.id] = task

        defer {
            inFlight[place.id] = nil
        }

        let entry = try await task.value

        reloadTimelines(for: trigger)

        return entry
    }

    private func reloadTimelines(for trigger: Trigger) {
        guard trigger != .widgetTimeline else {
            return
        }

        configuration.reloadWidgetTimelines()
    }
}

extension ConditionsCoordinator {
    public func scheduleDeferredRefresh(after delay: TimeInterval) async {
        guard let downloader else {
            return
        }

        await LegacySessionCleanup.flushIfNeeded()

        do {
            let place = try await selectedPlace()

            guard let plugin = Self.deferredPlugin(for: place, in: configuration.registry.plugins) else {
                return
            }

            downloader.schedule(
                try plugin.deferredRequest(for: place),
                token: .init(place: place),
                after: delay
            )
        } catch {
            logger.error("scheduling deferred refresh failed: \(error)")
        }
    }

    public nonisolated func handleBackgroundSessionEvents(
        completion: @escaping @Sendable @MainActor () -> Void
    ) {
        guard let downloader else {
            Task { @MainActor in
                completion()
            }

            return
        }

        downloader.adopt(completion: completion)
    }

    static func ingest(
        data: Data,
        mimeType: String?,
        token: DeferredDownloader.Token?,
        plugins: [any ConditionsPlugin],
        cache: Cache,
        reloadWidgetTimelines: @Sendable () -> Void
    ) async {
        let selected = await cache.selectedPlaceID()

        guard let place = token?.place else {
            logger.error("deferred ingest: missing token")
            return
        }

        if let selected, place.id != selected {
            logger.error("deferred ingest: dropping \(place.id), selected is \(selected)")
            return
        }

        guard let plugin = deferredPlugin(for: place, in: plugins) else {
            logger.error("deferred ingest: no plugin for \(place.id)")
            return
        }

        do {
            let entry = try await plugin.decodeDeferred(data, mimeType: mimeType, for: place)

            guard entry.place.id == place.id else {
                throw ConditionsFault.placeMismatch(expected: place.id, actual: entry.place.id)
            }

            guard await cache.setConditions(entry) else {
                logger.error("deferred ingest failed: could not persist entry for \(place.id)")
                return
            }

            reloadWidgetTimelines()
        } catch {
            logger.error("deferred ingest failed: \(error)")
        }
    }

    func ingest(data: Data, mimeType: String?, token: DeferredDownloader.Token?) async {
        await Self.ingest(
            data: data,
            mimeType: mimeType,
            token: token,
            plugins: configuration.registry.plugins,
            cache: configuration.cache,
            reloadWidgetTimelines: configuration.reloadWidgetTimelines
        )
    }

    private static func deferredPlugin(
        for place: Place,
        in plugins: [any ConditionsPlugin]
    ) -> (any DeferredDownloadable)? {
        plugins
            .compactMap { $0 as? any DeferredDownloadable }
            .first { $0.owns(place) }
    }
}
