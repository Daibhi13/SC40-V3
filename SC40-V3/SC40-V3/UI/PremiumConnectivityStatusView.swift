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
                case .connecting:
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundColor(.blue)
                        .rotationEffect(.degrees(animatePulse ? 360 : 0))
                        .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: animatePulse)
                case .disconnected:
                    Image(systemName: "wifi.slash")
                        .foregroundColor(.orange)
                case .error(_):
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
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
    
    // MARK: - Computed Properties
    private var connectionStatusText: String {
        return connectivityManager.connectionState.displayText
    }
    
    private var dataFreshnessText: String {
        return connectivityManager.dataFreshness.displayText
    }
    
    // MARK: - Status Text
    @ViewBuilder
    private var statusText: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Primary status
            Text(connectionStatusText)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(1)
            
            // Data freshness indicator
            if connectivityManager.dataFreshness != .current {
                Text(dataFreshnessText)
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
                    // No retry action available in current implementation
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(true)
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
        case .connecting: return .blue
        case .disconnected: return .orange
        case .error: return .red
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
                    
                    // Premium Features Section
                    premiumFeaturesSection
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
        case .connecting:
            ProgressView()
                .scaleEffect(0.8)
        case .disconnected:
            Image(systemName: "wifi.slash")
                .foregroundColor(.orange)
        case .error:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
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
                
                // Last sync time
                if let lastSync = connectivityManager.lastSyncTime {
                    HStack {
                        Text("Last Sync:")
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text(lastSync, style: .relative)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
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
    
    // MARK: - Premium Features Section
    @ViewBuilder
    private var premiumFeaturesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Premium Features")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                ForEach(connectivityManager.premiumFeatures, id: \.id) { feature in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(feature.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(feature.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if feature.isEnabled {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
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
                diagnosticRow(title: "Connection State", value: "\(connectivityManager.connectionState)")
                diagnosticRow(title: "Connection Quality", value: "\(connectivityManager.connectionQuality)")
                diagnosticRow(title: "Data Freshness", value: "\(connectivityManager.dataFreshness)")
                diagnosticRow(title: "Pending Operations", value: "\(connectivityManager.pendingOperations)")
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
    
    private var connectionStatusText: String {
        switch connectivityManager.connectionState {
        case .connected: return "Connected"
        case .connecting: return "Connecting..."
        case .disconnected: return "Disconnected"
        case .error: return "Error"
        }
    }
    
    var body: some View {
        HStack(spacing: 6) {
            // Simple dot indicator
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            // Status text
            Text(connectionStatusText)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
    
    private var statusColor: Color {
        switch connectivityManager.connectionState {
        case .connected: return .green
        case .connecting: return .blue
        case .disconnected: return .orange
        case .error: return .red
        }
    }
}

// MARK: - Preview
#Preview("Premium Connectivity Status") {
    Group {
        let manager = PremiumConnectivityManager.shared
        let _ = {
            manager.connectionState = .connected
            manager.syncStatus = .success
            manager.lastSyncTime = Date().addingTimeInterval(-120) // 2 minutes ago
            manager.pendingOperations = 3
            manager.connectionQuality = .excellent
            manager.dataFreshness = .current
        }()
        
        VStack(spacing: 20) {
            PremiumConnectivityStatusView(connectivityManager: manager)
            CompactConnectivityIndicator(connectivityManager: manager)
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

#Preview("Connectivity Error State") {
    Group {
        let manager = PremiumConnectivityManager.shared
        let _ = {
            manager.connectionState = .error("Watch not reachable")
            manager.syncStatus = .failed(ConnectivityError.networkUnavailable)
            manager.pendingOperations = 5
            manager.connectionQuality = .poor
            manager.dataFreshness = .stale
        }()
        
        PremiumConnectivityStatusView(connectivityManager: manager)
            .padding()
            .background(Color(.systemBackground))
    }
}
