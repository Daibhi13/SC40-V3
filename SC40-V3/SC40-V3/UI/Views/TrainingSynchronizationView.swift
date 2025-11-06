import SwiftUI
import Combine

// MARK: - Training Synchronization Demo View
// Demonstrates the Core UI/UX Synchronization Logic implementation

struct TrainingSynchronizationView: View {
    @StateObject private var syncManager = TrainingSynchronizationManager.shared
    @State private var showingLevelPicker = false
    @State private var showingDaysPicker = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                headerSection
                
                // Current Configuration
                configurationSection
                
                // 28 Combinations Grid
                combinationsGrid
                
                // Synchronization Status
                synchronizationStatus
                
                // Active Sessions Preview
                if !syncManager.activeSessions.isEmpty {
                    activeSessionsPreview
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Training Sync")
            .sheet(isPresented: $showingLevelPicker) {
                levelPickerSheet
            }
            .sheet(isPresented: $showingDaysPicker) {
                daysPickerSheet
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("SC40-V3 Training Synchronization")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("4 Levels × 7 Days = 28 Combinations")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if let compilationID = syncManager.currentCompilationID {
                Text("ID: \(String(compilationID.prefix(16)))...")
                    .font(.caption.monospaced())
                    .foregroundColor(Color.blue)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Configuration Section
    
    private var configurationSection: some View {
        HStack(spacing: 16) {
            // Level Selector
            Button(action: { showingLevelPicker = true }) {
                VStack(spacing: 4) {
                    Text("Level")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(syncManager.selectedLevel.label)
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray5))
                .cornerRadius(8)
            }
            
            Text("×")
                .font(.title2)
                .foregroundColor(.secondary)
            
            // Days Selector
            Button(action: { showingDaysPicker = true }) {
                VStack(spacing: 4) {
                    Text("Days/Week")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(syncManager.selectedDays)")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray5))
                .cornerRadius(8)
            }
            
            Text("=")
                .font(.title2)
                .foregroundColor(.secondary)
            
            // Sessions Count
            VStack(spacing: 4) {
                Text("Sessions")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(syncManager.activeSessions.count)")
                    .font(.headline)
                    .foregroundColor(.green)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray5))
            .cornerRadius(8)
        }
    }
    
    // MARK: - 28 Combinations Grid
    
    private var combinationsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All 28 Combinations")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(TrainingLevel.allCases, id: \.self) { level in
                    ForEach(1...7, id: \.self) { days in
                        combinationCell(level: level, days: days)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func combinationCell(level: TrainingLevel, days: Int) -> some View {
        let isSelected = level == syncManager.selectedLevel && days == syncManager.selectedDays
        let sessionCount = days * 12 // 12 weeks
        
        return Button(action: {
            Task {
                await syncManager.synchronizeTrainingProgram(level: level, days: days)
            }
        }) {
            VStack(spacing: 2) {
                Text(level.rawValue.prefix(1).uppercased())
                    .font(.caption2)
                    .fontWeight(.bold)
                Text("\(days)")
                    .font(.caption2)
                Text("\(sessionCount)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 40, height: 40)
            .background(isSelected ? Color.blue : Color(.systemGray4))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(6)
        }
        .disabled(syncManager.isSyncing)
    }
    
    // MARK: - Synchronization Status
    
    private var synchronizationStatus: some View {
        VStack(spacing: 12) {
            Text("Synchronization Status")
                .font(.headline)
            
            HStack(spacing: 20) {
                // Phone Status
                syncStatusIndicator(
                    title: "iPhone",
                    isConnected: true,
                    isSynced: syncManager.isPhoneSynced,
                    icon: "iphone"
                )
                
                // Sync Arrow
                Image(systemName: syncManager.isSyncing ? "arrow.triangle.2.circlepath" : "arrow.left.arrow.right")
                    .font(.title2)
                    .foregroundColor(syncManager.isSyncing ? .blue : .green)
                    .rotationEffect(.degrees(syncManager.isSyncing ? 360 : 0))
                    .animation(syncManager.isSyncing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: syncManager.isSyncing)
                
                // Watch Status
                syncStatusIndicator(
                    title: "Apple Watch",
                    isConnected: true, // Simplified for demo
                    isSynced: syncManager.isWatchSynced,
                    icon: "applewatch"
                )
            }
            
            if let lastSync = syncManager.lastSyncTimestamp {
                Text("Last sync: \(lastSync, formatter: timeFormatter)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if syncManager.isSyncing {
                ProgressView("Synchronizing...")
                    .progressViewStyle(CircularProgressViewStyle())
            }
            
            if let error = syncManager.syncError {
                Text("Error: \(error)")
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func syncStatusIndicator(title: String, isConnected: Bool, isSynced: Bool, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isSynced ? .green : .orange)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
            
            Circle()
                .fill(isSynced ? Color.green : Color.orange)
                .frame(width: 8, height: 8)
        }
    }
    
    // MARK: - Active Sessions Preview
    
    private var activeSessionsPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Sessions (First 5)")
                .font(.headline)
            
            ForEach(Array(syncManager.activeSessions.prefix(5)), id: \.id) { session in
                sessionRow(session: session)
            }
            
            if syncManager.activeSessions.count > 5 {
                Text("... and \(syncManager.activeSessions.count - 5) more sessions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func sessionRow(session: TrainingSession) -> some View {
        let progress = syncManager.sessionProgress[session.id.uuidString] ?? SessionProgress(isLocked: true, isCompleted: false, completionPercentage: 0.0)
        
        return HStack {
            // Session Info
            VStack(alignment: .leading, spacing: 2) {
                Text("Week \(session.week), Day \(session.day)")
                    .font(.caption)
                    .fontWeight(.medium)
                Text(session.type)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Status
            Image(systemName: progress.isCompleted ? "checkmark.circle.fill" : 
                             progress.isLocked ? "lock.circle" : "circle")
                .foregroundColor(progress.isCompleted ? .green : 
                               progress.isLocked ? .orange : .blue)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray5))
        .cornerRadius(6)
    }
    
    // MARK: - Picker Sheets
    
    private var levelPickerSheet: some View {
        NavigationView {
            List(TrainingLevel.allCases, id: \.self) { level in
                Button(action: {
                    Task {
                        await syncManager.synchronizeTrainingProgram(level: level, days: syncManager.selectedDays)
                    }
                    showingLevelPicker = false
                }) {
                    HStack {
                        Text(level.label)
                        Spacer()
                        if level == syncManager.selectedLevel {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Select Level")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        showingLevelPicker = false
                    }
                }
            }
        }
    }
    
    private var daysPickerSheet: some View {
        NavigationView {
            List(1...7, id: \.self) { days in
                Button(action: {
                    Task {
                        await syncManager.synchronizeTrainingProgram(level: syncManager.selectedLevel, days: days)
                    }
                    showingDaysPicker = false
                }) {
                    HStack {
                        Text("\(days) day\(days == 1 ? "" : "s") per week")
                        Spacer()
                        if days == syncManager.selectedDays {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Select Days")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        showingDaysPicker = false
                    }
                }
            }
        }
    }
    
    // MARK: - Formatters
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }
}

// MARK: - Preview

struct TrainingSynchronizationView_Previews: PreviewProvider {
    static var previews: some View {
        TrainingSynchronizationView()
    }
}
