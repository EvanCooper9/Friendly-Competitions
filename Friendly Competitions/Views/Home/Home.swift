import HealthKit
import SwiftUI
import Resolver

// TODO: Permissions

struct Home: View {

    @EnvironmentObject private var activitySummaryManager: AnyActivitySummaryManager
    @EnvironmentObject private var competitionsManager: AnyCompetitionsManager
    @EnvironmentObject private var friendsManager: AnyFriendsManager
    @EnvironmentObject private var user: User

    @State private var presentDeveloper = false
    @State private var presentSettings = false
    @State private var presentNewCompetition = false
    @State private var presentSearchFriendsSheet = false
    @State private var presentConfirmDeleteFriend = false
    @State private var friendToDelete: User?
    @State private var sharedFriendId: String?
    @AppStorage(#function) var competitionsFiltered = false

    var body: some View {
        List {
            Group {
                activitySummary
                competitions
                friends
            }
            .textCase(nil)
        }
        .navigationBarTitle(user.name)
        .toolbar {
            HStack {
                if user.role == .developer {
                    Button(action: { presentDeveloper.toggle() }) {
                        Image(systemName: "hammer.circle")
                    }
                }
                Button(action: { presentSettings.toggle() }) {
                    Image(systemName: "person.crop.circle")
                }
            }
        }
        .embeddedInNavigationView()
        .sheet(isPresented: $presentDeveloper) { Developer() }
        .sheet(isPresented: $presentSettings) { Profile() }
        .sheet(isPresented: $presentSearchFriendsSheet) { AddFriendView(sharedFriendId: sharedFriendId) }
        .sheet(isPresented: $presentNewCompetition) { NewCompetitionView() }
        .environmentObject(competitionsManager)
        .onOpenURL { url in
            guard url.absoluteString.contains("invite") else { return }
            sharedFriendId = url.lastPathComponent
            presentSearchFriendsSheet = true
        }
    }

    private var activitySummary: some View {
        Section {
            ActivitySummaryInfoView(activitySummary: activitySummaryManager.activitySummary)
        } header: {
            Text("Activity").font(.title3)
        } footer: {
            if activitySummaryManager.activitySummary == nil {
                Text("Have you worn your watch today? We can't find any activity summaries yet. If this is a mistake, please make sure that permissions are enabled in the Health app.")
            }
        }
    }

    private var competitions: some View {
        Section {
            let competitions = competitionsManager.competitions
                .filter { competitionsFiltered ? $0.isActive : true }
            ForEach(competitions) { competition in
                CompetitionListItem(competition: competition)
            }
        } header: {
            HStack {
                let text = competitionsFiltered ? "Active competitions" : "Competitions"
                Text(text).font(.title3)
                Spacer()
                Button {
                    withAnimation { competitionsFiltered.toggle() }
                } label: {
                    Image(
                        systemName: competitionsFiltered ?
                            "line.3.horizontal.decrease.circle.fill" :
                            "line.3.horizontal.decrease.circle"
                    )
                    .font(.title2)
                }
                .disabled(competitionsManager.competitions.isEmpty)

                Button(action: { presentNewCompetition.toggle() }) {
                    Image(systemName: "plus.circle")
                        .font(.title2)
                }
            }
        } footer: {
            if competitionsManager.competitions.isEmpty {
                Text("Start a competition against your friends!")
            }
        }
    }

    private var friends: some View {
        Section {
            ForEach(friendsManager.friends) { friend in
                HStack {
                    ActivityRingView(activitySummary: friend.tempActivitySummary?.hkActivitySummary)
                        .frame(width: 35, height: 35)
                    Text(friend.name)
                    Spacer()
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        friendToDelete = friend
                        presentConfirmDeleteFriend.toggle()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            ForEach(friendsManager.friendRequests) { friendRequest in
                HStack {
                    Image(systemName: "person.crop.circle.badge.questionmark")
                        .font(.title)
                        .frame(width: 35, height: 35)
                    Text(friendRequest.name)
                    Spacer()
                    Button("Accept", action: { friendsManager.acceptFriendRequest(from: friendRequest) })
                        .foregroundColor(.blue)
                        .buttonStyle(.borderless)
                    Text("/")
                        .fontWeight(.ultraLight)
                    Button("Decline", action: { friendsManager.declineFriendRequest(from: friendRequest) })
                        .foregroundColor(.red)
                        .padding(.trailing, 10)
                        .buttonStyle(.borderless)
                }
            }
        } header: {
            HStack {
                Text("Friends")
                    .font(.title3)
                Spacer()
                Button(action: { presentSearchFriendsSheet.toggle() }) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.title2)
                }
            }
        } footer: {
            if friendsManager.friends.isEmpty && friendsManager.friendRequests.isEmpty {
                Text("Add friends to get started!")
            }
        }
        .confirmationDialog(
            "Are you sure?",
            isPresented: $presentConfirmDeleteFriend,
            titleVisibility: .visible
        ) {
            Button("Yes", role: .destructive) {
                guard let friendToDelete = friendToDelete else { return }
                friendsManager.delete(friend: friendToDelete)
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

struct HomeView_Previews: PreviewProvider {

    private static let activitySummaryManager: AnyActivitySummaryManager = {
        let activitySummaryManager = AnyActivitySummaryManager()
        activitySummaryManager.activitySummary = .mock
        return activitySummaryManager
    }()

    private static let competitionManager: AnyCompetitionsManager = {
        let competitionManager = AnyCompetitionsManager()
        competitionManager.competitions = [.mock, .mockInvited, .mockOld]
        return competitionManager
    }()

    private static let friendsManager: AnyFriendsManager = {
        let friendsManager = AnyFriendsManager()
        friendsManager.friends = [.gabby]
        friendsManager.friendRequests = [.gabby]
        return friendsManager
    }()

    static var previews: some View {
        Resolver.Name.mode = .mock
        return Home()
            .environmentObject(User.evan)
            .environmentObject(activitySummaryManager)
            .environmentObject(competitionManager)
            .environmentObject(friendsManager)
    }
}
