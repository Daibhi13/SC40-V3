import SwiftUI
import UIKit

struct ShareWithTeammatesView: View {
    @State private var showShareSheet = false
    @State private var shareLink = "https://sprintcoach40.com/freeweek?ref=athlete"
    
    var body: some View {
        ZStack {
            // Canvas background
            Canvas { context, size in
                context.fill(
                    Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 10),
                    with: .color(.brandPrimary.opacity(0.1))
                )
                context.stroke(
                    Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 10),
                    with: .color(.brandPrimary.opacity(0.3)),
                    lineWidth: 1
                )
            }
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 24) {
            Capsule()
                .frame(width: 40, height: 5)
                .foregroundColor(.brandAccent.opacity(0.2))
                .padding(.top, 12)
            Text("Give 1 Week Free!")
                .font(.title.bold())
                .foregroundColor(.brandPrimary)
            Text("Share Sprint Coach 40 with a teammate and you’ll give them 7 days free!")
                .font(.body)
                .foregroundColor(.brandSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.brandAccent.opacity(0.08))
                    .frame(height: 140)
                HStack(spacing: 18) {
                    Image(systemName: "figure.run")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 70, height: 70)
                        .foregroundColor(.brandTertiary)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("1 Free Week of Sprint Coach 40")
                            .font(.headline)
                            .foregroundColor(.brandPrimary)
                        Text("From: You")
                            .font(.subheadline)
                            .foregroundColor(.brandTertiary)
                        Spacer()
                        Text("Recipients must be new to Sprint Coach 40 to redeem this gift.")
                            .font(.caption)
                            .foregroundColor(.brandAccent)
                    }
                    Spacer()
                }
                .padding(.horizontal)
            }
            Button(action: { showShareSheet = true }) {
                Text("Share With a Teammate")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.brandTertiary)
                    .foregroundColor(.brandBackground)
                    .cornerRadius(16)
            }
            .padding(.horizontal)
            Button(action: {
                UIPasteboard.general.string = shareLink
            }) {
                Text("Copy Link")
                    .font(.subheadline)
                    .foregroundColor(.brandPrimary)
            }
            .padding(.horizontal)
            Spacer()
        }
        .sheet(isPresented: $showShareSheet) {
            ActivityView(activityItems: [shareLink])
        }
        }
    }
}

// MARK: - ActivityView (remove duplicate)
/*
struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
*/


#if DEBUG
struct ShareWithTeammatesView_Previews: PreviewProvider {
    static var previews: some View {
        ShareWithTeammatesView()
    }
}
#endif
