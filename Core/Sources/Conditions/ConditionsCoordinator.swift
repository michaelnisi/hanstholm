import Foundation
import os.log
import Cache
import DomainTypes
import SurfConditions

let logger = Logger(subsystem: "ink.codes.Hanstholm", category: "Conditions")

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
        public var plugins: [any SurfConditionsPlugin]
        public var cache: Cache
        public var session: URLSession
        public var deferredDownloads: DeferredDownloadConfiguration?
        public var reloadWidgetTimelines: @Sendable () -> Void
        public var now: @Sendable () -> Date

        public init(
            plugins: [any SurfConditionsPlugin],
            cache: Cache = Cache(),
            session: URLSession = .conditionsDefault,
            deferredDownloads: DeferredDownloadConfiguration? = nil,
            reloadWidgetTimelines: @escaping @Sendable () -> Void = {},
            now: @escaping @Sendable () -> Date = { .now }
        ) {
            self.plugins = plugins
            self.cache = cache
            self.session = session
            self.deferredDownloads = deferredDownloads
            self.reloadWidgetTimelines = reloadWidgetTimelines
            self.now = now
        }
    }

    private let configuration: Configuration

    nonisolated let downloader: DeferredDownloader?

    private var inFlight: [Place: Task<SurfEntry, Error>] = [:]

    public init(configuration: Configuration) {
        self.configuration = configuration
        self.downloader = configuration.deferredDownloads.map(DeferredDownloader.init(configuration:))

        let plugins = configuration.plugins
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
    func selectedPlace() async throws -> Place {
        let all = configuration.plugins.flatMap(\.places)

        guard let id = await configuration.cache.selectedPlaceID() else {
            guard let first = all.first else {
                throw SurfConditionsFault.noPlaceSelected
            }

            return first
        }

        guard let place = all.first(where: { $0.id == id }) else {
            throw SurfConditionsFault.noPluginForPlace(id)
        }

        return place
    }
}

extension ConditionsCoordinator {
    public func cached() async -> SurfEntry? {
        try? await configuration.cache.selectedConditions()
    }

    public func conditions(policy: FreshnessPolicy, trigger: Trigger) async throws -> SurfEntry {
        let place = try await selectedPlace()

        switch policy {
        case .cachedOnly:
            guard let entry = try? await configuration.cache.conditions(matching: place) else {
                throw SurfConditionsFault.noCachedConditions(place.id)
            }

            return entry

        case .cached(let maxAge):
            let cutoff = configuration.now().addingTimeInterval(-maxAge)

            if let fresh = try? await configuration.cache.conditions(matching: place, newer: cutoff) {
                return fresh
            }

            return try await fetch(place: place, trigger: trigger)

        case .reload:
            return try await fetch(place: place, trigger: trigger)
        }
    }

    private func fetch(place: Place, trigger: Trigger) async throws -> SurfEntry {
        if let existing = inFlight[place] {
            return try await existing.value
        }

        guard let plugin = configuration.plugins.first(where: { $0.owns(place) }) else {
            throw SurfConditionsFault.noPluginForPlace(place.id)
        }

        let session = configuration.session
        let cache = configuration.cache

        let task = Task<SurfEntry, Error> {
            let entry = try await plugin.conditions(for: place, using: session)

            guard entry.place == place else {
                throw SurfConditionsFault.placeMismatch(expected: place.id, actual: entry.place.id)
            }

            try? await cache.setConditions(entry)

            return entry
        }

        inFlight[place] = task

        defer {
            inFlight[place] = nil
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

            guard let plugin = Self.deferredPlugin(for: place, in: configuration.plugins) else {
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
        plugins: [any SurfConditionsPlugin],
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

            guard entry.place == place else {
                throw SurfConditionsFault.placeMismatch(expected: place.id, actual: entry.place.id)
            }

            try await cache.setConditions(entry)

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
            plugins: configuration.plugins,
            cache: configuration.cache,
            reloadWidgetTimelines: configuration.reloadWidgetTimelines
        )
    }

    private static func deferredPlugin(
        for place: Place,
        in plugins: [any SurfConditionsPlugin]
    ) -> (any DeferredDownloadable)? {
        plugins
            .compactMap { $0 as? any DeferredDownloadable }
            .first { $0.owns(place) }
    }
}
