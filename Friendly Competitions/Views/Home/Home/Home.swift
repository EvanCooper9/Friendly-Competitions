import SwiftUI

struct Home: View {

    @StateObject private var appState = AppState()

    @EnvironmentObject private var activitySummaryManager: AnyActivitySummaryManager
    @EnvironmentObject private var competitionsManager: AnyCompetitionsManager
    @EnvironmentObject private var friendsManager: AnyFriendsManager
    @EnvironmentObject private var permissionsManager: AnyPermissionsManager
    @EnvironmentObject private var userManager: AnyUserManager

    @State private var presentAbout = false
    @State private var presentPermissions = false
    @State private var presentSettings = false
    @State private var presentNewCompetition = false
    @State private var presentSearchFriendsSheet = false
    @AppStorage("competitionsFiltered") var competitionsFiltered = false

    var body: some View {
        List {
            Group {
                activitySummary
                competitions
                friends
            }
            .textCase(nil)
        }
        .navigationBarTitle(userManager.user.name)
        .toolbar {
            HStack {
                Button(toggling: $presentAbout) {
                    Image(systemName: "questionmark.circle")
                }
                Button(toggling: $presentSettings) {
                    Image(systemName: "person.crop.circle")
                }
            }
        }
        .embeddedInNavigationView()
        .sheet(isPresented: $presentAbout) { About() }
        .sheet(isPresented: $presentSettings) { Profile() }
        .sheet(isPresented: $presentSearchFriendsSheet) { AddFriendView() }
        .sheet(isPresented: $presentNewCompetition) { NewCompetitionView() }
        .sheet(isPresented: $presentPermissions) { PermissionsView() }
        .onOpenURL { url in
            appState.deepLink = DeepLink(from: url)
            switch appState.deepLink {
            case .friendReferral:
                presentSearchFriendsSheet.toggle()
            default:
                break
            }
        }
        .onAppear {
            presentPermissions = permissionsManager.requiresPermission
        }
        .onChange(of: permissionsManager.requiresPermission) { presentPermissions = $0 }
        .environmentObject(appState)
        .environmentObject(activitySummaryManager)
        .environmentObject(competitionsManager)
        .environmentObject(friendsManager)
        .environmentObject(permissionsManager)
        .environmentObject(userManager)
        .tabItem {
            Label("Home", systemImage: "house")
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
            ForEach($competitionsManager.competitions) { $competition in
                if competitionsFiltered ? competition.isActive : true {
                    CompetitionListItem(competition: $competition)
                }
            }
            ForEach($competitionsManager.invitedCompetitions) { $competition in
                if competitionsFiltered ? competition.isActive : true {
                    CompetitionListItem(competition: $competition)
                }
            }
        } header: {
            HStack {
                let text = competitionsFiltered ? "Active competitions" : "Competitions"
                Text(text).font(.title3)
                Spacer()
                Button {
                    withAnimation { competitionsFiltered.toggle() }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle\(competitionsFiltered ? ".fill" : "")")
                        .font(.title2)
                }
                .disabled(competitionsManager.competitions.isEmpty)

                Button(toggling: $presentNewCompetition) {
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
                NavigationLink(destination: FriendView(friend: friend)) {
                    HStack {
                        ActivityRingView(activitySummary: friend.tempActivitySummary?.hkActivitySummary)
                            .frame(width: 35, height: 35)
                        Text(friend.name)
                        Spacer()
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
                Button(toggling: $presentSearchFriendsSheet) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.title2)
                }
            }
        } footer: {
            if friendsManager.friends.isEmpty && friendsManager.friendRequests.isEmpty {
                Text("Add friends to get started!")
            }
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
        let competitions: [Competition] = [.mock, .mockInvited, .mockOld]
        let competitionManager = AnyCompetitionsManager()
        competitionManager.competitions = competitions
        competitionManager.standings = competitions.reduce(into: [:]) { partialResult, competition in
            partialResult[competition.id] = [.mock(for: .evan)]
        }
        return competitionManager
    }()

    private static let friendsManager: AnyFriendsManager = {
        let friend = User.gabby
        friend.tempActivitySummary = .mock
        let friendsManager = AnyFriendsManager()
        friendsManager.friends = [friend]
        friendsManager.friendRequests = [friend]
        return friendsManager
    }()

    private static let permissionsManager: AnyPermissionsManager = {
        let permissionsManager = AnyPermissionsManager()
        permissionsManager.requiresPermission = false
        permissionsManager.permissionStatus = [
            .health: .authorized,
            .notifications: .authorized
        ]
        return permissionsManager
    }()

    private static let userManager: AnyUserManager = {
        return AnyUserManager(user: .evan)
    }()

    static var previews: some View {
        Home()
            .environmentObject(activitySummaryManager)
            .environmentObject(competitionManager)
            .environmentObject(friendsManager)
            .environmentObject(permissionsManager)
            .environmentObject(userManager)
    }
}
