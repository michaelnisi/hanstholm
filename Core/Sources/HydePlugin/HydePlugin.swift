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
    public static let pluginID = "ink.codes.Hanstholm.plugin.hyde"

    public var id: String {
        Self.pluginID
    }

    public var places: [Place] {
        Hyde.Place.allCases.map(Self.place(for:))
    }

    public init() {}

    static func place(for place: Hyde.Place) -> Place {
        .init(pluginID: pluginID, key: place.key, name: place.name)
    }

    private func hydePlace(for place: Place) throws -> Hyde.Place {
        guard owns(place), let match = Hyde.Place(key: place.key) else {
            throw SurfConditionsFault.unknownPlace(place.id)
        }

        return match
    }

    public func conditions(for place: Place, using session: URLSession) async throws -> SurfEntry {
        let request = try deferredRequest(for: place)
        let (data, response) = try await session.data(for: request)

        return try await decodeDeferred(data, mimeType: response.mimeType, for: place)
    }

    public func deferredRequest(for place: Place) throws -> URLRequest {
        URLRequest(url: try hydePlace(for: place).url)
    }

    public func decodeDeferred(
        _ data: Data,
        mimeType: String?,
        for place: Place
    ) async throws -> SurfEntry {
        if let mimeType, mimeType != "text/html" {
            throw SurfConditionsFault.unexpectedMediaType(mimeType)
        }

        let hydePlace = try hydePlace(for: place)

        // `Parser` strips HTML with the `NSAttributedString` importer, which is
        // main-thread-only. Previously this ran wherever the caller happened to be; the hop
        // is explicit now so a background-session delegate can't drag it onto its own queue.
        return try await MainActor.run {
            let dto = try Hyde(place: hydePlace, data: data)

            guard let entry = SurfEntry(dto: dto, place: place) else {
                throw SurfConditionsFault.decoding
            }

            return entry
        }
    }
}
