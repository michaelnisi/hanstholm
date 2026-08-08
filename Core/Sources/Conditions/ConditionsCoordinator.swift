//
//  ConditionsCoordinator.swift
//
//
//  Created by Michael Nisi on 29.07.26.
//

import Foundation
import os.log
import Cache
import DomainTypes
import SurfConditions

let logger = Logger(subsystem: "ink.codes.Hanstholm", category: "Conditions")

/// How fresh cached conditions have to be before a fetch is worth doing.
public enum FreshnessPolicy: Sendable, Equatable {
    /// Never fetches.
    case cachedOnly
    /// Fetches only if nothing cached is newer than `maxAge`.
    case cached(maxAge: TimeInterval)
    /// Always fetches.
    case reload
}

/// What prompted a request. Only used to decide whether reloading widget timelines is safe.
public enum Trigger: Sendable, Equatable {
    case userInterface
    case appBackgroundRefresh
    case widgetTimeline
    case deferredDownload
}

/// Owns caching, freshness policy, place selection and transport, so plugins don't have to.
///
/// One instance per process. The App Group only shares *storage* between processes, never
/// memory, so nothing here is shared between the watch app and the widget extensions —
/// they meet in the `Cache`.
public actor ConditionsCoordinator {
    public struct Configuration: Sendable {
        public var plugins: [any SurfConditionsPlugin]
        public var cache: Cache

        /// Foreground session handed to plugins.
        public var session: URLSession

        /// `nil` disables deferred downloads in this process, and no background session is
        /// created at all.
        public var deferredDownloads: DeferredDownloadConfiguration?

        public var reloadWidgetTimelines: @Sendable () -> Void

        /// Injected so freshness boundaries are testable without sleeping.
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

    /// `nonisolated` because the WidgetKit events handler reaches it synchronously.
    nonisolated let downloader: DeferredDownloader?

    private var inFlight: [Place: Task<SurfEntry, Error>] = [:]

    public init(configuration: Configuration) {
        self.configuration = configuration
        self.downloader = configuration.deferredDownloads.map(DeferredDownloader.init(configuration:))

        // Hand the ingest closure the pieces it needs rather than `self`: the session
        // retains its delegate for the life of the process, so capturing the coordinator
        // would tie its lifetime to the session's — and escaping `self` from an actor's
        // initializer is its own problem.
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

// MARK: - Resolving the selected place

extension ConditionsCoordinator {
    /// The selected place, or the first installed plugin's first place when nothing has been
    /// chosen yet.
    ///
    /// The default lives here rather than in `Cache` because it depends on what's installed;
    /// storage has no business knowing that a place called "Hanstholm" exists.
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

// MARK: - Reading conditions

extension ConditionsCoordinator {
    /// Whatever is cached for the selected place, at any age. Never fetches.
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

    /// Single-in-flight per place: `ContentView` loads from both `.task` and the
    /// `scenePhase` change, so launch would otherwise fire two identical fetches.
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

            // The cache files an entry under its own place. A plugin that answers about a
            // different one would write somewhere nothing ever reads, so every request
            // would silently re-fetch forever — better to say so.
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

    /// Reloading from inside the widget's own `getTimeline` would loop, so that one trigger
    /// is excluded. Keeping the rule here makes it one testable line instead of a
    /// convention spread across call sites.
    private func reloadTimelines(for trigger: Trigger) {
        guard trigger != .widgetTimeline else {
            return
        }

        configuration.reloadWidgetTimelines()
    }
}

// MARK: - Deferred downloads

extension ConditionsCoordinator {
    /// Asks the system to download conditions in the background, no earlier than `delay`
    /// from now. Does nothing if this process has deferred downloads disabled, or if the
    /// selected place's plugin doesn't support them.
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

    /// Hands WidgetKit's completion handler to the downloader.
    ///
    /// `nonisolated` on purpose: this must complete synchronously, or a download that
    /// already finished finds nothing to call back.
    public nonisolated func handleBackgroundSessionEvents(
        completion: @escaping @Sendable @MainActor () -> Void
    ) {
        guard let downloader else {
            // Never withhold the completion — the system penalises extensions that don't
            // finish their launch events.
            Task { @MainActor in
                completion()
            }

            return
        }

        downloader.adopt(completion: completion)
    }

    /// Writes a finished background download through to the cache.
    ///
    /// This write-through is what lets the widget drop its old middle tier: by the time
    /// anything asks, a completed download is already *in* the cache, so there's no
    /// in-memory result to consult — and nothing to lose when the process is relaunched.
    ///
    /// Static because the downloader calls it without holding the coordinator.
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
            // Scheduled before the selected place changed; writing it would file one
            // spot's conditions under another's key.
            logger.error("deferred ingest: dropping \(place.id), selected is \(selected)")
            return
        }

        guard let plugin = deferredPlugin(for: place, in: plugins) else {
            // The plugin was removed in an update: drop the payload rather than guessing
            // which source these bytes came from.
            logger.error("deferred ingest: no plugin for \(place.id)")
            return
        }

        do {
            let entry = try await plugin.decodeDeferred(data, mimeType: mimeType, for: place)

            try await cache.setConditions(entry)

            reloadWidgetTimelines()
        } catch {
            logger.error("deferred ingest failed: \(error)")
        }
    }

    /// Instance entry point, so tests can drive ingest without a real session.
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
