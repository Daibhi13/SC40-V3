import Foundation
import MessageUI
import Messages
import SwiftUI
import Combine
import UIKit

/// Messages integration for sharing workout results and challenges via iMessage
@MainActor
class MessagesManager: NSObject, ObservableObject {
    static let shared = MessagesManager()
    
    @Published var canSendMessages = false
    @Published var canSendMail = false
    
    override init() {
        super.init()
        checkAvailability()
    }
    
    private func checkAvailability() {
        canSendMessages = MFMessageComposeViewController.canSendText()
        canSendMail = MFMailComposeViewController.canSendMail()
    }
    
    // MARK: - iMessage Sharing
    
    func shareWorkoutResult(
        sprintTime: Double,
        improvement: Double?,
        weekNumber: Int,
        dayNumber: Int
    ) {
        guard canSendMessages else { return }
        
        let messageVC = MFMessageComposeViewController()
        messageVC.messageComposeDelegate = self
        
        // Create engaging message content
        var messageText = "🏃‍♂️ Just crushed my 40-yard sprint!\n\n"
        messageText += "⏱️ Time: \(String(format: "%.2f", sprintTime)) seconds\n"
        messageText += "📅 Week \(weekNumber), Day \(dayNumber)\n"
        
        if let improvement = improvement, improvement > 0 {
            messageText += "📈 Improved by \(String(format: "%.2f", improvement))s!\n"
        }
        
        messageText += "\n💪 Training with SC40 Sprint Coach\n"
        messageText += "Want to race? Download the app and let's see who's faster! 🚀"
        
        messageVC.body = messageText
        
        // Add workout summary as attachment if possible
        if let summaryImage = generateWorkoutSummaryImage(
            sprintTime: sprintTime,
            improvement: improvement,
            weekNumber: weekNumber,
            dayNumber: dayNumber
        ) {
            if let imageData = summaryImage.pngData() {
                messageVC.addAttachmentData(
                    imageData,
                    typeIdentifier: "public.png",
                    filename: "SC40_Workout_Summary.png"
                )
            }
        }
        
        presentViewController(messageVC)
    }
    
    func sharePersonalRecord(
        newRecord: Double,
        previousRecord: Double,
        improvement: Double
    ) {
        guard canSendMessages else { return }
        
        let messageVC = MFMessageComposeViewController()
        messageVC.messageComposeDelegate = self
        
        let messageText = """
        🎉 NEW PERSONAL RECORD! 🎉
        
        🏃‍♂️ 40-Yard Sprint: \(String(format: "%.2f", newRecord))s
        📈 Previous: \(String(format: "%.2f", previousRecord))s
        ⚡ Improved by: \(String(format: "%.2f", improvement))s
        
        💪 All thanks to SC40 Sprint Coach training!
        
        Think you can beat my time? 😏
        Download SC40 and prove it! 🚀
        """
        
        messageVC.body = messageText
        
        // Add celebration image
        if let celebrationImage = generateCelebrationImage(newRecord: newRecord, improvement: improvement) {
            if let imageData = celebrationImage.pngData() {
                messageVC.addAttachmentData(
                    imageData,
                    typeIdentifier: "public.png",
                    filename: "SC40_Personal_Record.png"
                )
            }
        }
        
        presentViewController(messageVC)
    }
    
    func shareWeeklyProgress(
        weekNumber: Int,
        sessionsCompleted: Int,
        totalSessions: Int,
        averageTime: Double,
        bestTime: Double
    ) {
        guard canSendMessages else { return }
        
        let messageVC = MFMessageComposeViewController()
        messageVC.messageComposeDelegate = self
        
        let completionRate = Double(sessionsCompleted) / Double(totalSessions) * 100
        
        let messageText = """
        📊 Week \(weekNumber) Training Summary
        
        ✅ Sessions: \(sessionsCompleted)/\(totalSessions) (\(Int(completionRate))%)
        ⏱️ Average Time: \(String(format: "%.2f", averageTime))s
        🏆 Best Time: \(String(format: "%.2f", bestTime))s
        
        💪 Consistency is key to speed!
        
        Join me on SC40 Sprint Coach! 🚀
        """
        
        messageVC.body = messageText
        
        presentViewController(messageVC)
    }
    
    func sendChallenge(
        challengerTime: Double,
        challengeMessage: String = "Think you can beat my time?"
    ) {
        guard canSendMessages else { return }
        
        let messageVC = MFMessageComposeViewController()
        messageVC.messageComposeDelegate = self
        
        let messageText = """
        🏁 SPRINT CHALLENGE! 🏁
        
        I just ran a 40-yard sprint in \(String(format: "%.2f", challengerTime)) seconds!
        
        \(challengeMessage)
        
        🎯 Challenge Rules:
        • 40-yard sprint
        • Proper warmup required
        • Share your time back!
        
        Download SC40 Sprint Coach to track your progress! 📱
        
        Ready... Set... GO! 🚀
        """
        
        messageVC.body = messageText
        
        presentViewController(messageVC)
    }
    
    // MARK: - Email Sharing
    
    func shareDetailedReport(
        weeklyData: WeeklyProgressData,
        includeCharts: Bool = true
    ) {
        guard canSendMail else { return }
        
        let mailVC = MFMailComposeViewController()
        mailVC.mailComposeDelegate = self
        
        mailVC.setSubject("SC40 Sprint Training - Week \(weeklyData.weekNumber) Report")
        
        let htmlBody = generateDetailedHTMLReport(weeklyData: weeklyData)
        mailVC.setMessageBody(htmlBody, isHTML: true)
        
        // Add CSV data as attachment
        if let csvData = generateCSVReport(weeklyData: weeklyData) {
            mailVC.addAttachmentData(
                csvData,
                mimeType: "text/csv",
                fileName: "SC40_Week\(weeklyData.weekNumber)_Data.csv"
            )
        }
        
        // Add charts if requested
        if includeCharts, let chartImage = generateProgressChart(weeklyData: weeklyData) {
            if let imageData = chartImage.pngData() {
                mailVC.addAttachmentData(
                    imageData,
                    mimeType: "image/png",
                    fileName: "SC40_Progress_Chart.png"
                )
            }
        }
        
        presentViewController(mailVC)
    }
    
    // MARK: - Image Generation
    
    private func generateWorkoutSummaryImage(
        sprintTime: Double,
        improvement: Double?,
        weekNumber: Int,
        dayNumber: Int
    ) -> UIImage? {
        let size = CGSize(width: 400, height: 300)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let _ = CGRect(origin: .zero, size: size)
            
            // Background gradient
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [
                    UIColor(red: 0.1, green: 0.2, blue: 0.4, alpha: 1.0).cgColor,
                    UIColor(red: 0.2, green: 0.1, blue: 0.3, alpha: 1.0).cgColor
                ] as CFArray,
                locations: [0.0, 1.0]
            )!
            
            context.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: size.width, y: size.height),
                options: []
            )
            
            // Title
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: UIColor.white
            ]
            
            let title = "SC40 Sprint Result"
            let titleSize = title.size(withAttributes: titleAttributes)
            let titleRect = CGRect(
                x: (size.width - titleSize.width) / 2,
                y: 20,
                width: titleSize.width,
                height: titleSize.height
            )
            title.draw(in: titleRect, withAttributes: titleAttributes)
            
            // Sprint time
            let timeAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 36),
                .foregroundColor: UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0)
            ]
            
            let timeText = String(format: "%.2fs", sprintTime)
            let timeSize = timeText.size(withAttributes: timeAttributes)
            let timeRect = CGRect(
                x: (size.width - timeSize.width) / 2,
                y: 80,
                width: timeSize.width,
                height: timeSize.height
            )
            timeText.draw(in: timeRect, withAttributes: timeAttributes)
            
            // Week/Day info
            let infoAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16),
                .foregroundColor: UIColor.white.withAlphaComponent(0.8)
            ]
            
            let infoText = "Week \(weekNumber), Day \(dayNumber)"
            let infoSize = infoText.size(withAttributes: infoAttributes)
            let infoRect = CGRect(
                x: (size.width - infoSize.width) / 2,
                y: 140,
                width: infoSize.width,
                height: infoSize.height
            )
            infoText.draw(in: infoRect, withAttributes: infoAttributes)
            
            // Improvement (if any)
            if let improvement = improvement, improvement > 0 {
                let improvementText = "↗️ +\(String(format: "%.2f", improvement))s improvement"
                let improvementSize = improvementText.size(withAttributes: infoAttributes)
                let improvementRect = CGRect(
                    x: (size.width - improvementSize.width) / 2,
                    y: 170,
                    width: improvementSize.width,
                    height: improvementSize.height
                )
                improvementText.draw(in: improvementRect, withAttributes: infoAttributes)
            }
            
            // App branding
            let brandingText = "SC40 Sprint Coach"
            let brandingSize = brandingText.size(withAttributes: infoAttributes)
            let brandingRect = CGRect(
                x: (size.width - brandingSize.width) / 2,
                y: size.height - 40,
                width: brandingSize.width,
                height: brandingSize.height
            )
            brandingText.draw(in: brandingRect, withAttributes: infoAttributes)
        }
    }
    
    private func generateCelebrationImage(newRecord: Double, improvement: Double) -> UIImage? {
        let size = CGSize(width: 400, height: 400)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            
            // Celebration background
            UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0).setFill()
            context.fill(rect)
            
            // Trophy emoji (simplified - in real implementation you'd use proper graphics)
            let trophyAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 80),
                .foregroundColor: UIColor.white
            ]
            
            let trophy = "🏆"
            let trophySize = trophy.size(withAttributes: trophyAttributes)
            let trophyRect = CGRect(
                x: (size.width - trophySize.width) / 2,
                y: 50,
                width: trophySize.width,
                height: trophySize.height
            )
            trophy.draw(in: trophyRect, withAttributes: trophyAttributes)
            
            // "NEW RECORD" text
            let recordAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 28),
                .foregroundColor: UIColor.white
            ]
            
            let recordText = "NEW RECORD!"
            let recordSize = recordText.size(withAttributes: recordAttributes)
            let recordRect = CGRect(
                x: (size.width - recordSize.width) / 2,
                y: 160,
                width: recordSize.width,
                height: recordSize.height
            )
            recordText.draw(in: recordRect, withAttributes: recordAttributes)
            
            // Time
            let timeText = String(format: "%.2f seconds", newRecord)
            let timeSize = timeText.size(withAttributes: recordAttributes)
            let timeRect = CGRect(
                x: (size.width - timeSize.width) / 2,
                y: 200,
                width: timeSize.width,
                height: timeSize.height
            )
            timeText.draw(in: timeRect, withAttributes: recordAttributes)
            
            // Improvement
            let improvementText = String(format: "%.2fs faster!", improvement)
            let improvementSize = improvementText.size(withAttributes: recordAttributes)
            let improvementRect = CGRect(
                x: (size.width - improvementSize.width) / 2,
                y: 240,
                width: improvementSize.width,
                height: improvementSize.height
            )
            improvementText.draw(in: improvementRect, withAttributes: recordAttributes)
        }
    }
    
    // MARK: - Report Generation
    
    private func generateDetailedHTMLReport(weeklyData: WeeklyProgressData) -> String {
        return """
        <html>
        <head>
            <title>SC40 Sprint Training Report</title>
            <style>
                body { font-family: Arial, sans-serif; margin: 20px; }
                .header { background: linear-gradient(45deg, #1a3a6b, #2a1a4b); color: white; padding: 20px; border-radius: 10px; }
                .stats { display: flex; justify-content: space-around; margin: 20px 0; }
                .stat-box { background: #f0f0f0; padding: 15px; border-radius: 8px; text-align: center; }
                .improvement { color: green; font-weight: bold; }
                .decline { color: red; font-weight: bold; }
            </style>
        </head>
        <body>
            <div class="header">
                <h1>🏃‍♂️ SC40 Sprint Training Report</h1>
                <h2>Week \(weeklyData.weekNumber) Summary</h2>
            </div>
            
            <div class="stats">
                <div class="stat-box">
                    <h3>Sessions Completed</h3>
                    <p>\(weeklyData.sessionsCompleted)/\(weeklyData.totalSessions)</p>
                </div>
                <div class="stat-box">
                    <h3>Best Time</h3>
                    <p>\(String(format: "%.2f", weeklyData.bestTime))s</p>
                </div>
                <div class="stat-box">
                    <h3>Average Time</h3>
                    <p>\(String(format: "%.2f", weeklyData.averageTime))s</p>
                </div>
                <div class="stat-box">
                    <h3>Improvement</h3>
                    <p class="\(weeklyData.improvement >= 0 ? "improvement" : "decline")">
                        \(weeklyData.improvement >= 0 ? "+" : "")\(String(format: "%.2f", weeklyData.improvement))s
                    </p>
                </div>
            </div>
            
            <h3>Session Details</h3>
            <table border="1" style="width: 100%; border-collapse: collapse;">
                <tr>
                    <th>Day</th>
                    <th>Session Type</th>
                    <th>Time</th>
                    <th>Notes</th>
                </tr>
                \(weeklyData.sessions.map { session in
                    "<tr><td>\(session.day)</td><td>\(session.type)</td><td>\(String(format: "%.2f", session.time))s</td><td>\(session.notes)</td></tr>"
                }.joined())
            </table>
            
            <p><em>Generated by SC40 Sprint Coach</em></p>
        </body>
        </html>
        """
    }
    
    private func generateCSVReport(weeklyData: WeeklyProgressData) -> Data? {
        var csvContent = "Day,Session Type,Time (seconds),Notes\n"
        
        for session in weeklyData.sessions {
            csvContent += "\(session.day),\(session.type),\(session.time),\(session.notes)\n"
        }
        
        return csvContent.data(using: .utf8)
    }
    
    private func generateProgressChart(weeklyData: WeeklyProgressData) -> UIImage? {
        // Simplified chart generation - in a real app you'd use a charting library
        let size = CGSize(width: 600, height: 400)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Background
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Simple line chart showing progress
            let times = weeklyData.sessions.map { $0.time }
            guard !times.isEmpty else { return }
            
            let minTime = times.min()! - 0.1
            let maxTime = times.max()! + 0.1
            let timeRange = maxTime - minTime
            
            let chartRect = CGRect(x: 50, y: 50, width: size.width - 100, height: size.height - 100)
            
            // Draw axes
            UIColor.black.setStroke()
            let path = UIBezierPath()
            path.move(to: CGPoint(x: chartRect.minX, y: chartRect.maxY))
            path.addLine(to: CGPoint(x: chartRect.maxX, y: chartRect.maxY))
            path.move(to: CGPoint(x: chartRect.minX, y: chartRect.minY))
            path.addLine(to: CGPoint(x: chartRect.minX, y: chartRect.maxY))
            path.stroke()
            
            // Draw data points
            UIColor.blue.setStroke()
            let dataPath = UIBezierPath()
            
            for (index, time) in times.enumerated() {
                let x = chartRect.minX + (CGFloat(index) / CGFloat(times.count - 1)) * chartRect.width
                let y = chartRect.maxY - ((time - minTime) / timeRange) * chartRect.height
                
                if index == 0 {
                    dataPath.move(to: CGPoint(x: x, y: y))
                } else {
                    dataPath.addLine(to: CGPoint(x: x, y: y))
                }
            }
            
            dataPath.lineWidth = 2.0
            dataPath.stroke()
        }
    }
    
    // MARK: - Helper Methods
    
    private func presentViewController(_ viewController: UIViewController) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        rootViewController.present(viewController, animated: true)
    }
}

// MARK: - Delegate Methods

extension MessagesManager: MFMessageComposeViewControllerDelegate {
    func messageComposeViewController(
        _ controller: MFMessageComposeViewController,
        didFinishWith result: MessageComposeResult
    ) {
        controller.dismiss(animated: true)
        
        switch result {
        case .sent:
            print("Message sent successfully")
        case .cancelled:
            print("Message cancelled")
        case .failed:
            print("Message failed to send")
        @unknown default:
            break
        }
    }
}

extension MessagesManager: MFMailComposeViewControllerDelegate {
    func mailComposeController(
        _ controller: MFMailComposeViewController,
        didFinishWith result: MFMailComposeResult,
        error: Error?
    ) {
        controller.dismiss(animated: true)
        
        switch result {
        case .sent:
            print("Email sent successfully")
        case .cancelled:
            print("Email cancelled")
        case .failed:
            print("Email failed to send: \(error?.localizedDescription ?? "Unknown error")")
        case .saved:
            print("Email saved as draft")
        @unknown default:
            break
        }
    }
}

// MARK: - Supporting Types

struct WeeklyProgressData {
    let weekNumber: Int
    let sessionsCompleted: Int
    let totalSessions: Int
    let bestTime: Double
    let averageTime: Double
    let improvement: Double
    let sessions: [SessionData]
}

struct SessionData {
    let day: Int
    let type: String
    let time: Double
    let notes: String
}
