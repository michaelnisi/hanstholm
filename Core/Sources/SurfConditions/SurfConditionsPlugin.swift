//
//  SurfConditionsPlugin.swift
//
//
//  Created by Michael Nisi on 29.07.26.
//

import Foundation
import DomainTypes

/// A source of surf conditions.
///
/// A plugin has exactly two responsibilities: **HTTP** — issuing its own requests, with a
/// session it is handed — and **parsing** — turning the response bytes into a `SurfEntry`.
///
/// Everything else belongs to the coordinator: caching, freshness policy, place selection,
/// background download scheduling and delivery, and widget timeline reloads.
public protocol SurfConditionsPlugin: Sendable {
    /// Stable, reverse-DNS identifier. This is persisted — in background download tokens
    /// and in every `Place` this plugin vends — so changing it orphans both.
    var id: String { get }

    /// Every place this plugin can report on. Each one must carry this plugin's `id`.
    var places: [Place] { get }

    /// Fetches and parses conditions for `place`.
    ///
    /// The session is supplied by the coordinator; the plugin neither owns nor configures
    /// it. Declared `async` rather than isolated so a conformance is free to hop to
    /// whatever isolation its parser needs.
    ///
    /// The returned entry must carry the same place it was asked about — the coordinator
    /// checks, because otherwise the write-through would file it under a key nothing reads.
    func conditions(for place: Place, using session: URLSession) async throws -> SurfEntry
}

extension SurfConditionsPlugin {
    /// Exact, not a name lookup: two plugins covering the same spot stay distinct.
    public func owns(_ place: Place) -> Bool {
        place.pluginID == id
    }
}

public enum SurfConditionsFault: Error, Equatable, Sendable {
    case unknownPlace(String)
    case noPluginForPlace(String)
    case noPlaceSelected
    case noCachedConditions(String)
    case placeMismatch(expected: String, actual: String)
    case unexpectedMediaType(String?)
    case decoding
}
