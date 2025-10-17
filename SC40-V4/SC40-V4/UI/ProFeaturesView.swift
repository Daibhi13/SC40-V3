import SwiftUI

struct ProFeaturesView: View {
    var body: some View {
        NavigationView {
            ZStack {
                // Pro Features Canvas liquid glass background
                Canvas { context, size in
                    // Pro gradient with gold accents
                    let proGradient = Gradient(colors: [
                        Color.brandBackground.opacity(0.95),
                        Color.yellow.opacity(0.3),
                        Color.orange.opacity(0.25),
                        Color.brandPrimary.opacity(0.8)
                    ])
                    context.fill(
                        Path(CGRect(origin: .zero, size: size)),
                        with: .linearGradient(proGradient,
                                            startPoint: CGPoint(x: 0, y: 0),
                                            endPoint: CGPoint(x: size.width, y: size.height))
                    )
                    
                    // Premium glass elements
                    let premiumElements = 6
                    for i in 0..<premiumElements {
                        let x = size.width * (0.15 + CGFloat(i % 3) * 0.35)
                        let y = size.height * (0.2 + CGFloat(i / 3) * 0.4)
                        let radius: CGFloat = 25 + CGFloat(i) * 8
                        
                        // Gold/premium glass bubbles
                        context.addFilter(.blur(radius: 18))
                        context.fill(Path(ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)),
                                   with: .color(Color.yellow.opacity(0.20)))
                        
                        // Inner highlight
                        context.fill(Path(ellipseIn: CGRect(x: x - radius * 0.4, y: y - radius * 0.4, width: radius * 0.8, height: radius * 0.8)),
                                   with: .color(Color.orange.opacity(0.15)))
                    }
                    
                    // Premium wave pattern
                    let waveHeight: CGFloat = 20
                    let waveLength = size.width / 3
                    var wavePath = Path()
                    wavePath.move(to: CGPoint(x: 0, y: size.height * 0.6))
                    for x in stride(from: 0, through: size.width, by: 2) {
                        let y = size.height * 0.6 + waveHeight * sin((x / waveLength) * 2 * .pi)
                        wavePath.addLine(to: CGPoint(x: x, y: y))
                    }
                    wavePath.addLine(to: CGPoint(x: size.width, y: size.height))
                    wavePath.addLine(to: CGPoint(x: 0, y: size.height))
                    
                    context.fill(wavePath, with: .color(Color.yellow.opacity(0.12)))
                    
                    // Glass overlay
                    context.fill(
                        Path(CGRect(origin: .zero, size: size)),
                        with: .color(Color.brandPrimary.opacity(0.05))
                    )
                }
                .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 32) {
                    // Performance Trends Pro Feature
                    VStack(spacing: 18) {
                        Text("Performance Trends")
                            .font(.title.bold())
                            .foregroundColor(.brandPrimary)
                            .multilineTextAlignment(.center)
                        Text("Track your progress with advanced performance analytics and detailed sprint trend analysis.")
                            .font(.body)
                            .foregroundColor(.brandSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        VStack(alignment: .leading, spacing: 10) {
                            Text("• Detailed performance graphs")
                            Text("• Sprint time progression tracking")
                            Text("• Comparative analysis over time")
                            Text("• Export performance reports")
                        }
                        .font(.body)
                        .foregroundColor(.brandTertiary)
                        .padding(.horizontal)
                        
                        Button(action: { 
                            // Show our new purchase manager
                        }) {
                            Text("Upgrade for $4.99/mo")
                                .font(.body)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.brandPrimary)
                                .foregroundColor(.white)
                                .cornerRadius(14)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Advanced Analytics summary
                    Text("Advanced Analytics")
                        .font(.title.bold())
                        .foregroundColor(.brandPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 24)
                    Text("Gain a competitive edge with in-depth sprint metrics, AI-powered coaching, and pro recruiting tools.")
                        .font(.body)
                        .foregroundColor(.brandSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button(action: { /* Upgrade action */ }) {
                        Text("Upgrade for $4.99/mo")
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.brandPrimary)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                    }
                    .padding(.horizontal)

                    // SC Pro summary
                    VStack(spacing: 18) {
                        Text("Sprint Coach Starter")
                            .font(.title.bold())
                            .foregroundColor(.brandPrimary)
                            .multilineTextAlignment(.center)
                        Text("SC Pro turns your Apple Watch into a world-class starter and timer. Set reps and rest, start your session, and get precise results—automatically synced to your phone.")
                            .font(.body)
                            .foregroundColor(.brandSecondary)
                            .multilineTextAlignment(.center)
                        VStack(alignment: .leading, spacing: 10) {
                            Text("• Precision starter: 'On your marks... Set... Go!'")
                            Text("• Set reps and rest your way")
                            Text("• Team or solo timing")
                            Text("• Results sync to phone & analytics")
                        }
                        .font(.body)
                        .foregroundColor(.brandTertiary)
                        .padding(.horizontal)
                        Button(action: { /* Unlock SC Pro action */ }) {
                            Text("Unlock SC Pro for $4.99 one-time")
                                .font(.body)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.brandPrimary)
                                .foregroundColor(.white)
                                .cornerRadius(14)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 12)
                    Spacer(minLength: 100) // Add some bottom spacing for scrolling
                }
                .padding(.top, 24)
                }
            }
            .navigationTitle("SC Pro Features")
        }
    }
}

#if DEBUG
struct ProFeaturesView_Previews: PreviewProvider {
    static var previews: some View {
        ProFeaturesView()
    }
}
#endif
