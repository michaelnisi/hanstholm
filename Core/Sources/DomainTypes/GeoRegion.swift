public struct GeoRegion: Hashable, Sendable, Codable {
    public let latitude: Double
    public let longitude: Double
    public let radius: Double

    public init(latitude: Double, longitude: Double, radius: Double) {
        self.latitude = latitude
        self.longitude = longitude
        self.radius = radius
    }
}
