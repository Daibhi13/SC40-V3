import SwiftUI

struct WatchConnectivityStatusView: View {
    @ObservedObject var watchManager = WatchSessionManager.shared
    @State private var showingDetailedStatus = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Connection Status Card
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: connectionIcon)
                            .font(.title2)
                            .foregroundColor(connectionColor)
                        
                        Text("iPhone Connection")
                            .font(.headline)
                        
                        Spacer()
                    }
                    
                    HStack {
                        Text(watchManager.connectionStatusText)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if watchManager.isFullyConnected {
                            Text("✓")
                                .foregroundColor(.green)
                                .font(.title3)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(12)
                
                // Session Sync Status
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.title3)
                            .foregroundColor(.blue)
                        
                        Text("Session Sync")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text("\(watchManager.trainingSessions.count)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    
                    if let lastSync = watchManager.lastSyncTime {
                        HStack {
                            Text("Last sync: \(formatLastSync(lastSync))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                    }
                    
                    if watchManager.syncProgress < 1.0 && watchManager.syncProgress > 0 {
                        ProgressView(value: watchManager.syncProgress)
                            .progressViewStyle(LinearProgressViewStyle())
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(12)
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        watchManager.refreshSessions()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Refresh Sessions")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(!watchManager.isPhoneReachable)
                    
                    if !watchManager.trainingSessions.isEmpty {
                        Button(action: {
                            watchManager.clearLocalSessions()
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Clear Local Data")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.3))
                            .foregroundColor(.primary)
                            .cornerRadius(10)
                        }
                    }
                }
                
                Spacer()
                
                // Detailed Status Button
                Button("View Details") {
                    showingDetailedStatus = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            .padding()
            .navigationTitle("Connection")
            .sheet(isPresented: $showingDetailedStatus) {
                DetailedConnectionStatusView()
                    .environmentObject(watchManager)
            }
        }
    }
    
    private var connectionIcon: String {
        if watchManager.isFullyConnected {
            return "iphone.and.arrow.forward"
        } else if watchManager.isPhoneConnected {
            return "iphone.slash"
        } else {
            return "iphone.slash"
        }
    }
    
    private var connectionColor: Color {
        if watchManager.isFullyConnected {
            return .green
        } else if watchManager.isPhoneConnected {
            return .orange
        } else {
            return .red
        }
    }
    
    private func formatLastSync(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct DetailedConnectionStatusView: View {
    @EnvironmentObject var watchManager: WatchSessionManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                // WatchConnectivity Details
                VStack(alignment: .leading, spacing: 8) {
                    Text("WatchConnectivity Status")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    StatusRow(label: "Paired", value: watchManager.isPhoneConnected)
                    StatusRow(label: "Reachable", value: watchManager.isPhoneReachable)
                        
                        if let error = watchManager.connectionError {
                            Text("Error: \(error)")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                // Session Details
                VStack(alignment: .leading, spacing: 8) {
                    Text("Training Sessions")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    Text("Total Sessions: \(watchManager.trainingSessions.count)")
                    
                    if !watchManager.trainingSessions.isEmpty {
                        let currentWeekSessions = watchManager.trainingSessions.filter { $0.week == 1 }
                        Text("Week 1 Sessions: \(currentWeekSessions.count)")
                    }
                    
                    if let currentSession = watchManager.currentWorkoutSession {
                        Text("Active: W\(currentSession.week)/D\(currentSession.day)")
                            .fontWeight(.medium)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(12)
                
                // Battery Info
                VStack(alignment: .leading, spacing: 8) {
                    Text("Watch Status")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    StatusRow(label: "Battery Level", 
                            value: "N/A") // WKInterfaceDevice not available in iOS build
                    StatusRow(label: "Battery State", 
                            value: "Unknown")
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Connection Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

struct StatusRow: View {
    let label: String
    let value: Any
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
            Spacer()
            
            if let boolValue = value as? Bool {
                Image(systemName: boolValue ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(boolValue ? .green : .red)
                    .font(.caption)
            } else {
                Text(String(describing: value))
                    .font(.caption)
                    .fontWeight(.medium)
            }
        }
    }
}

#if DEBUG
struct WatchConnectivityStatusView_Previews: PreviewProvider {
    static var previews: some View {
        WatchConnectivityStatusView()
    }
}
#endif
