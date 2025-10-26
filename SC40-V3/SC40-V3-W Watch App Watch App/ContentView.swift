import SwiftUI

struct ContentView: View {
    var body: some View {
        WatchMainView()
    }
}

struct WatchMainView: View {
    @State private var showSplash = true
    
    var body: some View {
        ZStack {
            if showSplash {
                SplashScreenView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                showSplash = false
                            }
                        }
                    }
            } else {
                SessionCardsView()
            }
        }
    }
}

struct SplashScreenView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 50, weight: .bold))
                    .foregroundColor(.yellow)
                    .scaleEffect(animate ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: animate)
                
                Text("Sprint Coach 40")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Apple Watch")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .onAppear {
            animate = true
        }
    }
}

struct SessionCardsView: View {
    @State private var selectedCard = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                TabView(selection: $selectedCard) {
                    WelcomeCard()
                        .tag(0)
                    
                    SessionCard(week: 1, day: 1, type: "Sprint Training", focus: "Acceleration")
                        .tag(1)
                    
                    SessionCard(week: 1, day: 2, type: "Speed Endurance", focus: "Lactate Tolerance")
                        .tag(2)
                }
                #if os(watchOS)
                .tabViewStyle(.page)
                #else
                .tabViewStyle(PageTabViewStyle())
                #endif
                
                Button(action: {
                    // Handle start action
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                            .font(.system(size: 14, weight: .bold))
                        
                        Text("START")
                            .font(.system(size: 14, weight: .bold))
                            .tracking(0.5)
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.85, blue: 0.1),
                                Color(red: 1.0, green: 0.75, blue: 0.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(12)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Sprint Coach")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }
}

struct WelcomeCard: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.yellow)
            
            Text("Welcome to")
                .font(.caption)
                .foregroundColor(.gray)
            
            Text("Sprint Coach 40")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Ready to train")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
    }
}

struct SessionCard: View {
    let week: Int
    let day: Int
    let type: String
    let focus: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("W\(week)/D\(day)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.yellow)
                    .cornerRadius(4)
                
                Spacer()
            }
            
            Text(type)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .lineLimit(2)
            
            Text(focus)
                .font(.caption)
                .foregroundColor(.gray)
                .lineLimit(2)
            
            HStack {
                Text("5×40yd")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("MAX")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.white)
                    .cornerRadius(4)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.15, green: 0.1, blue: 0.25).opacity(0.9),
                            Color(red: 0.1, green: 0.05, blue: 0.2).opacity(0.95)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.yellow.opacity(0.4), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
    }
}

#if DEBUG
#Preview("ContentView") {
    ContentView()
        .preferredColorScheme(.dark)
}
#endif
