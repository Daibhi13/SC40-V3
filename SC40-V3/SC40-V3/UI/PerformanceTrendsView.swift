import SwiftUI
import Charts

struct PerformanceTrendsView: View {
    let weeks: [WeeklyProgram]
    @State private var showShareSheet = false
    @State private var exportData: String = ""
    
    var splitData: [(week: Int, phase: Phase, time: Double)] {
        weeks.enumerated().flatMap { (wIdx, week) in
            week.flatMap { day in
                day.phases.compactMap { phase in
                    guard let t = phase.lastTime else { return nil }
                    return (week: wIdx+1, phase: phase.phase, time: t)
                }
            }
        }
    }
    var fatigueData: [(week: Int, fatigue: Double)] {
        weeks.enumerated().compactMap { (wIdx, week) in
            let fatigue = week.compactMap { $0.hybridAI?.fatigueScore }.average
            return fatigue.map { (week: wIdx+1, fatigue: $0) }
        }
    }
    var pbData: [(week: Int, pb: Double)] {
        weeks.enumerated().compactMap { (wIdx, week) in
            let pb = week.compactMap { $0.phases.compactMap { $0.pb }.min() }.min()
            return pb.map { (week: wIdx+1, pb: $0) }
        }
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Splits Over Time").font(.headline)
                if #available(iOS 16.0, *) {
                    Chart(splitData, id: \ .week) {
                        LineMark(
                            x: .value("Week", $0.week),
                            y: .value("Time", $0.time),
                            series: .value("Phase", $0.phase.rawValue)
                        )
                    }
                    .frame(height: 180)
                } else {
                    Text("Charts are available in iOS 16 and later")
                        .frame(height: 180)
                        .foregroundColor(.secondary)
                }
                Text("Fatigue Trend").font(.headline)
                if #available(iOS 16.0, *) {
                    Chart(fatigueData, id: \ .week) {
                        LineMark(
                            x: .value("Week", $0.week),
                            y: .value("Fatigue", $0.fatigue)
                        )
                    }
                    .frame(height: 120)
                } else {
                    Text("Charts are available in iOS 16 and later")
                        .frame(height: 120)
                        .foregroundColor(.secondary)
                }
                Text("Personal Best Progress").font(.headline)
                if #available(iOS 16.0, *) {
                    Chart(pbData, id: \ .week) {
                        LineMark(
                            x: .value("Week", $0.week),
                            y: .value("PB", $0.pb)
                        )
                    }
                    .frame(height: 120)
                } else {
                    Text("Charts are available in iOS 16 and later")
                        .frame(height: 120)
                        .foregroundColor(.secondary)
                }
                HStack {
                    Button(action: exportCSV) {
                        Label("Export CSV", systemImage: "square.and.arrow.up")
                    }
                    Button(action: exportJSON) {
                        Label("Export JSON", systemImage: "doc.text")
                    }
                }
                .padding(.top)
            }
            .padding()
        }
        .sheet(isPresented: $showShareSheet) {
            ActivityView(activityItems: [exportData])
        }
    }
    func exportCSV() {
        var csv = "Week,Phase,SplitTime\n"
        for row in splitData { csv += "\(row.week),\(row.phase.rawValue),\(row.time)\n" }
        exportData = csv
        showShareSheet = true
    }
    func exportJSON() {
        let dict = [
            "splits": splitData.map { ["week": $0.week, "phase": $0.phase.rawValue, "time": $0.time] },
            "fatigue": fatigueData.map { ["week": $0.week, "fatigue": $0.fatigue] },
            "pb": pbData.map { ["week": $0.week, "pb": $0.pb] }
        ]
        if let data = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted),
           let str = String(data: data, encoding: .utf8) {
            exportData = str
            showShareSheet = true
        }
    }
}

private extension Array where Element == Double {
    var average: Double? { isEmpty ? nil : reduce(0, +) / Double(count) }
}
