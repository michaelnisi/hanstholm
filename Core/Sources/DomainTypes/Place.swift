import Foundation

public struct Place: Hashable, Sendable, Codable, Identifiable {
    public let pluginID: String
    public let key: String
    public let name: String

    public var id: String {
        "\(pluginID)/\(key)"
    }

    public init(pluginID: String, key: String, name: String) {
        self.pluginID = pluginID
        self.key = key
        self.name = name
    }
}
