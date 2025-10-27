import Foundation
import WeatherKit
import CoreLocation
import Combine
import os.log

/// Weather and environmental adaptation engine for intelligent workout modifications
/// Automatically adjusts training recommendations based on weather conditions and environmental factors
@MainActor
class WeatherAdaptationEngine: NSObject, ObservableObject {
    static let shared = WeatherAdaptationEngine()
    
    // MARK: - Published Properties
    @Published var currentWeather: WeatherConditions?
    @Published var workoutAdaptations: [WorkoutAdaptation] = []
    @Published var environmentalAlerts: [EnvironmentalAlert] = []
    @Published var optimalTrainingWindows: [TrainingWindow] = []
    
    // MARK: - Weather Service
    private let weatherService = WeatherService.shared
    private let locationManager = CLLocationManager()
    private let logger = Logger(subsystem: "com.accelerate.sc40", category: "WeatherAdaptation")
    
    // MARK: - Current Location
    private var currentLocation: CLLocation?
    
    // MARK: - Data Structures
    
    struct WeatherConditions {
        let temperature: Measurement<UnitTemperature>
        let humidity: Double // 0-1
        let windSpeed: Measurement<UnitSpeed>
        let windDirection: Measurement<UnitAngle>
        let precipitation: PrecipitationType
        let uvIndex: Int
        let airQuality: AirQualityIndex?
        let visibility: Measurement<UnitLength>
        let pressure: Measurement<UnitPressure>
        let timestamp: Date
        
        enum PrecipitationType {
            case none, light, moderate, heavy, snow, sleet
        }
        
        enum AirQualityIndex {
            case good, moderate, unhealthyForSensitive, unhealthy, veryUnhealthy, hazardous
            
            var description: String {
                switch self {
                case .good: return "Good"
                case .moderate: return "Moderate"
                case .unhealthyForSensitive: return "Unhealthy for Sensitive Groups"
                case .unhealthy: return "Unhealthy"
                case .veryUnhealthy: return "Very Unhealthy"
                case .hazardous: return "Hazardous"
                }
            }
        }
    }
    
    struct WorkoutAdaptation {
        let id = UUID()
        let type: AdaptationType
        let severity: AdaptationSeverity
        let modification: WorkoutModification
        let reasoning: String
        let confidence: Double
        let timestamp: Date
        
        enum AdaptationType {
            case temperature, humidity, wind, precipitation, airQuality, uv, visibility
        }
        
        enum AdaptationSeverity {
            case minor, moderate, major, critical
        }
        
        struct WorkoutModification {
            let parameter: String
            let originalValue: Double
            let adaptedValue: Double
            let unit: String
            let description: String
        }
    }
    
    struct EnvironmentalAlert {
        let id = UUID()
        let type: AlertType
        let severity: AlertSeverity
        let message: String
        let recommendation: String
        let validUntil: Date
        
        enum AlertType {
            case heatWarning, coldWarning, airQuality, storm, highWind, lowVisibility
        }
        
        enum AlertSeverity {
            case advisory, watch, warning, emergency
            
            var color: String {
                switch self {
                case .advisory: return "blue"
                case .watch: return "yellow"
                case .warning: return "orange"
                case .emergency: return "red"
                }
            }
        }
    }
    
    struct TrainingWindow {
        let id = UUID()
        let startTime: Date
        let endTime: Date
        let suitability: TrainingSuitability
        let conditions: WeatherConditions
        let recommendations: [String]
        
        enum TrainingSuitability {
            case optimal, good, fair, poor, unsafe
            
            var score: Double {
                switch self {
                case .optimal: return 1.0
                case .good: return 0.8
                case .fair: return 0.6
                case .poor: return 0.4
                case .unsafe: return 0.0
                }
            }
        }
    }
    
    private override init() {
        super.init()
        setupLocationTracking()
        startWeatherMonitoring()
    }
    
    // MARK: - Setup
    
    private func setupLocationTracking() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.requestWhenInUseAuthorization()
    }
    
    private func startWeatherMonitoring() {
        // Update weather every 30 minutes
        Timer.scheduledTimer(withTimeInterval: 1800, repeats: true) { [weak self] _ in
            Task {
                await self?.updateWeatherConditions()
            }
        }
        
        // Initial weather update
        Task {
            await updateWeatherConditions()
        }
    }
    
    // MARK: - Weather Data Management
    
    private func updateWeatherConditions() async {
        guard let location = currentLocation else {
            logger.warning("No location available for weather update")
            return
        }
        
        do {
            let weather = try await weatherService.weather(for: location)
            let conditions = convertToWeatherConditions(weather)
            
            currentWeather = conditions
            
            // Generate adaptations and alerts
            await generateWorkoutAdaptations(conditions)
            await generateEnvironmentalAlerts(conditions)
            await generateOptimalTrainingWindows(conditions)
            
            logger.info("Weather conditions updated successfully")
            
        } catch {
            logger.error("Failed to fetch weather: \(error.localizedDescription)")
        }
    }
    
    private func convertToWeatherConditions(_ weather: Weather) -> WeatherConditions {
        return WeatherConditions(
            temperature: weather.currentWeather.temperature,
            humidity: weather.currentWeather.humidity,
            windSpeed: weather.currentWeather.wind.speed,
            windDirection: weather.currentWeather.wind.direction ?? Measurement(value: 0, unit: UnitAngle.degrees),
            precipitation: convertPrecipitation(weather.currentWeather.condition),
            uvIndex: weather.currentWeather.uvIndex.value,
            airQuality: nil, // Would integrate with air quality API
            visibility: weather.currentWeather.visibility,
            pressure: weather.currentWeather.pressure,
            timestamp: Date()
        )
    }
    
    private func convertPrecipitation(_ condition: WeatherKit.WeatherCondition) -> WeatherConditions.PrecipitationType {
        // Use a simplified approach since WeatherKit enum cases may vary
        let conditionDescription = condition.description.lowercased()
        
        if conditionDescription.contains("rain") {
            if conditionDescription.contains("heavy") {
                return .heavy
            } else if conditionDescription.contains("light") || conditionDescription.contains("drizzle") {
                return .light
            } else {
                return .moderate
            }
        } else if conditionDescription.contains("snow") {
            return .snow
        } else if conditionDescription.contains("sleet") {
            return .sleet
        } else {
            return .none
        }
    }
    
    // MARK: - Adaptation Generation
    
    private func generateWorkoutAdaptations(_ conditions: WeatherConditions) async {
        var adaptations: [WorkoutAdaptation] = []
        
        // Temperature adaptations
        let tempCelsius = conditions.temperature.converted(to: .celsius).value
        
        if tempCelsius > 30 { // Above 86°F
            adaptations.append(WorkoutAdaptation(
                type: .temperature,
                severity: .major,
                modification: WorkoutAdaptation.WorkoutModification(
                    parameter: "intensity",
                    originalValue: 0.85,
                    adaptedValue: 0.70,
                    unit: "percentage",
                    description: "Reduce intensity due to high temperature"
                ),
                reasoning: "High temperature increases heat stress and dehydration risk",
                confidence: 0.9,
                timestamp: Date()
            ))
            
            adaptations.append(WorkoutAdaptation(
                type: .temperature,
                severity: .moderate,
                modification: WorkoutAdaptation.WorkoutModification(
                    parameter: "rest_periods",
                    originalValue: 120,
                    adaptedValue: 180,
                    unit: "seconds",
                    description: "Extend rest periods for cooling"
                ),
                reasoning: "Longer rest periods needed for thermoregulation",
                confidence: 0.85,
                timestamp: Date()
            ))
        }
        
        if tempCelsius < 5 { // Below 41°F
            adaptations.append(WorkoutAdaptation(
                type: .temperature,
                severity: .moderate,
                modification: WorkoutAdaptation.WorkoutModification(
                    parameter: "warmup_duration",
                    originalValue: 300,
                    adaptedValue: 450,
                    unit: "seconds",
                    description: "Extended warmup for cold conditions"
                ),
                reasoning: "Cold temperatures require longer warmup to prevent injury",
                confidence: 0.9,
                timestamp: Date()
            ))
        }
        
        // Humidity adaptations
        if conditions.humidity > 0.8 {
            adaptations.append(WorkoutAdaptation(
                type: .humidity,
                severity: .moderate,
                modification: WorkoutAdaptation.WorkoutModification(
                    parameter: "hydration_breaks",
                    originalValue: 0,
                    adaptedValue: 2,
                    unit: "count",
                    description: "Add hydration breaks"
                ),
                reasoning: "High humidity impairs sweat evaporation and cooling",
                confidence: 0.8,
                timestamp: Date()
            ))
        }
        
        // Wind adaptations
        let windSpeedKmh = conditions.windSpeed.converted(to: .kilometersPerHour).value
        if windSpeedKmh > 25 { // Above 15.5 mph
            adaptations.append(WorkoutAdaptation(
                type: .wind,
                severity: .minor,
                modification: WorkoutAdaptation.WorkoutModification(
                    parameter: "direction_consideration",
                    originalValue: 0,
                    adaptedValue: 1,
                    unit: "boolean",
                    description: "Consider wind direction for sprint orientation"
                ),
                reasoning: "Strong winds affect sprint performance and safety",
                confidence: 0.7,
                timestamp: Date()
            ))
        }
        
        // UV adaptations
        if conditions.uvIndex >= 8 {
            adaptations.append(WorkoutAdaptation(
                type: .uv,
                severity: .moderate,
                modification: WorkoutAdaptation.WorkoutModification(
                    parameter: "session_timing",
                    originalValue: 14, // 2 PM
                    adaptedValue: 10, // 10 AM
                    unit: "hour",
                    description: "Recommend earlier training time"
                ),
                reasoning: "High UV index increases skin damage and heat stress risk",
                confidence: 0.85,
                timestamp: Date()
            ))
        }
        
        // Precipitation adaptations
        if conditions.precipitation != .none {
            adaptations.append(WorkoutAdaptation(
                type: .precipitation,
                severity: .major,
                modification: WorkoutAdaptation.WorkoutModification(
                    parameter: "surface_type",
                    originalValue: 0, // outdoor track
                    adaptedValue: 1, // indoor alternative
                    unit: "type",
                    description: "Recommend indoor training alternative"
                ),
                reasoning: "Wet surfaces increase slip and injury risk",
                confidence: 0.95,
                timestamp: Date()
            ))
        }
        
        workoutAdaptations = adaptations
    }
    
    private func generateEnvironmentalAlerts(_ conditions: WeatherConditions) async {
        var alerts: [EnvironmentalAlert] = []
        
        let tempCelsius = conditions.temperature.converted(to: .celsius).value
        
        // Heat warnings
        if tempCelsius > 35 { // Above 95°F
            alerts.append(EnvironmentalAlert(
                type: .heatWarning,
                severity: .warning,
                message: "Extreme heat conditions detected",
                recommendation: "Consider postponing outdoor training or moving indoors",
                validUntil: Calendar.current.date(byAdding: .hour, value: 4, to: Date()) ?? Date()
            ))
        } else if tempCelsius > 30 && conditions.humidity > 0.7 {
            alerts.append(EnvironmentalAlert(
                type: .heatWarning,
                severity: .watch,
                message: "High heat index due to temperature and humidity combination",
                recommendation: "Increase hydration and reduce intensity",
                validUntil: Calendar.current.date(byAdding: .hour, value: 2, to: Date()) ?? Date()
            ))
        }
        
        // Cold warnings
        if tempCelsius < -5 { // Below 23°F
            alerts.append(EnvironmentalAlert(
                type: .coldWarning,
                severity: .warning,
                message: "Extreme cold conditions",
                recommendation: "Extended warmup required. Consider indoor alternatives",
                validUntil: Calendar.current.date(byAdding: .hour, value: 4, to: Date()) ?? Date()
            ))
        }
        
        // Wind warnings
        let windSpeedKmh = conditions.windSpeed.converted(to: .kilometersPerHour).value
        if windSpeedKmh > 40 { // Above 25 mph
            alerts.append(EnvironmentalAlert(
                type: .highWind,
                severity: .watch,
                message: "High wind speeds detected",
                recommendation: "Exercise caution with sprint direction and consider indoor training",
                validUntil: Calendar.current.date(byAdding: .hour, value: 2, to: Date()) ?? Date()
            ))
        }
        
        // Visibility warnings
        let visibilityKm = conditions.visibility.converted(to: .kilometers).value
        if visibilityKm < 1 {
            alerts.append(EnvironmentalAlert(
                type: .lowVisibility,
                severity: .warning,
                message: "Low visibility conditions",
                recommendation: "Avoid outdoor training for safety",
                validUntil: Calendar.current.date(byAdding: .hour, value: 2, to: Date()) ?? Date()
            ))
        }
        
        environmentalAlerts = alerts
    }
    
    private func generateOptimalTrainingWindows(_ conditions: WeatherConditions) async {
        var windows: [TrainingWindow] = []
        let calendar = Calendar.current
        let now = Date()
        
        // Generate windows for next 24 hours
        for hour in 0..<24 {
            guard let windowStart = calendar.date(byAdding: .hour, value: hour, to: now),
                  let windowEnd = calendar.date(byAdding: .hour, value: hour + 1, to: now) else { continue }
            
            // Predict conditions for this window (simplified - would use forecast data)
            let predictedConditions = predictConditionsForTime(windowStart, baseConditions: conditions)
            let suitability = assessTrainingSuitability(predictedConditions)
            let recommendations = generateWindowRecommendations(predictedConditions, suitability)
            
            let window = TrainingWindow(
                startTime: windowStart,
                endTime: windowEnd,
                suitability: suitability,
                conditions: predictedConditions,
                recommendations: recommendations
            )
            
            windows.append(window)
        }
        
        // Sort by suitability score
        optimalTrainingWindows = windows.sorted { $0.suitability.score > $1.suitability.score }
    }
    
    private func predictConditionsForTime(_ time: Date, baseConditions: WeatherConditions) -> WeatherConditions {
        // Simplified prediction - in reality would use weather forecast API
        let hour = Calendar.current.component(.hour, from: time)
        
        // Adjust temperature based on time of day
        var tempAdjustment: Double = 0
        switch hour {
        case 6...11: tempAdjustment = -2 // Cooler in morning
        case 12...16: tempAdjustment = 2 // Warmer in afternoon
        case 17...20: tempAdjustment = 0 // Moderate in evening
        default: tempAdjustment = -4 // Cooler at night
        }
        
        let adjustedTemp = Measurement(
            value: baseConditions.temperature.converted(to: .celsius).value + tempAdjustment,
            unit: UnitTemperature.celsius
        )
        
        return WeatherConditions(
            temperature: adjustedTemp,
            humidity: baseConditions.humidity,
            windSpeed: baseConditions.windSpeed,
            windDirection: baseConditions.windDirection,
            precipitation: baseConditions.precipitation,
            uvIndex: hour >= 10 && hour <= 16 ? baseConditions.uvIndex : 0,
            airQuality: baseConditions.airQuality,
            visibility: baseConditions.visibility,
            pressure: baseConditions.pressure,
            timestamp: time
        )
    }
    
    private func assessTrainingSuitability(_ conditions: WeatherConditions) -> TrainingWindow.TrainingSuitability {
        let tempCelsius = conditions.temperature.converted(to: .celsius).value
        let windSpeedKmh = conditions.windSpeed.converted(to: .kilometersPerHour).value
        
        // Temperature scoring
        var tempScore: Double = 1.0
        if tempCelsius < 0 || tempCelsius > 35 {
            tempScore = 0.2 // Unsafe
        } else if tempCelsius < 5 || tempCelsius > 30 {
            tempScore = 0.4 // Poor
        } else if tempCelsius < 10 || tempCelsius > 25 {
            tempScore = 0.6 // Fair
        } else if tempCelsius < 15 || tempCelsius > 22 {
            tempScore = 0.8 // Good
        } // else optimal (1.0)
        
        // Wind scoring
        var windScore: Double = 1.0
        if windSpeedKmh > 40 {
            windScore = 0.2
        } else if windSpeedKmh > 25 {
            windScore = 0.6
        } else if windSpeedKmh > 15 {
            windScore = 0.8
        }
        
        // Precipitation scoring
        var precipScore: Double = 1.0
        switch conditions.precipitation {
        case .none: precipScore = 1.0
        case .light: precipScore = 0.6
        case .moderate: precipScore = 0.3
        case .heavy, .snow, .sleet: precipScore = 0.1
        }
        
        // UV scoring
        var uvScore: Double = 1.0
        if conditions.uvIndex >= 10 {
            uvScore = 0.4
        } else if conditions.uvIndex >= 8 {
            uvScore = 0.7
        }
        
        // Combined score
        let overallScore = (tempScore + windScore + precipScore + uvScore) / 4.0
        
        switch overallScore {
        case 0.9...1.0: return .optimal
        case 0.7..<0.9: return .good
        case 0.5..<0.7: return .fair
        case 0.2..<0.5: return .poor
        default: return .unsafe
        }
    }
    
    private func generateWindowRecommendations(_ conditions: WeatherConditions, 
                                            _ suitability: TrainingWindow.TrainingSuitability) -> [String] {
        var recommendations: [String] = []
        
        let tempCelsius = conditions.temperature.converted(to: .celsius).value
        
        if tempCelsius > 25 {
            recommendations.append("Increase hydration before and during training")
            recommendations.append("Consider lighter colored clothing")
        }
        
        if tempCelsius < 10 {
            recommendations.append("Extended warmup recommended")
            recommendations.append("Layer clothing for temperature regulation")
        }
        
        if conditions.humidity > 0.7 {
            recommendations.append("Monitor for signs of overheating")
        }
        
        if conditions.windSpeed.converted(to: .kilometersPerHour).value > 15 {
            recommendations.append("Consider wind direction for sprint planning")
        }
        
        if conditions.uvIndex >= 6 {
            recommendations.append("Apply sunscreen and wear protective clothing")
        }
        
        return recommendations
    }
    
    // MARK: - Public Interface
    
    func getWorkoutAdaptationsForSession(_ session: TrainingSession) -> [WorkoutAdaptation] {
        return workoutAdaptations.filter { adaptation in
            // Filter adaptations relevant to the session type
            switch session.type.lowercased() {
            case "speed", "sprint":
                return true // All adaptations relevant for high-intensity work
            case "recovery":
                return adaptation.type == .temperature || adaptation.type == .humidity
            default:
                return adaptation.severity != .minor
            }
        }
    }
    
    func getOptimalTrainingTime(for date: Date) -> TrainingWindow? {
        let calendar = Calendar.current
        
        return optimalTrainingWindows.first { window in
            calendar.isDate(window.startTime, inSameDayAs: date) && 
            window.suitability == .optimal || window.suitability == .good
        }
    }
    
    func shouldPostponeWorkout() -> Bool {
        return environmentalAlerts.contains { alert in
            alert.severity == .warning || alert.severity == .emergency
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension WeatherAdaptationEngine: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        
        Task {
            await updateWeatherConditions()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        logger.error("Location update failed: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        case .denied, .restricted:
            logger.warning("Location permission denied - weather adaptations will be limited")
        default:
            break
        }
    }
}
