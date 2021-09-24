import SwiftUI
import Resolver

struct CompetitionListView: View {

    let competition: Competition

    @EnvironmentObject private var user: User

    var body: some View {
        NavigationLink(destination: CompetitionView(competition: competition)) {
            HStack {
                Text(competition.name)
                Spacer()
                if competition.pendingParticipants.contains(user.id) {
                    Text("Invited")
                        .foregroundColor(.gray)
                }
            }
        }
    }
}
