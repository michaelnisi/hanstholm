import CoreLocation
import DomainTypes

extension GeoRegion {
    var clRegion: CLCircularRegion {
        CLCircularRegion(
            center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            radius: radius,
            identifier: "\(latitude),\(longitude)"
        )
    }
}
