import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Share Performance View

struct SharePerformanceView: View {
    @ObservedObject var userProfileVM: UserProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFormat: ShareFormat = .recruitingCard
    @State private var includePersonalBests = true
    @State private var includeTrainingHistory = true
    @State private var includeProgressCharts = true
    @State private var recipientEmail = ""
    @State private var showActivityView = false
    @State private var shareText = ""
    @State private var isGenerating = false
    
    enum ShareFormat: String, CaseIterable, Identifiable {
        case recruitingCard = "Recruiting Card"
        case coachingReport = "Coaching Report"
        case performanceSummary = "Performance Summary"
        case scholarshipPortfolio = "Scholarship Portfolio"
        case csvData = "CSV Data Export"
        case medicalReport = "Medical Assessment"
        
        var id: String { rawValue }
        
        var description: String {
            switch self {
            case .recruitingCard: return "Professional 1-page athlete profile for college recruiters"
            case .coachingReport: return "Detailed technical analysis for coaches and trainers"
            case .performanceSummary: return "Comprehensive performance metrics and trends"
            case .scholarshipPortfolio: return "Complete athletic portfolio for scholarship applications"
            case .csvData: return "Raw performance data for statistical analysis"
            case .medicalReport: return "Biomechanics and injury prevention assessment"
            }
        }
        
        var icon: String {
            switch self {
            case .recruitingCard: return "person.crop.rectangle.fill"
            case .coachingReport: return "chart.bar.doc.horizontal.fill"
            case .performanceSummary: return "speedometer"
            case .scholarshipPortfolio: return "graduationcap.fill"
            case .csvData: return "tablecells.fill"
            case .medicalReport: return "cross.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .recruitingCard: return Color(red: 1.0, green: 0.4, blue: 0.4)
            case .coachingReport: return Color(red: 0.2, green: 0.6, blue: 1.0)
            case .performanceSummary: return Color(red: 0.0, green: 0.8, blue: 0.4)
            case .scholarshipPortfolio: return Color(red: 0.6, green: 0.4, blue: 1.0)
            case .csvData: return Color(red: 0.8, green: 0.6, blue: 0.0)
            case .medicalReport: return Color(red: 1.0, green: 0.6, blue: 0.0)
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
                        EnhancedReportFormatSection(selectedFormat: $selectedFormat)
                        
                        // Include in Report Section
                        IncludeInReportSection(
                            includePersonalBests: $includePersonalBests,
                            includeTrainingHistory: $includeTrainingHistory,
                            includeProgressCharts: $includeProgressCharts
                        )
                        
                        // Send To Section
                        SendToSection(recipientEmail: $recipientEmail)
                        
                        // Generate Button
                        Button(action: generateAndShare) {
                            HStack(spacing: 12) {
                                if isGenerating {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "doc.fill")
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
                        
                        // Professional Format Badge
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
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .sheet(isPresented: $showActivityView) {
            #if canImport(UIKit)
            ActivityViewController(activityItems: createShareItems(), applicationActivities: nil)
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
        case .recruitingCard:
            content = generateRecruitingCardReport()
        case .coachingReport:
            content = generateCoachingReport()
        case .performanceSummary:
            content = generatePerformanceSummaryReport()
        case .scholarshipPortfolio:
            content = generateScholarshipPortfolioReport()
        case .csvData:
            content = generateCSVDataReport()
        case .medicalReport:
            content = generateMedicalReport()
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
}

// MARK: - Activity View Controller for Sharing

#if canImport(UIKit)
struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]?
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif



// MARK: - Supporting Components (moved from EnhancedReportFormatSection for accessibility)

struct IncludeInReportSection: View {
    @Binding var includePersonalBests: Bool
    @Binding var includeTrainingHistory: Bool
    @Binding var includeProgressCharts: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Include in Report")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                ToggleOptionRow(
                    title: "Personal Best Times",
                    subtitle: "Your fastest recorded times",
                    icon: "stopwatch.fill",
                    isOn: $includePersonalBests
                )
                
                ToggleOptionRow(
                    title: "Training History",
                    subtitle: "Complete session records",
                    icon: "calendar.badge.clock",
                    isOn: $includeTrainingHistory
                )
                
                ToggleOptionRow(
                    title: "Progress Charts",
                    subtitle: "Visual performance trends",
                    icon: "chart.line.uptrend.xyaxis",
                    isOn: $includeProgressCharts
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct ToggleOptionRow: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(isOn ? .green : .white.opacity(0.5))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: .green))
        }
        .padding(.vertical, 8)
    }
}

struct SendToSection: View {
    @Binding var recipientEmail: String
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Send To")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                TextField("Coach or recruiter email", text: $recipientEmail)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                
                HStack(spacing: 12) {
                    Button("Share via Messages") {
                        // Handle Messages sharing
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(Color.blue.opacity(0.8))
                    .cornerRadius(8)
                    
                    Button("Save to Files") {
                        // Handle Files saving
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(Color.orange.opacity(0.8))
                    .cornerRadius(8)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

#Preview {
    SharePerformanceView(userProfileVM: UserProfileViewModel())
}
