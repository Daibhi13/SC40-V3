import SwiftUI

// MARK: - Professional Reports Card Component

struct ProfessionalReportsCard: View {
    @State private var selectedReportType: ReportType = .recruiting
    @State private var showReportGenerator = false
    @State private var showShareView = false
    
    enum ReportType: String, CaseIterable, Identifiable {
        case recruiting = "Recruiting Card"
        case coaching = "Coaching Analysis"
        case performance = "Performance Summary"
        case medical = "Medical Report"
        case scholarship = "Scholarship Portfolio"
        
        var id: String { rawValue }
        
        var description: String {
            switch self {
            case .recruiting:
                return "Professional 1-page athlete profile for college recruiters"
            case .coaching:
                return "Detailed technical analysis for coaches and trainers"
            case .performance:
                return "Comprehensive performance metrics and trends"
            case .medical:
                return "Injury prevention and biomechanics assessment"
            case .scholarship:
                return "Complete athletic portfolio for scholarship applications"
            }
        }
        
        var icon: String {
            switch self {
            case .recruiting: return "person.crop.rectangle.fill"
            case .coaching: return "chart.bar.doc.horizontal.fill"
            case .performance: return "speedometer"
            case .medical: return "cross.fill"
            case .scholarship: return "graduationcap.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .recruiting: return Color(red: 1.0, green: 0.4, blue: 0.4)
            case .coaching: return Color(red: 0.2, green: 0.6, blue: 1.0)
            case .performance: return Color(red: 0.0, green: 0.8, blue: 0.4)
            case .medical: return Color(red: 1.0, green: 0.6, blue: 0.0)
            case .scholarship: return Color(red: 0.6, green: 0.4, blue: 1.0)
            }
        }
        
        var formats: [ReportFormat] {
            switch self {
            case .recruiting:
                return [.pdf, .image, .web]
            case .coaching:
                return [.pdf, .csv, .json]
            case .performance:
                return [.pdf, .csv, .summary]
            case .medical:
                return [.pdf, .medical]
            case .scholarship:
                return [.pdf, .portfolio, .web]
            }
        }
    }
    
    enum ReportFormat: String, CaseIterable, Identifiable {
        case pdf = "PDF Document"
        case csv = "CSV Data"
        case json = "JSON Export"
        case image = "High-Res Image"
        case web = "Web Link"
        case summary = "Text Summary"
        case medical = "Medical Format"
        case portfolio = "Portfolio Package"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .pdf: return "doc.fill"
            case .csv: return "tablecells.fill"
            case .json: return "curlybraces"
            case .image: return "photo.fill"
            case .web: return "link"
            case .summary: return "text.alignleft"
            case .medical: return "cross.case.fill"
            case .portfolio: return "folder.fill"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.4))
                    
                    Text("Professional Reports")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                
                Text("Generate professional reports for coaches, recruiters, and institutions")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.leading)
            }
            
            // Report Type Selector
            VStack(spacing: 16) {
                HStack {
                    Text("Report Type")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(ReportType.allCases) { reportType in
                        ReportTypeCard(
                            reportType: reportType,
                            isSelected: selectedReportType == reportType
                        ) {
                            selectedReportType = reportType
                        }
                    }
                }
            }
            
            // Selected Report Details
            SelectedReportDetailsCard(reportType: selectedReportType)
            
            // Format Options
            FormatOptionsSection(
                reportType: selectedReportType,
                onGenerate: { format in
                    generateReport(type: selectedReportType, format: format)
                }
            )
            
            // Quick Actions
            QuickActionsSection(
                onShare: { showShareView = true },
                onPreview: { showReportGenerator = true }
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .sheet(isPresented: $showReportGenerator) {
            ReportGeneratorView(reportType: selectedReportType)
        }
        .sheet(isPresented: $showShareView) {
            SharePerformanceView(userProfileVM: UserProfileViewModel())
        }
    }
    
    private func generateReport(type: ReportType, format: ReportFormat) {
        // Implement report generation logic
        print("Generating \(type.rawValue) in \(format.rawValue) format")
        showReportGenerator = true
    }
}

// MARK: - Supporting Components

struct ReportTypeCard: View {
    let reportType: ProfessionalReportsCard.ReportType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(reportType.color.opacity(isSelected ? 0.3 : 0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: reportType.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(reportType.color)
                }
                
                Text(reportType.rawValue)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? reportType.color.opacity(0.1) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? reportType.color : Color.white.opacity(0.2),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SelectedReportDetailsCard: View {
    let reportType: ProfessionalReportsCard.ReportType
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: reportType.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(reportType.color)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(reportType.rawValue)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(reportType.description)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
            }
            
            // Report Features
            VStack(spacing: 8) {
                HStack {
                    Text("Includes:")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                }
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], alignment: .leading, spacing: 6) {
                    ForEach(getReportFeatures(for: reportType), id: \.self) { feature in
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(reportType.color)
                            
                            Text(feature)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                            
                            Spacer()
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(reportType.color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(reportType.color.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private func getReportFeatures(for type: ProfessionalReportsCard.ReportType) -> [String] {
        switch type {
        case .recruiting:
            return ["Personal Bests", "Season Progress", "Athletic Profile", "Contact Info", "Performance Charts", "Video Highlights"]
        case .coaching:
            return ["Technical Analysis", "Biomechanics", "Training Load", "Injury Risk", "Recommendations", "Periodization"]
        case .performance:
            return ["Sprint Times", "Trend Analysis", "Comparative Data", "Goal Tracking", "Seasonal Stats", "PR History"]
        case .medical:
            return ["Injury History", "Biomechanics", "Risk Assessment", "Recovery Data", "Load Management", "Recommendations"]
        case .scholarship:
            return ["Athletic Resume", "Performance Portfolio", "Academic Info", "References", "Video Package", "Awards"]
        }
    }
}

struct FormatOptionsSection: View {
    let reportType: ProfessionalReportsCard.ReportType
    let onGenerate: (ProfessionalReportsCard.ReportFormat) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Export Format")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 10) {
                ForEach(reportType.formats) { format in
                    Button(action: { onGenerate(format) }) {
                        VStack(spacing: 6) {
                            Image(systemName: format.icon)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(reportType.color)
                            
                            Text(format.rawValue)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(reportType.color.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

struct QuickActionsSection: View {
    let onShare: () -> Void
    let onPreview: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onPreview) {
                HStack(spacing: 8) {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 14, weight: .semibold))
                    
                    Text("Preview")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.2))
                )
            }
            
            Button(action: onShare) {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up.fill")
                        .font(.system(size: 14, weight: .semibold))
                    
                    Text("Share Performance")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
                .background(
                    LinearGradient(
                        colors: [Color(red: 1.0, green: 0.4, blue: 0.4), Color(red: 1.0, green: 0.5, blue: 0.5)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(10)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
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
            ProfessionalReportsCard()
                .padding()
        }
    }
}
