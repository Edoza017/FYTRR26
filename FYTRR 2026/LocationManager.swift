import Foundation
import CoreLocation
import UIKit

final class LocationManager: NSObject, ObservableObject {

    private let manager = CLLocationManager()

    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus?
    @Published var locationErrorMessage: String?
    @Published var isRequestingLocation = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = kCLDistanceFilterNone
        authorizationStatus = manager.authorizationStatus
    }

    func start() {
        let status = manager.authorizationStatus
        locationErrorMessage = nil

        switch status {
        case .notDetermined:
            isRequestingLocation = true
            manager.requestWhenInUseAuthorization()

        case .authorizedWhenInUse, .authorizedAlways:
            isRequestingLocation = true
            manager.requestLocation()
            manager.startUpdatingLocation()

        case .denied, .restricted:
            isRequestingLocation = false
            locationErrorMessage = "Location permission denied. Open Settings to enable it."

        @unknown default:
            isRequestingLocation = false
            locationErrorMessage = "Unknown location authorization status."
        }
    }

    func openSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL)
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        authorizationStatus = status

        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationErrorMessage = nil
            isRequestingLocation = true
            manager.requestLocation()
            manager.startUpdatingLocation()
        } else if status == .denied || status == .restricted {
            isRequestingLocation = false
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

        guard let loc = locations.last else { return }

        DispatchQueue.main.async {
            self.location = loc
            self.isRequestingLocation = false
        }

        locationErrorMessage = nil
        manager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let clError = error as? CLError, clError.code == .locationUnknown {
            manager.startUpdatingLocation()
            return
        }
        DispatchQueue.main.async {
            self.isRequestingLocation = false
            self.locationErrorMessage = error.localizedDescription
        }
    }
}
