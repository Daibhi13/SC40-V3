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

                // Enhanced location enrichment with modern APIs
                if (county.isEmpty || state.isEmpty || country.isEmpty) {
                    // Use modern MKLocalSearch for better accuracy and future compatibility
                    await enrichLocationWithMKLocalSearch(location: location, county: &county, state: &state, country: &country)
                    
                    // Fallback to CLGeocoder only if MKLocalSearch fails
                    if (county.isEmpty || state.isEmpty || country.isEmpty) {
                        await fallbackToCLGeocoder(location: location, county: &county, state: &state, country: &country)
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

    // MARK: - Modern Location Enrichment Methods
    
    private func enrichLocationWithMKLocalSearch(location: CLLocation, county: inout String, state: inout String, country: inout String) async {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "location details"
        request.region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 1000,
            longitudinalMeters: 1000
        )
        
        let search = MKLocalSearch(request: request)
        
        do {
            let response = try await search.start()
            
            if let mapItem = response.mapItems.first {
                let placemark = mapItem.placemark
                
                if county.isEmpty, let subAdmin = placemark.subAdministrativeArea {
                    county = subAdmin
                }
                if state.isEmpty, let admin = placemark.administrativeArea {
                    state = admin
                }
                if country.isEmpty, let countryName = placemark.country {
                    country = countryName
                }
                
                print("✅ LocationService: Enhanced with MKLocalSearch")
            }
        } catch {
            print("⚠️ LocationService: MKLocalSearch failed - \(error.localizedDescription)")
        }
    }
    
    private func fallbackToCLGeocoder(location: CLLocation, county: inout String, state: inout String, country: inout String) async {
        // Note: CLGeocoder will be deprecated in iOS 26.0
        // TODO: Replace with MKReverseGeocodingRequest when available
        let geocoder = CLGeocoder()
        
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            
            if let placemark = placemarks.first {
                if county.isEmpty, let subAdmin = placemark.subAdministrativeArea {
                    county = subAdmin
                }
                if state.isEmpty, let admin = placemark.administrativeArea {
                    state = admin
                }
                if country.isEmpty, let countryName = placemark.country {
                    country = countryName
                }
                
                print("✅ LocationService: Fallback CLGeocoder used")
            }
        } catch {
            print("❌ LocationService: CLGeocoder fallback failed - \(error.localizedDescription)")
            // Note: Error handling is done at the caller level
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
