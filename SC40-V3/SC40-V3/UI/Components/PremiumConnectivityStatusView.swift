import SwiftUI

// MARK: - Premium Connectivity Status View
// Provides fast feedback UI with clean, non-intrusive premium experience
struct PremiumConnectivityStatusView: View {
    @ObservedObject var connectivityManager: PremiumConnectivityManager
    @State private var showDetails = false
    @State private var animatePulse = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Connection indicator with quality
            connectionIndicator
            
            // Status text
            statusText
            
            Spacer()
            
            // Action buttons
            actionButtons
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(statusBackgroundColor.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(statusBackgroundColor.opacity(0.3), lineWidth: 1)
        )
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.3)) {
                showDetails.toggle()
            }
        }
        .sheet(isPresented: $showDetails) {
            ConnectivityDetailsView(connectivityManager: connectivityManager)
        }
    }
    
    // MARK: - Connection Indicator
    @ViewBuilder
    private var connectionIndicator: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(statusBackgroundColor.opacity(0.2))
                .frame(width: 24, height: 24)
            
            // Status icon
            Group {
                switch connectivityManager.connectionState {
                case .connected:
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                case .syncing:
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundColor(.blue)
                        .rotationEffect(.degrees(animatePulse ? 360 : 0))
                        .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: animatePulse)
                case .offline:
                    Image(systemName: "wifi.slash")
                        .foregroundColor(.orange)
                case .error:
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                case .initializing:
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.gray)
                }
            }
            .font(.system(size: 12, weight: .semibold))
            
            // Quality indicator ring
            if connectivityManager.connectionQuality != .unknown {
                Circle()
                    .stroke(qualityColor, lineWidth: 2)
                    .frame(width: 28, height: 28)
                    .opacity(0.6)
            }
        }
        .onAppear {
            animatePulse = true
        }
    }
    
    // MARK: - Status Text
    @ViewBuilder
    private var statusText: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Primary status
            Text(connectivityManager.getStatusMessage())
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(1)
            
            // Data freshness indicator
            if connectivityManager.dataFreshness != .unknown {
                Text(connectivityManager.dataFreshness.displayText)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Action Buttons
    @ViewBuilder
    private var actionButtons: some View {
        HStack(spacing: 8) {
            // Pending operations indicator
            if connectivityManager.pendingOperations > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 10, weight: .medium))
                    Text("\(connectivityManager.pendingOperations)")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundColor(.orange)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Retry button for error states
            if case .error = connectivityManager.connectionState {
                Button(action: {
                    HapticManager.shared.light()
                    Task {
                        await connectivityManager.retryConnection()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Details button
            Button(action: {
                HapticManager.shared.light()
                showDetails = true
            }) {
                Image(systemName: "info.circle")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Computed Properties
    private var statusBackgroundColor: Color {
        switch connectivityManager.connectionState {
        case .connected: return .green
        case .syncing: return .blue
        case .offline: return .orange
        case .error: return .red
        case .initializing: return .gray
        }
    }
    
    private var qualityColor: Color {
        switch connectivityManager.connectionQuality {
        case .excellent: return .green
        case .good: return .yellow
        case .poor: return .red
        case .unknown: return .gray
        }
    }
}

// MARK: - Connectivity Details View
struct ConnectivityDetailsView: View {
    @ObservedObject var connectivityManager: PremiumConnectivityManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Connection Status Section
                    connectionStatusSection
                    
                    // Sync Status Section
                    syncStatusSection
                    
                    // Connection Quality Section
                    connectionQualitySection
                    
                    // Recovery Actions Section
                    if let guidance = connectivityManager.getRecoveryGuidance() {
                        recoverySection(guidance: guidance)
                    }
                    
                    // Advanced Diagnostics
                    diagnosticsSection
                }
                .padding()
            }
            .navigationTitle("Connectivity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Connection Status Section
    @ViewBuilder
    private var connectionStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Connection Status")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack {
                Image(systemName: "applewatch")
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading) {
                    Text("Apple Watch")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(connectivityManager.connectionState.displayText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                connectionStatusIcon
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    @ViewBuilder
    private var connectionStatusIcon: some View {
        switch connectivityManager.connectionState {
        case .connected:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        case .syncing:
            ProgressView()
                .scaleEffect(0.8)
        case .offline:
            Image(systemName: "wifi.slash")
                .foregroundColor(.orange)
        case .error:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
        case .initializing:
            ProgressView()
                .scaleEffect(0.8)
        }
    }
    
    // MARK: - Sync Status Section
    @ViewBuilder
    private var syncStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sync Status")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                // Last sync time
                HStack {
                    Text("Last Sync:")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    if let lastSync = connectivityManager.lastSyncTime {
                        Text(lastSync, style: .relative)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Never")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Data freshness
                HStack {
                    Text("Data Status:")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text(connectivityManager.dataFreshness.displayText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Pending operations
                if connectivityManager.pendingOperations > 0 {
                    HStack {
                        Text("Pending:")
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text("\(connectivityManager.pendingOperations) operations")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    }
                }
                
                // Sync progress
                if case .syncing = connectivityManager.syncStatus {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Progress:")
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Text("\(Int(connectivityManager.syncProgress * 100))%")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                        
                        ProgressView(value: connectivityManager.syncProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Connection Quality Section
    @ViewBuilder
    private var connectionQualitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Connection Quality")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack {
                // Quality indicator
                Circle()
                    .fill(qualityColor)
                    .frame(width: 16, height: 16)
                
                Text(qualityText)
                    .font(.subheadline)
                
                Spacer()
                
                if connectivityManager.connectionQuality != .unknown {
                    Text(qualityDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private var qualityColor: Color {
        switch connectivityManager.connectionQuality {
        case .excellent: return .green
        case .good: return .yellow
        case .poor: return .red
        case .unknown: return .gray
        }
    }
    
    private var qualityText: String {
        switch connectivityManager.connectionQuality {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .poor: return "Poor"
        case .unknown: return "Unknown"
        }
    }
    
    private var qualityDescription: String {
        switch connectivityManager.connectionQuality {
        case .excellent: return "< 100ms latency"
        case .good: return "100-300ms latency"
        case .poor: return "> 300ms latency"
        case .unknown: return "Not measured"
        }
    }
    
    // MARK: - Recovery Section
    @ViewBuilder
    private func recoverySection(guidance: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Connection Recovery")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(guidance)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button(action: {
                    HapticManager.shared.medium()
                    Task {
                        await connectivityManager.retryConnection()
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Retry Connection")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Diagnostics Section
    @ViewBuilder
    private var diagnosticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Diagnostics")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                diagnosticRow(title: "Watch Paired", value: WatchConnectivityManager.shared.isWatchConnected ? "Yes" : "No")
                diagnosticRow(title: "Watch Reachable", value: WatchConnectivityManager.shared.isWatchReachable ? "Yes" : "No")
                diagnosticRow(title: "App Installed", value: "Yes") // Assume installed if we're running
                diagnosticRow(title: "Background Sync", value: "Enabled")
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    @ViewBuilder
    private func diagnosticRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Compact Status Indicator
struct CompactConnectivityIndicator: View {
    @ObservedObject var connectivityManager: PremiumConnectivityManager
    
    var body: some View {
        HStack(spacing: 6) {
            // Simple dot indicator
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            // Status text
            Text(connectivityManager.connectionState.displayText)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
    
    private var statusColor: Color {
        switch connectivityManager.connectionState {
        case .connected: return .green
        case .syncing: return .blue
        case .offline: return .orange
        case .error: return .red
        case .initializing: return .gray
        }
    }
}

// MARK: - Preview
#Preview("Premium Connectivity Status") {
    let manager = PremiumConnectivityManager.shared
    manager.connectionState = .connected
    manager.syncStatus = .success
    manager.lastSyncTime = Date().addingTimeInterval(-120) // 2 minutes ago
    manager.pendingOperations = 3
    manager.connectionQuality = .excellent
    manager.dataFreshness = .current
    
    return VStack(spacing: 20) {
        PremiumConnectivityStatusView(connectivityManager: manager)
        CompactConnectivityIndicator(connectivityManager: manager)
    }
    .padding()
    .background(Color(.systemBackground))
}

#Preview("Connectivity Error State") {
    let manager = PremiumConnectivityManager.shared
    manager.connectionState = .error("Watch not reachable")
    manager.syncStatus = .failed(ConnectivityError.networkUnavailable)
    manager.pendingOperations = 5
    manager.connectionQuality = .poor
    manager.dataFreshness = .stale
    
    return PremiumConnectivityStatusView(connectivityManager: manager)
        .padding()
        .background(Color(.systemBackground))
}
