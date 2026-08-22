import Foundation

public struct Place: Hashable, Sendable, Codable, Identifiable {
    public let pluginID: String
    public let key: String
    public let name: String
    public let icon: String

    public var id: String {
        "\(pluginID)/\(key)"
    }

    public init(pluginID: String, key: String, name: String, icon: String = "mappin.and.ellipse") {
        self.pluginID = pluginID
        self.key = key
        self.name = name
        self.icon = icon
    }
}
