import Foundation
import DomainTypes

public protocol ConditionsPlugin: Sendable {
    var id: PluginID { get }
    var places: [Place] { get }
    var region: GeoRegion { get }

    func conditions(for place: Place, using session: URLSession) async throws -> SurfEntry
}

extension ConditionsPlugin {
    public func owns(_ place: Place) -> Bool {
        place.pluginID == id
    }
}

public enum ConditionsFault: Error, Equatable, Sendable {
    case unknownPlace(PlaceID)
    case noPluginForPlace(PlaceID)
    case noPlaceSelected
    case noCachedConditions(PlaceID)
    case placeMismatch(expected: PlaceID, actual: PlaceID)
    case unexpectedMediaType(String?)
    case decoding
}
