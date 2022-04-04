import Resolver
import SwiftUI

struct FriendView: View {

    let friend: User

    @InjectedObject private var friendsManager: AnyFriendsManager

    @State private var showConfirmDelete = false

    private var activitySummary: ActivitySummary? {
        friendsManager.friendActivitySummaries[friend.id]
    }

    var body: some View {
        List {
            Section {
                ActivitySummaryInfoView(activitySummary: activitySummary)
            } header: {
                Text("Today's activity")
            } footer: {
                if activitySummary == nil {
                    Text("Nothing here, yet!")
                }
            }

            Section("Stats") {
                StatisticsView(statistics: friend.statistics ?? .zero)
            }

            Section {
                Button(toggling: $showConfirmDelete) {
                    Label("Remove friend", systemImage: "person.crop.circle.badge.minus")
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle(friend.name)
        .confirmationDialog(
            "Are you sure?",
            isPresented: $showConfirmDelete,
            titleVisibility: .visible
        ) {
            Button("Yes", role: .destructive) { friendsManager.delete(friend: friend) }
            Button("Cancel", role: .cancel) {}
        }
        .registerScreenView(
            name: "Friend",
            parameters: [
                "id": friend.id,
                "name": friend.name
            ]
        )
    }
}

struct FriendView_Previews: PreviewProvider {
    static var previews: some View {
        FriendView(friend: .gabby)
            .withEnvironmentObjects()
            .embeddedInNavigationView()
    }
}
