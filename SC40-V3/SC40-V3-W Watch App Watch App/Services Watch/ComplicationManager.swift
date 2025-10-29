import Foundation
import ClockKit
import SwiftUI

/// ClockKit integration for SC40 watch face complications
@available(watchOS 7.0, *)
class ComplicationManager: NSObject, CLKComplicationDataSource {
    static let shared = ComplicationManager()
    
    // MARK: - Complication Configuration
    
    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        let descriptors = [
            CLKComplicationDescriptor(
                identifier: "sc40_next_workout",
                displayName: "Next Workout",
                supportedFamilies: [
                    .modularSmall,
                    .modularLarge,
                    .utilitarianSmall,
                    .utilitarianLarge,
                    .circularSmall,
                    .extraLarge,
                    .graphicCorner,
                    .graphicCircular,
                    .graphicRectangular,
                    .graphicExtraLarge
                ]
            ),
            CLKComplicationDescriptor(
                identifier: "sc40_personal_best",
                displayName: "Personal Best",
                supportedFamilies: [
                    .modularSmall,
                    .modularLarge,
                    .circularSmall,
                    .extraLarge,
                    .graphicCorner,
                    .graphicCircular,
                    .graphicRectangular
                ]
            ),
            CLKComplicationDescriptor(
                identifier: "sc40_weekly_progress",
                displayName: "Weekly Progress",
                supportedFamilies: [
                    .modularLarge,
                    .utilitarianLarge,
                    .extraLarge,
                    .graphicRectangular,
                    .graphicExtraLarge
                ]
            ),
            CLKComplicationDescriptor(
                identifier: "sc40_quick_start",
                displayName: "Quick Start",
                supportedFamilies: [
                    .modularSmall,
                    .circularSmall,
                    .graphicCorner,
                    .graphicCircular
                ]
            )
        ]
        
        handler(descriptors)
    }
    
    // MARK: - Timeline Configuration
    
    func getTimelineStartDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        // Start timeline from beginning of current week
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start
        handler(startOfWeek)
    }
    
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        // End timeline at end of current week
        let calendar = Calendar.current
        let endOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.end
        handler(endOfWeek)
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.showOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        let entry = createTimelineEntry(for: complication, date: Date())
        handler(entry)
    }
    
    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        var entries: [CLKComplicationTimelineEntry] = []
        let calendar = Calendar.current
        
        // Create entries for the next few days
        for i in 1...min(limit, 7) {
            if let futureDate = calendar.date(byAdding: .day, value: i, to: date) {
                if let entry = createTimelineEntry(for: complication, date: futureDate) {
                    entries.append(entry)
                }
            }
        }
        
        handler(entries.isEmpty ? nil : entries)
    }
    
    func getTimelineEntries(for complication: CLKComplication, before date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        var entries: [CLKComplicationTimelineEntry] = []
        let calendar = Calendar.current
        
        // Create entries for the previous few days
        for i in 1...min(limit, 7) {
            if let pastDate = calendar.date(byAdding: .day, value: -i, to: date) {
                if let entry = createTimelineEntry(for: complication, date: pastDate) {
                    entries.append(entry)
                }
            }
        }
        
        handler(entries.isEmpty ? nil : entries)
    }
    
    // MARK: - Localization
    
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        let template = createTemplate(for: complication, with: getSampleData(for: complication))
        handler(template)
    }
    
    // MARK: - Template Creation
    
    private func createTimelineEntry(for complication: CLKComplication, date: Date) -> CLKComplicationTimelineEntry? {
        let data = getComplicationData(for: complication, date: date)
        guard let template = createTemplate(for: complication, with: data) else { return nil }
        
        return CLKComplicationTimelineEntry(date: date, complicationTemplate: template)
    }
    
    private func createTemplate(for complication: CLKComplication, with data: ComplicationData) -> CLKComplicationTemplate? {
        switch complication.family {
        case .modularSmall:
            return createModularSmallTemplate(for: complication, with: data)
        case .modularLarge:
            return createModularLargeTemplate(for: complication, with: data)
        case .utilitarianSmall:
            return createUtilitarianSmallTemplate(for: complication, with: data)
        case .utilitarianLarge:
            return createUtilitarianLargeTemplate(for: complication, with: data)
        case .circularSmall:
            return createCircularSmallTemplate(for: complication, with: data)
        case .extraLarge:
            return createExtraLargeTemplate(for: complication, with: data)
        case .graphicCorner:
            return createGraphicCornerTemplate(for: complication, with: data)
        case .graphicCircular:
            return createGraphicCircularTemplate(for: complication, with: data)
        case .graphicRectangular:
            return createGraphicRectangularTemplate(for: complication, with: data)
        case .graphicExtraLarge:
            return createGraphicExtraLargeTemplate(for: complication, with: data)
        default:
            return nil
        }
    }
    
    // MARK: - Template Implementations
    
    private func createModularSmallTemplate(for complication: CLKComplication, with data: ComplicationData) -> CLKComplicationTemplate? {
        switch complication.identifier {
        case "sc40_next_workout":
            let template = CLKComplicationTemplateModularSmallStackText()
            template.line1TextProvider = CLKSimpleTextProvider(text: "NEXT")
            template.line2TextProvider = CLKSimpleTextProvider(text: data.nextWorkoutType)
            return template
            
        case "sc40_personal_best":
            let template = CLKComplicationTemplateModularSmallStackText()
            template.line1TextProvider = CLKSimpleTextProvider(text: "PB")
            template.line2TextProvider = CLKSimpleTextProvider(text: String(format: "%.2fs", data.personalBest))
            return template
            
        case "sc40_quick_start":
            let template = CLKComplicationTemplateModularSmallSimpleImage()
            template.imageProvider = CLKImageProvider(onePieceImage: UIImage(systemName: "bolt.fill")!)
            return template
            
        default:
            return nil
        }
    }
    
    private func createModularLargeTemplate(for complication: CLKComplication, with data: ComplicationData) -> CLKComplicationTemplate? {
        switch complication.identifier {
        case "sc40_next_workout":
            let template = CLKComplicationTemplateModularLargeStandardBody()
            template.headerTextProvider = CLKSimpleTextProvider(text: "SC40 Sprint Coach")
            template.body1TextProvider = CLKSimpleTextProvider(text: "Next: \(data.nextWorkoutType)")
            template.body2TextProvider = CLKSimpleTextProvider(text: "Week \(data.currentWeek), Day \(data.currentDay)")
            return template
            
        case "sc40_weekly_progress":
            let template = CLKComplicationTemplateModularLargeStandardBody()
            template.headerTextProvider = CLKSimpleTextProvider(text: "Weekly Progress")
            template.body1TextProvider = CLKSimpleTextProvider(text: "\(data.sessionsCompleted)/\(data.totalSessions) sessions")
            template.body2TextProvider = CLKSimpleTextProvider(text: "Best: \(String(format: "%.2fs", data.weeklyBest))")
            return template
            
        default:
            return nil
        }
    }
    
    private func createGraphicCircularTemplate(for complication: CLKComplication, with data: ComplicationData) -> CLKComplicationTemplate? {
        switch complication.identifier {
        case "sc40_next_workout":
            let template = CLKComplicationTemplateGraphicCircularStackText()
            template.line1TextProvider = CLKSimpleTextProvider(text: "NEXT")
            template.line2TextProvider = CLKSimpleTextProvider(text: data.nextWorkoutType)
            return template
            
        case "sc40_personal_best":
            let template = CLKComplicationTemplateGraphicCircularStackText()
            template.line1TextProvider = CLKSimpleTextProvider(text: "PB")
            template.line2TextProvider = CLKSimpleTextProvider(text: String(format: "%.2f", data.personalBest))
            return template
            
        case "sc40_quick_start":
            let template = CLKComplicationTemplateGraphicCircularImage()
            template.imageProvider = CLKFullColorImageProvider(fullColorImage: UIImage(systemName: "bolt.circle.fill")!)
            return template
            
        default:
            return nil
        }
    }
    
    private func createGraphicRectangularTemplate(for complication: CLKComplication, with data: ComplicationData) -> CLKComplicationTemplate? {
        switch complication.identifier {
        case "sc40_weekly_progress":
            let template = CLKComplicationTemplateGraphicRectangularStandardBody()
            template.headerTextProvider = CLKSimpleTextProvider(text: "SC40 Week \(data.currentWeek)")
            template.body1TextProvider = CLKSimpleTextProvider(text: "\(data.sessionsCompleted)/\(data.totalSessions) sessions completed")
            template.body2TextProvider = CLKSimpleTextProvider(text: "Best: \(String(format: "%.2fs", data.weeklyBest)) • Avg: \(String(format: "%.2fs", data.weeklyAverage))")
            return template
            
        case "sc40_next_workout":
            let template = CLKComplicationTemplateGraphicRectangularStandardBody()
            template.headerTextProvider = CLKSimpleTextProvider(text: "Next Sprint Session")
            template.body1TextProvider = CLKSimpleTextProvider(text: data.nextWorkoutType)
            template.body2TextProvider = CLKSimpleTextProvider(text: "Week \(data.currentWeek), Day \(data.currentDay)")
            return template
            
        default:
            return nil
        }
    }
    
    // MARK: - Additional Template Methods (simplified for brevity)
    
    private func createUtilitarianSmallTemplate(for complication: CLKComplication, with data: ComplicationData) -> CLKComplicationTemplate? {
        let template = CLKComplicationTemplateUtilitarianSmallFlat()
        template.textProvider = CLKSimpleTextProvider(text: String(format: "%.2f", data.personalBest))
        return template
    }
    
    private func createUtilitarianLargeTemplate(for complication: CLKComplication, with data: ComplicationData) -> CLKComplicationTemplate? {
        let template = CLKComplicationTemplateUtilitarianLargeFlat()
        template.textProvider = CLKSimpleTextProvider(text: "SC40: \(data.nextWorkoutType)")
        return template
    }
    
    private func createCircularSmallTemplate(for complication: CLKComplication, with data: ComplicationData) -> CLKComplicationTemplate? {
        let template = CLKComplicationTemplateCircularSmallStackText()
        template.line1TextProvider = CLKSimpleTextProvider(text: "PB")
        template.line2TextProvider = CLKSimpleTextProvider(text: String(format: "%.1f", data.personalBest))
        return template
    }
    
    private func createExtraLargeTemplate(for complication: CLKComplication, with data: ComplicationData) -> CLKComplicationTemplate? {
        let template = CLKComplicationTemplateExtraLargeStackText()
        template.line1TextProvider = CLKSimpleTextProvider(text: String(format: "%.2f", data.personalBest))
        template.line2TextProvider = CLKSimpleTextProvider(text: "SECONDS")
        return template
    }
    
    private func createGraphicCornerTemplate(for complication: CLKComplication, with data: ComplicationData) -> CLKComplicationTemplate? {
        let template = CLKComplicationTemplateGraphicCornerStackText()
        template.outerTextProvider = CLKSimpleTextProvider(text: "SC40")
        template.innerTextProvider = CLKSimpleTextProvider(text: String(format: "%.1f", data.personalBest))
        return template
    }
    
    private func createGraphicExtraLargeTemplate(for complication: CLKComplication, with data: ComplicationData) -> CLKComplicationTemplate? {
        let template = CLKComplicationTemplateGraphicExtraLargeCircularStackText()
        template.line1TextProvider = CLKSimpleTextProvider(text: "PERSONAL BEST")
        template.line2TextProvider = CLKSimpleTextProvider(text: String(format: "%.2f SECONDS", data.personalBest))
        return template
    }
    
    // MARK: - Data Management
    
    private func getComplicationData(for complication: CLKComplication, date: Date) -> ComplicationData {
        // Fetch real user data from Watch services
        _ = WatchDataStore.shared
        _ = WatchSessionManager.shared
        
        return ComplicationData(
            nextWorkoutType: getNextWorkoutType(),
            currentWeek: getCurrentWeek(),
            currentDay: getCurrentDay(),
            personalBest: getUserPersonalBest(),
            sessionsCompleted: getSessionsCompletedThisWeek(),
            totalSessions: getTotalSessionsThisWeek(),
            weeklyBest: getWeeklyBest(),
            weeklyAverage: getWeeklyAverage()
        )
    }
    
    private func getSampleData(for complication: CLKComplication) -> ComplicationData {
        return ComplicationData(
            nextWorkoutType: "Sprint",
            currentWeek: 3,
            currentDay: 2,
            personalBest: 4.85,
            sessionsCompleted: 4,
            totalSessions: 6,
            weeklyBest: 4.92,
            weeklyAverage: 5.15
        )
    }
    
    // MARK: - Helper Methods
    
    private func getNextWorkoutType() -> String {
        // Get next workout from real session data
        let sessionManager = WatchSessionManager.shared
        
        if let nextSession = sessionManager.trainingSessions.first {
            return nextSession.type
        }
        
        // Fallback to current day calculation
        let calendar = Calendar.current
        let dayOfWeek = calendar.component(.weekday, from: Date())
        let workoutTypes = ["Sprint", "Speed", "Accel", "Recovery", "Time Trial", "Drill", "Rest"]
        return workoutTypes[dayOfWeek % workoutTypes.count]
    }
    
    private func getCurrentWeek() -> Int {
        // Get real current week from UserDefaults or calculate from start date
        let currentWeek = UserDefaults.standard.integer(forKey: "currentWeek")
        return currentWeek > 0 ? currentWeek : 1
    }
    
    private func getCurrentDay() -> Int {
        // Get real current day from UserDefaults
        let currentDay = UserDefaults.standard.integer(forKey: "currentDay")
        return currentDay > 0 ? currentDay : 1
    }
    
    private func getUserPersonalBest() -> Double {
        // Get real personal best from UserDefaults
        let pb = UserDefaults.standard.double(forKey: "personalBest40yd")
        return pb > 0 ? pb : 5.0 // Default fallback
    }
    
    private func getSessionsCompletedThisWeek() -> Int {
        // Calculate from real workout history
        let dataStore = WatchDataStore.shared
        let stats = dataStore.getWorkoutStats(for: .week)
        
        // Get workouts from this week
        let calendar = Calendar.current
        _ = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        
        return stats.totalWorkouts // Simplified - would filter by week in full implementation
    }
    
    private func getTotalSessionsThisWeek() -> Int {
        // Get total sessions planned for current week
        let sessionManager = WatchSessionManager.shared
        let currentWeek = getCurrentWeek()
        
        let weekSessions = sessionManager.trainingSessions.filter { $0.week == currentWeek }
        return weekSessions.count > 0 ? weekSessions.count : 6 // Default 6 sessions per week
    }
    
    private func getWeeklyBest() -> Double {
        // Calculate real weekly best from workout data
        let dataStore = WatchDataStore.shared
        let stats = dataStore.getWorkoutStats(for: .week)
        
        return stats.bestTime > 0 ? stats.bestTime : getUserPersonalBest()
    }
    
    private func getWeeklyAverage() -> Double {
        // Calculate real weekly average from workout data
        let dataStore = WatchDataStore.shared
        let stats = dataStore.getWorkoutStats(for: .week)
        
        return stats.averageWorkoutTime > 0 ? stats.averageWorkoutTime : getUserPersonalBest() + 0.3
    }
    
    // MARK: - Complication Updates
    
    func updateComplications() {
        let server = CLKComplicationServer.sharedInstance()
        
        for complication in server.activeComplications ?? [] {
            server.reloadTimeline(for: complication)
        }
    }
    
    func updateComplication(withIdentifier identifier: String) {
        let server = CLKComplicationServer.sharedInstance()
        
        if let complication = server.activeComplications?.first(where: { $0.identifier == identifier }) {
            server.reloadTimeline(for: complication)
        }
    }
}

// MARK: - Supporting Types

struct ComplicationData {
    let nextWorkoutType: String
    let currentWeek: Int
    let currentDay: Int
    let personalBest: Double
    let sessionsCompleted: Int
    let totalSessions: Int
    let weeklyBest: Double
    let weeklyAverage: Double
}

// MARK: - SwiftUI Integration

@available(watchOS 7.0, *)
struct ComplicationPreview: View {
    var body: some View {
        VStack(spacing: 10) {
            Text("SC40 Complications")
                .font(.headline)
            
            HStack {
                VStack {
                    Text("PB")
                        .font(.caption)
                    Text("4.85s")
                        .font(.title3.bold())
                }
                .frame(width: 60, height: 60)
                .background(Color.blue)
                .cornerRadius(30)
                
                VStack {
                    Text("NEXT")
                        .font(.caption)
                    Text("Sprint")
                        .font(.title3.bold())
                }
                .frame(width: 60, height: 60)
                .background(Color.green)
                .cornerRadius(30)
            }
            
            VStack {
                Text("Weekly Progress")
                    .font(.caption)
                Text("4/6 sessions")
                    .font(.body)
                Text("Best: 4.92s")
                    .font(.caption)
            }
            .padding()
            .background(Color.orange)
            .cornerRadius(10)
        }
        .padding()
    }
}
