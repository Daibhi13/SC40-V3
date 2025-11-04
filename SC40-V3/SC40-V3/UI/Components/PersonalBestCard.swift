import SwiftUI

struct PersonalBestCard: View {
    let personalBest: TimeInterval
    let date: String
    let competition: String
    let rank: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "rosette")
                    .foregroundColor(.yellow)
                Text("Personal Best")
                    .font(.headline)
                Spacer()
                Text(rank)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(String(format: "%.2f", personalBest))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                Text("sec")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(competition)
                        .font(.subheadline)
                    Text(date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct PersonalBestCard_Previews: PreviewProvider {
    static var previews: some View {
        PersonalBestCard(
            personalBest: 4.32,
            date: "Mar 15, 2023",
            competition: "State Finals",
            rank: "#12 Regionally"
        )
        .previewLayout(.sizeThatFits)
    }
}
