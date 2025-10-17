import SwiftUI

/// iPhone Setup Instructions View - Only appears when iPhone sync fails
struct iPhoneSetupInstructionsView: View {
    @State private var showDetailedInstructions = false
    @ObservedObject private var sessionManager = WatchSessionManager.shared
    var onContinue: () -> Void
    
    var body: some View {
        ZStack {
            // Premium gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color(red: 0.1, green: 0.1, blue: 0.15).opacity(0.2),
                    Color.black
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            if showDetailedInstructions {
                // Detailed instructions screen
                VStack(alignment: .leading, spacing: 16) {
                    // Back button
                    HStack {
                        Button("Back") {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showDetailedInstructions = false
                            }
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.bottom, 8)
                    
                    // Title
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Start Your SC40")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                        
                        Text("Journey")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                    }
                    .padding(.bottom, 16)
                    
                    // Detailed instructions
                    VStack(alignment: .leading, spacing: 12) {
                        InstructionRow(text: "Open the SC40 iPhone app")
                        InstructionRow(text: "Tap on the top left side menu")
                        InstructionRow(text: "Go into settings")
                        InstructionRow(text: "Go to Apple Watch and complete your setup")
                    }
                    
                    Spacer()
                    
                    // Continue button
                    Button(action: {
                        print("📱 User continuing from detailed instructions")
                        onContinue()
                    }) {
                        Text("Continue Anyway")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color(red: 0.95, green: 0.95, blue: 0.95).opacity(0.8))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                
            } else {
                // Main instruction screen
                VStack(spacing: 20) {
                    Spacer()
                    
                    // Title
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Start Your SC40")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                        
                        Text("Journey")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Subtitle
                    Text("Open the SC40 app on your iPhone to continue")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 20)
                    
                    // iPhone and Watch icons
                    HStack(spacing: 20) {
                        // iPhone icon
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.6))
                            .frame(width: 40, height: 60)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.8), lineWidth: 2)
                            )
                        
                        // Sync arrows
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.gray)
                        
                        // Watch icon
                        Circle()
                            .fill(Color.gray.opacity(0.6))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Circle()
                                    .stroke(Color.gray.opacity(0.8), lineWidth: 2)
                            )
                    }
                    .padding(.bottom, 30)
                    
                    Spacer()
                    
                    // Info button and Continue button
                    VStack(spacing: 12) {
                        // Info button
                        HStack {
                            Spacer()
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showDetailedInstructions = true
                                }
                            }) {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.white)
                                    .background(
                                        Circle()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 30, height: 30)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                        
                        // Continue button
                        Button(action: {
                            print("📱 User continuing without iPhone sync")
                            onContinue()
                        }) {
                            Text("Continue Without iPhone")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color(red: 0.95, green: 0.95, blue: 0.95).opacity(0.8))
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
        }
        .onAppear {
            print("📱 iPhone Setup Instructions appeared - sync failed")
        }
    }
}

/// Helper view for instruction rows
struct InstructionRow: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
    }
}

#Preview {
    iPhoneSetupInstructionsView(onContinue: {
        print("Continue pressed")
    })
}
