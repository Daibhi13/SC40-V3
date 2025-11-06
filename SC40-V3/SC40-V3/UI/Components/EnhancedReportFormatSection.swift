import SwiftUI

struct EnhancedReportFormatSection: View {
    @Binding var selectedFormat: SharePerformanceView.ShareFormat
    
    var body: some View {
        VStack(spacing: 20) {
            // Section Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Report Format")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Choose the format that best fits your needs")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
            }
            
            // Format Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(SharePerformanceView.ShareFormat.allCases) { format in
                    ReportFormatCard(
                        format: format,
                        isSelected: selectedFormat == format
                    ) {
                        selectedFormat = format
                    }
                }
            }
            
            // Selected Format Details
            SelectedFormatDetailsCard(format: selectedFormat)
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

struct ReportFormatCard: View {
    let format: SharePerformanceView.ShareFormat
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(format.color.opacity(isSelected ? 0.3 : 0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: format.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(format.color)
                }
                
                // Title
                Text(format.rawValue)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                // Selection Indicator
                if isSelected {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(format.color)
                        
                        Text("Selected")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(format.color)
                    }
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? format.color.opacity(0.1) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? format.color : Color.white.opacity(0.2),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SelectedFormatDetailsCard: View {
    let format: SharePerformanceView.ShareFormat
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: format.icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(format.color)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(format.rawValue)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(format.description)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
            }
            
            // Format Features
            VStack(spacing: 12) {
                HStack {
                    Text("What's Included:")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], alignment: .leading, spacing: 8) {
                    ForEach(getFormatFeatures(for: format), id: \.self) { feature in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(format.color)
                            
                            Text(feature)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                        }
                    }
                }
            }
            
            // Format Specifications
            FormatSpecificationsView(format: format)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(format.color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(format.color.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private func getFormatFeatures(for format: SharePerformanceView.ShareFormat) -> [String] {
        switch format {
        case .recruitingCard:
            return [
                "Personal Information",
                "Season Best Times",
                "Performance Chart",
                "Athletic Profile",
                "Contact Details",
                "Achievement Highlights"
            ]
        case .coachingReport:
            return [
                "Technical Analysis",
                "Training Recommendations",
                "Biomechanics Data",
                "Performance Trends",
                "Injury Risk Assessment",
                "Periodization Plan"
            ]
        case .performanceSummary:
            return [
                "Sprint Time Analysis",
                "Progress Tracking",
                "Comparative Data",
                "Goal Achievement",
                "Statistical Overview",
                "Trend Visualization"
            ]
        case .scholarshipPortfolio:
            return [
                "Athletic Resume",
                "Academic Records",
                "Performance Portfolio",
                "Reference Letters",
                "Video Highlights",
                "Award History"
            ]
        case .csvData:
            return [
                "Raw Sprint Times",
                "Training Sessions",
                "Performance Metrics",
                "Date Timestamps",
                "Weather Conditions",
                "Equipment Used"
            ]
        case .medicalReport:
            return [
                "Injury History",
                "Biomechanics Analysis",
                "Recovery Metrics",
                "Load Management",
                "Risk Factors",
                "Medical Recommendations"
            ]
        }
    }
}

struct FormatSpecificationsView: View {
    let format: SharePerformanceView.ShareFormat
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Format Details:")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
            }
            
            HStack(spacing: 20) {
                SpecificationItem(
                    icon: "doc.fill",
                    title: "Format",
                    value: getFileFormat()
                )
                
                SpecificationItem(
                    icon: "clock.fill",
                    title: "Generation",
                    value: getGenerationTime()
                )
                
                SpecificationItem(
                    icon: "arrow.down.circle.fill",
                    title: "Size",
                    value: getEstimatedSize()
                )
            }
        }
    }
    
    private func getFileFormat() -> String {
        switch format {
        case .recruitingCard, .scholarshipPortfolio, .performanceSummary, .coachingReport, .medicalReport:
            return "PDF"
        case .csvData:
            return "CSV"
        }
    }
    
    private func getGenerationTime() -> String {
        switch format {
        case .recruitingCard:
            return "~30s"
        case .coachingReport, .medicalReport:
            return "~60s"
        case .performanceSummary:
            return "~45s"
        case .scholarshipPortfolio:
            return "~90s"
        case .csvData:
            return "~10s"
        }
    }
    
    private func getEstimatedSize() -> String {
        switch format {
        case .recruitingCard:
            return "1-2 MB"
        case .coachingReport, .medicalReport:
            return "3-5 MB"
        case .performanceSummary:
            return "2-3 MB"
        case .scholarshipPortfolio:
            return "5-10 MB"
        case .csvData:
            return "< 1 MB"
        }
    }
}

struct SpecificationItem: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.7))
            
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
            
            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Supporting Components for SharePerformanceView

// Note: IncludeInReportSection, ToggleOptionRow, and SendToSection components
// are now defined in SharePerformanceView.swift to avoid duplicate declarations

#Preview {
    ZStack {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.1, green: 0.2, blue: 0.4),
                Color(red: 0.2, green: 0.3, blue: 0.6)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        ScrollView {
            EnhancedReportFormatSection(selectedFormat: .constant(.recruitingCard))
                .padding()
        }
    }
}
