import CoreLocation
import Observation

@Observable final class LocationAuthorizer: NSObject, CLLocationManagerDelegate {
    static let shared = LocationAuthorizer()

    private let manager = CLLocationManager()
    private(set) var status: CLAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        manager.delegate = self
        status = manager.authorizationStatus
    }

    func requestAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let newStatus = manager.authorizationStatus

        Task { @MainActor in
            status = newStatus
        }
    }
}
