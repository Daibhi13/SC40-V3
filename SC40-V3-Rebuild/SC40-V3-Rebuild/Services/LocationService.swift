import Foundation
import CoreLocation
import MapKit

class LocationService: NSObject, ObservableObject, @unchecked Sendable {
    private let locationManager = CLLocationManager()
    
    @Published var userLocation: CLLocation?
    @Published var county: String = ""
    @Published var state: String = ""
    @Published var country: String = ""
    @Published var isAuthorized = false
    @Published var errorMessage: String?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocationPermission() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            errorMessage = "Location access denied. Please enable location services in Settings."
        case .authorizedWhenInUse, .authorizedAlways:
            isAuthorized = true
            getCurrentLocation()
        @unknown default:
            errorMessage = "Unknown location authorization status."
        }
    }
    
    private func getCurrentLocation() {
        guard isAuthorized else { return }
        locationManager.requestLocation()
    }
    
    private func reverseGeocode(location: CLLocation) {
        // Use CLGeocoder but suppress warnings for now
        reverseGeocodeWithCLGeocoder(location: location)
    }
    
    private func reverseGeocodeWithCLGeocoder(location: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            DispatchQueue.main.async { [weak self] in
                if let error = error {
                    self?.errorMessage = "Failed to get location details: \(error.localizedDescription)"
                    return
                }
                
                guard let placemark = placemarks?.first else {
                    self?.errorMessage = "No location information found"
                    return
                }
                
                // Extract location details
                self?.county = placemark.subAdministrativeArea ?? ""
                self?.state = placemark.administrativeArea ?? ""
                self?.country = placemark.country ?? ""
                
                print("📍 Location detected:")
                print("   County: \(self?.county ?? "Unknown")")
                print("   State: \(self?.state ?? "Unknown")")
                print("   Country: \(self?.country ?? "Unknown")")
            }
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        userLocation = location
        reverseGeocode(location: location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = "Location error: \(error.localizedDescription)"
        print("📍 Location error: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async { [weak self] in
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                self?.isAuthorized = true
                self?.getCurrentLocation()
            case .denied, .restricted:
                self?.isAuthorized = false
                self?.errorMessage = "Location access denied"
            case .notDetermined:
                self?.isAuthorized = false
            @unknown default:
                self?.isAuthorized = false
            }
        }
    }
}
