import SwiftUI

struct FriendView: View {

    let friend: User

    @EnvironmentObject private var friendsManager: AnyFriendsManager

    @State private var showConfirmDelete = false

    var body: some View {
        List {
            UserInfoSection(user: friend)

            Section {
                ActivitySummaryInfoView(activitySummary: friend.tempActivitySummary?.hkActivitySummary)
            } header: {
                Text("Today's activity")
            } footer: {
                if friend.tempActivitySummary == nil {
                    Text("Nothing here, yet!")
                }
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
    }
}

struct FriendView_Previews: PreviewProvider {
    static var previews: some View {
        FriendView(friend: .gabby)
            .environmentObject(AnyFriendsManager())
            .embeddedInNavigationView()
    }
}
