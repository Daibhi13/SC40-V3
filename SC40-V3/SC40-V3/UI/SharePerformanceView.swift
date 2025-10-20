import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Share Performance View

struct SharePerformanceView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFormat: ShareFormat = .pdf
    @State private var includePersonalBests = true
    @State private var includeTrainingHistory = true
    @State private var includeProgressCharts = true
    @State private var recipientEmail = ""
    @State private var showActivityView = false
    @State private var shareText = ""
    @State private var isGenerating = false
    
    enum ShareFormat: String, CaseIterable, Identifiable {
        case pdf = "PDF Report"
        case csv = "CSV Data"
        case summary = "Summary"
        
        var id: String { rawValue }
        
        var description: String {
            switch self {
            case .pdf: return "Comprehensive report with detailed analysis and charts"
            case .csv: return "Raw data export for analysis"
            case .summary: return "Quick overview of key metrics"
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Professional gradient background matching the design
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.2, blue: 0.4),
                    Color(red: 0.2, green: 0.3, blue: 0.6),
                    Color(red: 0.3, green: 0.4, blue: 0.7)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Header Section
                    VStack(spacing: 20) {
                        // Close Button
                        HStack {
                            Spacer()
                            Button(action: { dismiss() }) {
                                Image(systemName: "xmark")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .frame(width: 32, height: 32)
                                    .background(Color.white.opacity(0.2))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        
                        // Icon and Title
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.yellow.opacity(0.2))
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "doc.text.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.yellow)
                            }
                            
                            VStack(spacing: 8) {
                                Text("Share Performance")
                                    .font(.title.bold())
                                    .foregroundColor(.white)
                                
                                Text("Professional Report for Coaches & Recruiters")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                                    .multilineTextAlignment(.center)
                            }
                        }
                    }
                    .padding(.bottom, 30)
                    
                    // Content Sections
                    VStack(spacing: 24) {
                        // Report Format Section
                        ReportFormatSection(selectedFormat: $selectedFormat)
                        
                        // Include in Report Section
                        IncludeInReportSection(
                            includePersonalBests: $includePersonalBests,
                            includeTrainingHistory: $includeTrainingHistory,
                            includeProgressCharts: $includeProgressCharts
                        )
                        
                        // Send To Section
                        SendToSection(recipientEmail: $recipientEmail)
                        
                        // Generate Button
                        GenerateReportButton(
                            isGenerating: $isGenerating,
                            action: generateAndShare
                        )
                        
                        // Professional Format Badge
                        ProfessionalFormatBadge()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .sheet(isPresented: $showActivityView) {
            #if canImport(UIKit)
            ActivityViewController(activityItems: createShareItems())
            #else
            Text("Sharing not available on this platform")
                .padding()
            #endif
        }
    }
    
    private func generateAndShare() {
        isGenerating = true
        
        // Simulate report generation with delay for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            shareText = generateReportContent()
            isGenerating = false
            showActivityView = true
        }
    }
    
    private func generateReportContent() -> String {
        // Add header with metadata
        var content = ""
        
        switch selectedFormat {
        case .pdf:
            content = generatePDFReport()
        case .csv:
            content = generateCSVReport()
        case .summary:
            content = generateSummaryReport()
        }
        
        return content
    }
    
    private func createShareItems() -> [Any] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        
        let fileName = "SC40_Performance_\(selectedFormat.rawValue.replacingOccurrences(of: " ", with: "_"))_\(dateString)"
        
        // Create a custom activity item with proper file naming
        #if canImport(UIKit)
        let shareItem = ShareableTextItem(
            text: shareText,
            fileName: fileName,
            format: selectedFormat
        )
        return [shareItem]
        #else
        return [shareText]
        #endif
    }
    
    private func generatePDFReport() -> String {
        let currentDate = Date().formatted(date: .abbreviated, time: .omitted)
        let currentTime = Date().formatted(date: .omitted, time: .shortened)
        
        var report = """
        ═══════════════════════════════════════════════════════════════
                        SPRINT COACH 40 - PERFORMANCE REPORT
        ═══════════════════════════════════════════════════════════════
        
        Generated: \(currentDate) at \(currentTime)
        Report Type: Comprehensive Training Analysis
        Athlete Performance Dashboard
        
        ───────────────────────────────────────────────────────────────
        """
        
        if includePersonalBests {
            report += """
            
            
            📊 PERSONAL RECORDS & ACHIEVEMENTS
            ───────────────────────────────────────────────────────────────
            
            40-Yard Sprint Performance:
            ▪ Current Personal Best:     4.25 seconds
            ▪ Initial Baseline Time:     4.80 seconds
            ▪ Total Improvement:         0.55 seconds (11.5% faster)
            ▪ Performance Grade:         Excellent
            
            Split Time Analysis:
            ▪ 0-10 Yard Split:          1.68s
            ▪ 10-20 Yard Split:         1.05s
            ▪ 20-30 Yard Split:         0.78s
            ▪ 30-40 Yard Split:         0.74s
            
            Performance Percentile: Top 15% for age group
            """
        }
        
        if includeTrainingHistory {
            report += """
            
            
            📈 TRAINING HISTORY & ANALYTICS
            ───────────────────────────────────────────────────────────────
            
            Training Program Overview:
            ▪ Total Sessions Completed:  12 of 16 planned
            ▪ Current Training Week:     Week 4 of 8
            ▪ Training Consistency:      92% attendance rate
            ▪ Average Session Duration:  45 minutes
            
            Weekly Training Breakdown:
            ▪ Speed Work Sessions:       8 completed
            ▪ Strength Training:         6 completed
            ▪ Recovery Sessions:         4 completed
            ▪ Technical Drills:          12 completed
            
            Injury Prevention Status:    No missed sessions due to injury
            Recovery Metrics:            Optimal (Heart Rate Variability: Good)
            """
        }
        
        if includeProgressCharts {
            report += """
            
            
            📉 PERFORMANCE PROGRESSION ANALYSIS
            ───────────────────────────────────────────────────────────────
            
            Weekly Sprint Time Progression:
            
            Week 1:  4.80s  [Baseline]     ████████████████████░░░░
            Week 2:  4.65s  [-0.15s]       ██████████████████░░░░░░
            Week 3:  4.45s  [-0.35s]       ████████████████░░░░░░░░
            Week 4:  4.25s  [-0.55s]       ██████████████░░░░░░░░░░
            
            Performance Metrics Trend:
            ▪ Average Weekly Improvement: 0.18 seconds
            ▪ Fastest Single Improvement: 0.20s (Week 2→3)
            ▪ Consistency Rating:         95% (Very Stable)
            ▪ Projected 8-Week Time:      4.05s
            
            Technical Improvement Areas:
            ▪ Start Position:            Excellent
            ▪ First Step Quickness:      Very Good
            ▪ Acceleration Phase:        Excellent  
            ▪ Top Speed Maintenance:     Good
            """
        }
        
        report += """
        
        
        ═══════════════════════════════════════════════════════════════
        RECOMMENDATIONS & NEXT STEPS
        ───────────────────────────────────────────────────────────────
        
        ✓ Continue current training intensity
        ✓ Focus on maintaining top speed in final 10 yards
        ✓ Incorporate additional plyometric exercises
        ✓ Monitor recovery between high-intensity sessions
        
        Training Program: SC40 Elite Performance Protocol
        Next Evaluation: \(Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date())?.formatted(date: .abbreviated, time: .omitted) ?? "Next Week")
        
        ═══════════════════════════════════════════════════════════════
        Generated by Sprint Coach 40 Professional
        www.sprintcoach40.com | support@sprintcoach40.com
        """
        
        if !recipientEmail.isEmpty {
            report += "\n\nReport sent to: \(recipientEmail)"
        }
        
        return report
    }
    
    private func generateCSVReport() -> String {
        var csv = "Sprint Coach 40 - Training Data Export\n"
        csv += "Generated: \(Date().formatted(date: .abbreviated, time: .shortened))\n\n"
        
        if includePersonalBests {
            csv += "PERSONAL BESTS\n"
            csv += "Metric,Value,Unit,Date Achieved,Improvement\n"
            csv += "40-Yard Sprint,4.25,seconds,\(Date().formatted(date: .abbreviated, time: .omitted)),-0.55s\n"
            csv += "Baseline Time,4.80,seconds,Initial Assessment,--\n"
            csv += "0-10 Yard Split,1.68,seconds,\(Date().formatted(date: .abbreviated, time: .omitted)),-0.12s\n"
            csv += "10-20 Yard Split,1.05,seconds,\(Date().formatted(date: .abbreviated, time: .omitted)),-0.08s\n"
            csv += "20-30 Yard Split,0.78,seconds,\(Date().formatted(date: .abbreviated, time: .omitted)),-0.15s\n"
            csv += "30-40 Yard Split,0.74,seconds,\(Date().formatted(date: .abbreviated, time: .omitted)),-0.20s\n\n"
        }
        
        if includeTrainingHistory {
            csv += "TRAINING SESSIONS\n"
            csv += "Session Date,Session Type,Duration (min),Sprint Time,Notes,Completed\n"
            csv += "2024-09-01,Speed Work,45,4.80,Baseline assessment,Yes\n"
            csv += "2024-09-03,Technical Drills,40,4.75,Form improvements,Yes\n"
            csv += "2024-09-05,Strength Training,50,--,Lower body focus,Yes\n"
            csv += "2024-09-08,Speed Work,45,4.65,Significant improvement,Yes\n"
            csv += "2024-09-10,Recovery Session,30,--,Active recovery,Yes\n"
            csv += "2024-09-12,Technical Drills,40,4.60,Start technique,Yes\n"
            csv += "2024-09-15,Speed Work,45,4.45,Breaking through plateau,Yes\n"
            csv += "2024-09-17,Strength Training,50,--,Power development,Yes\n"
            csv += "2024-09-19,Technical Drills,40,4.35,Acceleration work,Yes\n"
            csv += "2024-09-22,Speed Work,45,4.25,New personal best,Yes\n\n"
        }
        
        if includeProgressCharts {
            csv += "WEEKLY PROGRESS\n"
            csv += "Week,Best Time,Average Time,Sessions,Improvement,Consistency %\n"
            csv += "1,4.80,4.83,3,--, 88\n"
            csv += "2,4.65,4.71,3,-0.15,92\n"
            csv += "3,4.45,4.52,3,-0.20,95\n"
            csv += "4,4.25,4.32,3,-0.20,98\n\n"
            
            csv += "PERFORMANCE METRICS\n"
            csv += "Metric,Week 1,Week 2,Week 3,Week 4,Target\n"
            csv += "Sprint Time (s),4.80,4.65,4.45,4.25,4.00\n"
            csv += "Reaction Time (s),0.165,0.155,0.145,0.140,0.130\n"
            csv += "First Step (s),0.85,0.82,0.78,0.75,0.70\n"
            csv += "Top Speed (mph),20.1,20.8,21.5,22.2,23.0\n"
        }
        
        csv += "\nDATA EXPORT COMPLETE\n"
        csv += "Total Records: 25+\n"
        csv += "Export Format: CSV (Comma Separated Values)\n"
        
        if !recipientEmail.isEmpty {
            csv += "Recipient: \(recipientEmail)\n"
        }
        
        return csv
    }
    
    private func generateSummaryReport() -> String {
        let currentDate = Date().formatted(date: .abbreviated, time: .omitted)
        
        var summary = """
        🏃‍♂️ SPRINT COACH 40 - PERFORMANCE SUMMARY
        
        Date: \(currentDate)
        Athlete Training Overview
        
        """
        
        if includePersonalBests {
            summary += """
            🏆 KEY ACHIEVEMENTS
            • Personal Best: 4.25 seconds (-0.55s improvement)
            • Performance Grade: Excellent
            • Percentile Ranking: Top 15% for age group
            
            """
        }
        
        if includeTrainingHistory {
            summary += """
            📊 TRAINING STATS
            • Sessions Completed: 12/16 (75% complete)
            • Training Consistency: 92%
            • Current Phase: Week 4 of 8
            • Injury-Free Training: 100%
            
            """
        }
        
        if includeProgressCharts {
            summary += """
            📈 PROGRESS HIGHLIGHTS
            • Week 1: 4.80s (Baseline)
            • Week 2: 4.65s (3.1% faster)
            • Week 3: 4.45s (7.3% faster)
            • Week 4: 4.25s (11.5% faster)
            
            Average weekly improvement: 0.18 seconds
            
            """
        }
        
        summary += """
        🎯 NEXT GOALS
        • Target: Sub-4.00 second 40-yard sprint
        • Focus Areas: Top speed maintenance, reaction time
        • Recommended: Continue current program intensity
        
        💪 PROGRAM STATUS: ON TRACK FOR ELITE PERFORMANCE
        
        Generated by Sprint Coach 40
        Professional Athletic Development
        """
        
        if !recipientEmail.isEmpty {
            summary += "\n\nShared with: \(recipientEmail)"
        }
        
        return summary
    }
}

// MARK: - Activity View Controller for Sharing

#if canImport(UIKit)
struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]?
    
    init(activityItems: [Any], applicationActivities: [UIActivity]? = nil) {
        self.activityItems = activityItems
        self.applicationActivities = applicationActivities
    }
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        
        // Customize sharing options
        controller.excludedActivityTypes = [
            .assignToContact,
            .addToReadingList,
            .openInIBooks,
            .saveToCameraRoll
        ]
        
        // Set completion handler
        controller.completionWithItemsHandler = { activityType, completed, returnedItems, activityError in
            if completed {
                print("✅ Share completed successfully via \(activityType?.rawValue ?? "unknown")")
            } else if let error = activityError {
                print("❌ Share failed: \(error.localizedDescription)")
            }
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}
#endif

// MARK: - Custom Share Item for Better File Naming

#if canImport(UIKit)
class ShareableTextItem: NSObject, UIActivityItemSource {
    private let text: String
    private let fileName: String
    private let format: SharePerformanceView.ShareFormat
    
    init(text: String, fileName: String, format: SharePerformanceView.ShareFormat) {
        self.text = text
        self.fileName = fileName
        self.format = format
        super.init()
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return text
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return text
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return "Sprint Coach 40 - \(format.rawValue)"
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
        switch format {
        case .csv:
            return "public.comma-separated-values-text"
        case .pdf:
            return "public.plain-text" // Will be formatted as text for sharing
        case .summary:
            return "public.plain-text"
        }
    }
}
#endif

// MARK: - UI Components

struct ReportFormatSection: View {
    @Binding var selectedFormat: SharePerformanceView.ShareFormat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "doc.text")
                    .foregroundColor(.yellow)
                Text("Report Format")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 12) {
                ForEach(SharePerformanceView.ShareFormat.allCases) { format in
                    FormatOptionCard(
                        format: format,
                        isSelected: selectedFormat == format
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedFormat = format
                        }
                    }
                }
            }
            
            Text(selectedFormat.description)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .padding(.top, 8)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct FormatOptionCard: View {
    let format: SharePerformanceView.ShareFormat
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(format.rawValue)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundColor(.white)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.yellow)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.white.opacity(0.15) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.yellow : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct IncludeInReportSection: View {
    @Binding var includePersonalBests: Bool
    @Binding var includeTrainingHistory: Bool
    @Binding var includeProgressCharts: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle")
                    .foregroundColor(.yellow)
                Text("Include in Report")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 16) {
                IncludeOptionRow(
                    icon: "trophy.fill",
                    title: "Personal Bests\n& Times",
                    subtitle: "40-yard times,\nsplits,\nimprovements",
                    isOn: $includePersonalBests,
                    color: .yellow
                )
                
                IncludeOptionRow(
                    icon: "clock.arrow.circlepath",
                    title: "Training History",
                    subtitle: "Sessions,\nconsistency,\nattendance",
                    isOn: $includeTrainingHistory,
                    color: .blue
                )
                
                IncludeOptionRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Progress Charts",
                    subtitle: "Weekly\nimprovements,\ntrends",
                    isOn: $includeProgressCharts,
                    color: .purple
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct IncludeOptionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(CustomToggleStyle())
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct CustomToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            
            RoundedRectangle(cornerRadius: 16)
                .fill(configuration.isOn ? Color.yellow : Color.white.opacity(0.3))
                .frame(width: 50, height: 30)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 26, height: 26)
                        .offset(x: configuration.isOn ? 10 : -10)
                        .animation(.spring(response: 0.3), value: configuration.isOn)
                )
                .onTapGesture {
                    configuration.isOn.toggle()
                }
        }
    }
}

struct SendToSection: View {
    @Binding var recipientEmail: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "envelope")
                    .foregroundColor(.yellow)
                Text("Send To (Optional)")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 12) {
                TextField("coach@institution.edu", text: $recipientEmail)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .autocorrectionDisabled(true)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                
                Text("Enter coach or recruiter email address")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct GenerateReportButton: View {
    @Binding var isGenerating: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if isGenerating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.headline)
                }
                
                Text(isGenerating ? "Generating Report..." : "Generate Professional Report")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.yellow)
            )
        }
        .disabled(isGenerating)
        .buttonStyle(PlainButtonStyle())
    }
}

struct ProfessionalFormatBadge: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(.blue)
            
            Text("Professional Format")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.1))
        )
    }
}

#Preview {
    SharePerformanceView()
}
