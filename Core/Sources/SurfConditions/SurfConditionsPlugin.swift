import Foundation
import DomainTypes

public protocol SurfConditionsPlugin: Sendable {
    var id: String { get }
    var places: [Place] { get }

    func conditions(for place: Place, using session: URLSession) async throws -> SurfEntry
}

extension SurfConditionsPlugin {
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
