import SwiftUI

struct ReportGeneratorView: View {
    let reportType: ProfessionalReportsCard.ReportType
    @Environment(\.dismiss) private var dismiss
    @State private var isGenerating = false
    @State private var generationProgress: Double = 0.0
    @State private var showShareSheet = false
    @State private var generatedReport: GeneratedReport?
    
    struct GeneratedReport {
        let title: String
        let content: String
        let format: String
        let size: String
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
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
                    VStack(spacing: 24) {
                        // Header
                        ReportHeaderSection(reportType: reportType)
                        
                        // Generation Status
                        if isGenerating {
                            GenerationProgressCard(progress: generationProgress)
                        } else if let report = generatedReport {
                            GeneratedReportCard(report: report) {
                                showShareSheet = true
                            }
                        } else {
                            ReportPreviewCard(reportType: reportType) {
                                startGeneration()
                            }
                        }
                        
                        // Sample Data Preview
                        SampleDataPreview(reportType: reportType)
                    }
                    .padding()
                }
            }
            .navigationTitle("Report Generator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let report = generatedReport {
                ReportShareSheet(items: [report.content])
            }
        }
    }
    
    private func startGeneration() {
        isGenerating = true
        generationProgress = 0.0
        
        // Simulate report generation with progress
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            generationProgress += 0.05
            
            if generationProgress >= 1.0 {
                timer.invalidate()
                completeGeneration()
            }
        }
    }
    
    private func completeGeneration() {
        isGenerating = false
        generatedReport = GeneratedReport(
            title: "\(reportType.rawValue) - Sprint Coach 40",
            content: generateReportContent(),
            format: "PDF",
            size: "2.3 MB"
        )
    }
    
    private func generateReportContent() -> String {
        return """
        SPRINT COACH 40 - \(reportType.rawValue.uppercased())
        
        Generated: \(Date().formatted())
        
        ATHLETE PROFILE
        Name: John Athlete
        Age: 20
        Event: 100m Sprint
        
        PERFORMANCE SUMMARY
        Personal Best: 10.45s
        Season Best: 10.52s
        Training Sessions: 156
        
        [Report content would be generated here based on actual data]
        """
    }
}

struct ReportHeaderSection: View {
    let reportType: ProfessionalReportsCard.ReportType
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(reportType.color.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: reportType.icon)
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(reportType.color)
            }
            
            VStack(spacing: 8) {
                Text(reportType.rawValue)
                    .font(.title.bold())
                    .foregroundColor(.white)
                
                Text(reportType.description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
        }
    }
}

struct GenerationProgressCard: View {
    let progress: Double
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Generating Report...")
                .font(.headline)
                .foregroundColor(.white)
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .green))
                .scaleEffect(y: 2)
            
            Text("\(Int(progress * 100))% Complete")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
        )
    }
}

struct GeneratedReportCard: View {
    let report: ReportGeneratorView.GeneratedReport
    let onShare: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                
                VStack(alignment: .leading) {
                    Text("Report Generated")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("\(report.format) • \(report.size)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
            }
            
            Button(action: onShare) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Report")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
        )
    }
}

struct ReportPreviewCard: View {
    let reportType: ProfessionalReportsCard.ReportType
    let onGenerate: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Ready to Generate")
                .font(.headline)
                .foregroundColor(.white)
            
            Button(action: onGenerate) {
                HStack {
                    Image(systemName: "doc.badge.plus")
                    Text("Generate \(reportType.rawValue)")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(reportType.color)
                .cornerRadius(10)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
        )
    }
}

struct SampleDataPreview: View {
    let reportType: ProfessionalReportsCard.ReportType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Report Preview")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("This report will include:")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            
            ForEach(getSampleData(), id: \.self) { item in
                HStack {
                    Image(systemName: "checkmark")
                        .foregroundColor(.green)
                    Text(item)
                        .foregroundColor(.white.opacity(0.9))
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.2))
        )
    }
    
    private func getSampleData() -> [String] {
        switch reportType {
        case .recruiting:
            return ["Personal Best Times", "Season Progress", "Athletic Profile", "Performance Charts"]
        case .coaching:
            return ["Technical Analysis", "Training Recommendations", "Performance Trends"]
        case .performance:
            return ["Sprint Times", "Comparative Analysis", "Goal Tracking"]
        case .medical:
            return ["Injury Assessment", "Biomechanics Report", "Recovery Data"]
        case .scholarship:
            return ["Athletic Resume", "Performance Portfolio", "Academic Records"]
        }
    }
}

struct ReportShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
