//
//  HydePlugin.swift
//
//
//  Created by Michael Nisi on 29.07.26.
//

import Foundation
import os.log
import Hyde
import DomainTypes
import SurfConditions

let logger = Logger(subsystem: "ink.codes.Hanstholm", category: "HydePlugin")

/// Adapts `Hyde` — which stays a pure DTO and parser — to the plugin protocol.
public struct HydePlugin: SurfConditionsPlugin, DeferredDownloadable {
    public let id = "ink.codes.Hanstholm.plugin.hyde"

    public var places: [String] {
        Hyde.Place.allCases.map(\.name)
    }

    public init() {}

    public func conditions(for place: String, using session: URLSession) async throws -> SurfEntry {
        let request = try deferredRequest(for: place)
        let (data, response) = try await session.data(for: request)

        return try await decodeDeferred(data, mimeType: response.mimeType, for: place)
    }

    public func deferredRequest(for place: String) throws -> URLRequest {
        guard let place = Hyde.Place(name: place) else {
            throw SurfConditionsFault.unknownPlace(place)
        }

        return URLRequest(url: place.url)
    }

    public func decodeDeferred(
        _ data: Data,
        mimeType: String?,
        for place: String
    ) async throws -> SurfEntry {
        if let mimeType, mimeType != "text/html" {
            throw SurfConditionsFault.unexpectedMediaType(mimeType)
        }

        guard let place = Hyde.Place(name: place) else {
            throw SurfConditionsFault.unknownPlace(place)
        }

        // `Parser` strips HTML with the `NSAttributedString` importer, which is
        // main-thread-only. Previously this ran wherever the caller happened to be; the hop
        // is explicit now so a background-session delegate can't drag it onto its own queue.
        return try await MainActor.run {
            let dto = try Hyde(place: place, data: data)

            guard let entry = SurfEntry(dto: dto) else {
                throw SurfConditionsFault.decoding
            }

            return entry
        }
    }
}
