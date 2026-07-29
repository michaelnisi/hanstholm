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
    /// Stable, reverse-DNS identifier. This is persisted in background download tokens,
    /// so changing it orphans downloads scheduled by a previously installed build.
    var id: String { get }

    /// Places this plugin can report conditions for.
    var places: [String] { get }

    /// Fetches and parses conditions for `place`.
    ///
    /// The session is supplied by the coordinator; the plugin neither owns nor configures
    /// it. Declared `async` rather than isolated so a conformance is free to hop to
    /// whatever isolation its parser needs.
    func conditions(for place: String, using session: URLSession) async throws -> SurfEntry
}

extension SurfConditionsPlugin {
    public func owns(_ place: String) -> Bool {
        places.contains(place)
    }
}

public enum SurfConditionsFault: Error, Equatable, Sendable {
    case unknownPlace(String)
    case noPluginForPlace(String)
    case noCachedConditions(String)
    case unexpectedMediaType(String?)
    case decoding
}
