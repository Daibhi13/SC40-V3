import SwiftUI
import Combine

/// End-of-session summary and sharing.

struct SummaryReportView: View {
    var onDone: (() -> Void)? = nil
    var showClose: Bool = false
    // Use the same sample data as RepLogWatchLiveView for now
    let reps: [(rep: Int, dist: String, time: String?, isLive: Bool)] = [
        (1, "40", "5.21", false),
        (2, "40", "5.34", false),
        (3, "40", "5.29", false),
        (4, "40", "5.18", false),
        (5, "40", "5.25", false),
        (6, "40", "5.22", false)
    ]
    var body: some View {
        ZStack {
            Canvas { context, size in
                // Summary report liquid glass background
                let reportGradient = Gradient(colors: [
                    BrandColorsWatch.background,
                    BrandColorsWatch.tertiary.opacity(0.18),
                    BrandColorsWatch.primary.opacity(0.05)
                ])
                context.fill(Path(CGRect(origin: .zero, size: size)),
                           with: .linearGradient(reportGradient, startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: size.width, y: size.height)))
                
                // Chart visualization effects
                let barHeight: CGFloat = 8
                for i in 0..<6 {
                    let x = size.width * 0.2 + (size.width * 0.6 / 6) * CGFloat(i)
                    let height = barHeight * (1.2 - CGFloat(i) * 0.2)
                    context.fill(Path(CGRect(x: x, y: size.height * 0.7, width: 4, height: height)),
                               with: .color(BrandColorsWatch.accent.opacity(0.25)))
                }
                
                // Glass shimmer effect
                context.addFilter(.blur(radius: 10))
                context.fill(Path(ellipseIn: CGRect(x: size.width * 0.1, y: size.height * 0.3, width: 30, height: 30)),
                           with: .color(BrandColorsWatch.primary.opacity(0.12)))
                context.fill(Path(ellipseIn: CGRect(x: size.width * 0.7, y: size.height * 0.5, width: 20, height: 20)),
                           with: .color(BrandColorsWatch.tertiary.opacity(0.15)))
            }
            .ignoresSafeArea()
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 32))
                        .foregroundColor(BrandColorsWatch.primary)
                    Spacer()
                    if showClose {
                        Button(action: { onDone?() }) {
                            ZStack {
                                Circle()
                                    .fill(BrandColorsWatch.tertiary.opacity(0.18))
                                    .frame(width: 36, height: 36)
                                Image(systemName: "xmark")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(BrandColorsWatch.primary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                Text("SC Report")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(BrandColorsWatch.primary)
                    .shadow(color: BrandColorsWatch.tertiary.opacity(0.18), radius: 2, x: 0, y: 1)
                if !reps.isEmpty && reps.count <= 100 {
                    ScrollView {
                        VStack(spacing: 6) {
                            HStack {
                                Text("Rp").font(.caption2).frame(width: 32, alignment: .center)
                                Text("Dst").font(.caption2).frame(width: 44, alignment: .center)
                                Text("Tm").font(.caption2).frame(width: 44, alignment: .center)
                                Text("Rt").font(.caption2).frame(width: 44, alignment: .center)
                            }
                            .foregroundColor(BrandColorsWatch.secondary)
                            Divider().opacity(0.3)
                            ForEach(reps, id: \.rep) { row in
                                HStack {
                                    Text("\(row.rep)")
                                        .font(.system(size: 15, weight: .semibold, design: .monospaced))
                                        .frame(width: 32, alignment: .center)
                                    Text(row.dist)
                                        .font(.system(size: 15, weight: .regular, design: .monospaced))
                                        .frame(width: 44, alignment: .center)
                                    if let t = row.time {
                                        Text(t)
                                            .font(.system(size: 15, weight: .regular, design: .monospaced))
                                            .frame(width: 44, alignment: .center)
                                    } else {
                                        Text("")
                                            .frame(width: 44, alignment: .center)
                                    }
                                    Text("")
                                        .frame(width: 44, alignment: .center)
                                }
                                .background(BrandColorsWatch.tertiary.opacity(0.08))
                                .cornerRadius(6)
                            }
                        }
                        .padding(.bottom, 2)
                    }
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 24))
                            .foregroundColor(.yellow)
                        Text(reps.isEmpty ? "No data to display." : "Too many reps to display.")
                            .font(.footnote)
                            .foregroundColor(BrandColorsWatch.secondary)
                    }
                }
                Spacer(minLength: 0)
                if !showClose {
                    Button(action: { onDone?() }) {
                        Label("Done", systemImage: "checkmark")
                            .font(.headline)
                            .foregroundColor(BrandColorsWatch.background)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(BrandColorsWatch.primary)
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                    .padding(.top)
                }
            }
            .padding()
        }
    }
}

#Preview {
    SummaryReportView()
}
