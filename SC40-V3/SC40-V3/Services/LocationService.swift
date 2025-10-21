import Foundation
import Combine
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
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = " " // Empty query for reverse geocoding
        request.region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 100, longitudinalMeters: 100)

        let search = MKLocalSearch(request: request)
        search.start { [weak self] (response: MKLocalSearch.Response?, error: Error?) in
            // Ensure we have a strong self before hopping to the main queue
            guard let self = self else { return }

            Task { @MainActor in
                if let error = error {
                    self.errorMessage = "Failed to get location details: \(error.localizedDescription)"
                    return
                }

                guard let mapItem = response?.mapItems.first else {
                    self.errorMessage = "No location information found"
                    return
                }

                // Extract county/state/country using CLPlacemark fields (portable across OS versions)
                var county = ""
                var state = ""
                var country = ""

                // Note: Using deprecated APIs that will be replaced in iOS 26.0
                // TODO: Update to use MKReverseGeocodingRequest when iOS 26.0 APIs are available
                let placemark = mapItem.placemark
                
                // Extract location data using available properties
                if let admin = placemark.administrativeArea, !admin.isEmpty {
                    state = admin
                }
                if let countryName = placemark.country, !countryName.isEmpty {
                    country = countryName
                }
                if let subAdmin = placemark.subAdministrativeArea, !subAdmin.isEmpty {
                    county = subAdmin
                }

                // As a final enrichment step, if any field is still empty, use CLGeocoder
                // Note: CLGeocoder is deprecated in iOS 26.0, but we'll use it until replacement is available
                if (county.isEmpty || state.isEmpty || country.isEmpty) {
                    let geocoder = CLGeocoder()
                    do {
                        let placemarks = try await geocoder.reverseGeocodeLocation(location)
                        if let pm = placemarks.first {
                            if county.isEmpty { county = pm.subAdministrativeArea ?? county }
                            if state.isEmpty { state = pm.administrativeArea ?? state }
                            if country.isEmpty { country = pm.country ?? country }
                        }
                    } catch {
                        self.errorMessage = "Failed to reverse geocode: \(error.localizedDescription)"
                    }
                }

                self.county = county
                self.state = state
                self.country = country

                print("📍 Location detected:")
                print("   County: \(self.county)")
                print("   State: \(self.state)")
                print("   Country: \(self.country)")
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
