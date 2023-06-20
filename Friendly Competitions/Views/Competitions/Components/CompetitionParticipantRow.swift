import SwiftUI

struct CompetitionParticipantRow: View {

    struct Config: Identifiable {
        let id: String
        let rank: String
        let name: String
        let idPillText: String?
        let blurred: Bool
        let points: Int
        let highlighted: Bool
    }

    let config: Config

    var body: some View {
        HStack {
            Text(config.rank).bold()
            Text(config.name)
                .blur(radius: config.blurred ? 5 : 0)
            if let idPillText = config.idPillText {
                IDPill(id: idPillText)
            }
            Spacer()
            Text(config.points)
                .monospaced()
        }
        .foregroundColor(config.highlighted ? .blue : nil)
    }
}

extension CompetitionParticipantRow.Config {
    init(user: User?, currentUser: User, standing: Competition.Standing) {
        let visibility = user?.visibility(by: currentUser) ?? .hidden
        let rank = standing.isTie == true ? "T\(standing.rank)" : standing.rank.ordinalString ?? "?"
        self.init(
            id: standing.id,
            rank: rank,
            name: user?.name ?? standing.userId,
            idPillText: (user?.isAnonymous == true ? nil : user?.hashId)?.apply(visibility: visibility),
            blurred: visibility == .hidden,
            points: standing.points,
            highlighted: standing.userId == currentUser.id
        )
    }
}

private extension String {
    func apply(visibility: User.Visibility) -> String? {
        visibility == .visible ? self : nil
    }
}
