import SwiftUI

struct CompetitionParticipantView: View {
    
    struct Config: Identifiable {
        let id: String
        let rank: String?
        let name: String
        let idPillText: String?
        let blurred: Bool
        let points: Int?
        let highlighted: Bool
    }
    
    let config: Config
    
    var body: some View {
        HStack {
            if let rank = config.rank {
                Text(rank).bold()
            }
            Text(config.name)
                .blur(radius: config.blurred ? 5 : 0)
            if let idPillText = config.idPillText {
                IDPill(id: idPillText)
            }
            Spacer()
            if let points = config.points {
                Text(points)
            }
        }
        .foregroundColor(config.highlighted ? .blue : nil)
    }
}
