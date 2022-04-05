import Resolver
import SwiftUI

struct Dashboard: View {

    @InjectedObject private var appState: AppState
    @InjectedObject private var activitySummaryManager: AnyActivitySummaryManager
    @InjectedObject private var competitionsManager: AnyCompetitionsManager
    @InjectedObject private var friendsManager: AnyFriendsManager
    @InjectedObject private var permissionsManager: AnyPermissionsManager
    @InjectedObject private var userManager: AnyUserManager

    @State private var presentAbout = false
    @State private var presentPermissions = false
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
        .navigationBarTitle(userManager.user.name.ifEmpty(Bundle.main.displayName))
        .toolbar {
            HStack {
                Button(toggling: $presentAbout) {
                    Image(systemName: "questionmark.circle")
                }
                NavigationLink {
                    Profile()
                } label: {
                    Image(systemName: "person.crop.circle")
                }
            }
        }
        .embeddedInNavigationView()
        .sheet(isPresented: $presentAbout) { About() }
        .sheet(isPresented: $presentSearchFriendsSheet) { AddFriendView() }
        .sheet(isPresented: $presentNewCompetition) { NewCompetition() }
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
        .tabItem {
            Label("Home", systemImage: "house")
        }
        .registerScreenView(name: "Home")
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
                    CompetitionDetails(competition: $competition, showParticipantCount: false, isFeatured: false)
                }
            }
            ForEach($competitionsManager.invitedCompetitions) { $competition in
                if competitionsFiltered ? competition.isActive : true {
                    CompetitionDetails(competition: $competition, showParticipantCount: false, isFeatured: false)
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
                        ActivityRingView(activitySummary: friendsManager.friendActivitySummaries[friend.id]?.hkActivitySummary)
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

struct Dashboard_Previews: PreviewProvider {
    static var previews: some View {
        registerDependencies()
        return Dashboard()
            .setupMocks {
                activitySummaryManager.activitySummary = .mock

                let competitions: [Competition] = [.mock, .mockInvited, .mockOld, .mockPublic]
                competitionsManager.competitions = competitions
                competitionsManager.participants = competitions.reduce(into: [:]) { partialResult, competition in
                    partialResult[competition.id] = [.evan]
                }
                competitionsManager.standings = competitions.reduce(into: [:]) { partialResult, competition in
                    partialResult[competition.id] = [.mock(for: .evan)]
                }

                let friend = User.gabby
                friendsManager.friends = [friend]
                friendsManager.friendRequests = [friend]
                friendsManager.friendActivitySummaries = [friend.id: .mock]

                permissionsManager.requiresPermission = false
                permissionsManager.permissionStatus = [
                    .health: .authorized,
                    .notifications: .authorized
                ]
            }
    }
}
