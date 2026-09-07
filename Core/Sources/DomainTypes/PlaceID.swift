public struct PluginID: RawRepresentable, Hashable, Sendable, Codable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.rawValue = value
    }
}

public struct PlaceID: Hashable, Sendable, Codable {
    public let plugin: PluginID
    public let key: String

    public init(plugin: PluginID, key: String) {
        self.plugin = plugin
        self.key = key
    }
}

extension PlaceID: CustomStringConvertible {
    public var description: String {
        "\(plugin.rawValue)/\(key)"
    }
}
