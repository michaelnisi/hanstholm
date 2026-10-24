import Foundation

extension PlaceID {
    static let urlScheme = "patrol"
    static let urlHost = "place"

    public var url: URL? {
        let segments = [plugin.rawValue, key].map(Self.encodePathSegment)
        var components = URLComponents()

        components.scheme = Self.urlScheme
        components.host = Self.urlHost
        components.percentEncodedPath = "/" + segments.joined(separator: "/")

        return components.url
    }

    public init?(url: URL) {
        guard
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            components.scheme == Self.urlScheme,
            components.host == Self.urlHost
        else {
            return nil
        }

        let segments = components.percentEncodedPath
            .split(separator: "/", omittingEmptySubsequences: false)
            .dropFirst()
            .compactMap { $0.removingPercentEncoding }

        guard segments.count == 2, let plugin = segments.first, let key = segments.last,
            !plugin.isEmpty, !key.isEmpty
        else {
            return nil
        }

        self.init(plugin: PluginID(rawValue: plugin), key: key)
    }

    private static func encodePathSegment(_ segment: String) -> String {
        var allowed = CharacterSet.urlPathAllowed

        allowed.remove("/")

        return segment.addingPercentEncoding(withAllowedCharacters: allowed) ?? segment
    }
}
