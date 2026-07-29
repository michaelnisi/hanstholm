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

    private var inFlight: [String: Task<SurfEntry, Error>] = [:]

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

// MARK: - Reading conditions

extension ConditionsCoordinator {
    /// Whatever is cached for the selected place, at any age. Never fetches.
    public func cached() async -> SurfEntry? {
        let place = await configuration.cache.place()

        return try? await configuration.cache.conditions(matching: place)
    }

    public func conditions(policy: FreshnessPolicy, trigger: Trigger) async throws -> SurfEntry {
        let place = await configuration.cache.place()

        switch policy {
        case .cachedOnly:
            guard let entry = try? await configuration.cache.conditions(matching: place) else {
                throw SurfConditionsFault.noCachedConditions(place)
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
    private func fetch(place: String, trigger: Trigger) async throws -> SurfEntry {
        if let existing = inFlight[place] {
            return try await existing.value
        }

        guard let plugin = configuration.plugins.first(where: { $0.owns(place) }) else {
            throw SurfConditionsFault.noPluginForPlace(place)
        }

        let session = configuration.session
        let cache = configuration.cache

        let task = Task<SurfEntry, Error> {
            let entry = try await plugin.conditions(for: place, using: session)

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

        let place = await configuration.cache.place()

        guard let plugin = Self.deferredPlugin(id: nil, place: place, in: configuration.plugins) else {
            return
        }

        do {
            let request = try plugin.deferredRequest(for: place)

            downloader.schedule(
                request,
                token: .init(pluginID: plugin.id, place: place),
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
        let selected = await cache.place()

        if let token, token.place != selected {
            // Scheduled before the selected place changed; writing it would file one
            // spot's conditions under another's key.
            logger.error("deferred ingest: dropping \(token.place), selected is \(selected)")
            return
        }

        let place = token?.place ?? selected

        guard let plugin = deferredPlugin(id: token?.pluginID, place: place, in: plugins) else {
            logger.error("deferred ingest: no plugin for \(place)")
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
        id: String?,
        place: String,
        in plugins: [any SurfConditionsPlugin]
    ) -> (any DeferredDownloadable)? {
        let deferred = plugins.compactMap { $0 as? any DeferredDownloadable }

        guard let id else {
            return deferred.first { $0.owns(place) }
        }

        // An unknown id means the plugin was removed in an update: drop the payload
        // rather than guessing which source these bytes came from.
        return deferred.first { $0.id == id }
    }
}
