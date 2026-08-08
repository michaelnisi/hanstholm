import os.log
import Foundation
import DomainTypes
import SurfConditions

let logger = Logger(subsystem: "ink.codes.Hanstholm", category: "Hyde")

public struct Hyde: SurfConditionsPlugin, DeferredDownloadable {
    public static let pluginID = "ink.codes.Hanstholm.plugin.hyde"

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

        return try await MainActor.run {
            let report = try Report(station: station, data: data)

            guard let entry = SurfEntry(report: report, place: place) else {
                throw SurfConditionsFault.decoding
            }

            return entry
        }
    }
}

extension Hyde.Station {
    public var place: Place {
        .init(pluginID: Hyde.pluginID, key: key, name: name)
    }

    public init?(place: Place) {
        guard place.pluginID == Hyde.pluginID else {
            return nil
        }

        self.init(key: place.key)
    }

    public var name: String {
        switch self {
        case .hanstholm:
            return "Hanstholm"
        }
    }

    public var key: String {
        switch self {
        case .hanstholm:
            return "hanstholm"
        }
    }

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
