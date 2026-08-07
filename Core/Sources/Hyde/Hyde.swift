//
//  Hyde.swift
//
//
//  Created by Michael Nisi on 07.04.24.
//

import os.log
import Foundation
import DomainTypes
import SurfConditions

let logger = Logger(subsystem: "ink.codes.Hanstholm", category: "Hyde")

/// The hyde.dk data source: live readings from weather stations on the Danish west coast.
///
/// `Hyde` names a specific source, so this is the plugin itself. What it publishes — the
/// HTML it serves and the `Report` parsed out of it — is an implementation detail behind it.
public struct Hyde: SurfConditionsPlugin, DeferredDownloadable {
    /// Persisted in cache keys and background download tokens. Don't change it casually.
    public static let pluginID = "ink.codes.Hanstholm.plugin.hyde"

    /// A station this source publishes readings for.
    ///
    /// Named `Station` rather than `Place` because a `Place` is the domain-wide idea of a
    /// spot; this is hyde.dk's own notion of one, and only this file should have to know
    /// how the two line up.
    public enum Station: CaseIterable, Equatable, Sendable {
        case hanstholm
    }

    public enum Fault: Error {
        case parsing
        case missing(String)
        case transform(String)
    }

    public var id: String {
        Self.pluginID
    }

    public var places: [Place] {
        Station.allCases.map(\.place)
    }

    public init() {}

    private func station(for place: Place) throws -> Station {
        guard let station = Station(place: place) else {
            throw SurfConditionsFault.unknownPlace(place.id)
        }

        return station
    }
}

// MARK: - HTTP

extension Hyde {
    public func conditions(for place: Place, using session: URLSession) async throws -> SurfEntry {
        let request = try deferredRequest(for: place)
        let (data, response) = try await session.data(for: request)

        return try await decodeDeferred(data, mimeType: response.mimeType, for: place)
    }

    public func deferredRequest(for place: Place) throws -> URLRequest {
        URLRequest(url: try station(for: place).url)
    }
}

// MARK: - Parsing

extension Hyde {
    public func decodeDeferred(
        _ data: Data,
        mimeType: String?,
        for place: Place
    ) async throws -> SurfEntry {
        if let mimeType, mimeType != "text/html" {
            throw SurfConditionsFault.unexpectedMediaType(mimeType)
        }

        let station = try station(for: place)

        // `Parser` strips HTML with the `NSAttributedString` importer, which is
        // main-thread-only. The hop is explicit so a background-session delegate can't drag
        // it onto its own queue.
        return try await MainActor.run {
            let report = try Report(station: station, data: data)

            guard let entry = SurfEntry(report: report, place: place) else {
                throw SurfConditionsFault.decoding
            }

            return entry
        }
    }
}

// MARK: - Stations

extension Hyde.Station {
    /// The place this station reports for.
    ///
    /// A station knows its place; nothing outside this module has to know how the source's
    /// own notion of a spot lines up with the app's.
    public var place: Place {
        .init(pluginID: Hyde.pluginID, key: key, name: name)
    }

    /// `nil` for a place belonging to some other plugin, even if the key happens to match.
    public init?(place: Place) {
        guard place.pluginID == Hyde.pluginID else {
            return nil
        }

        self.init(key: place.key)
    }

    /// Display name.
    public var name: String {
        switch self {
        case .hanstholm:
            return "Hanstholm"
        }
    }

    /// Stable identity, kept apart from `name` so the displayed label can change without
    /// orphaning anything filed under it.
    public var key: String {
        switch self {
        case .hanstholm:
            return "hanstholm"
        }
    }

    /// Where this station's readings are published.
    public var url: URL {
        switch self {
        case .hanstholm:
            return URL(string: "https://hyde.dk/default_hanstholm.asp")!
        }
    }

    public init?(key: String) {
        guard let match = Self.allCases.first(where: { $0.key == key }) else {
            return nil
        }

        self = match
    }
}
