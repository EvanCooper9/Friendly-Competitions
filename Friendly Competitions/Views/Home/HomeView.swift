import HealthKit
import SwiftUI
import Resolver

struct HomeView: View {

    @EnvironmentObject private var activitySummaryManager: AnyActivitySummaryManager
    @EnvironmentObject private var competitionsManager: AnyCompetitionsManager
    @EnvironmentObject private var user: User

    @StateObject private var viewModel = HomeViewModel()
    @State private var presentDeveloper = false
    @State private var presentSettings = false
    @State private var presentNewCompetition = false
    @State private var presentSearchFriendsSheet = false
    @State private var sharedFriendId: String?
    @AppStorage(#function) var competitionsFiltered = false

    private var activitySummary: HKActivitySummary? {
        activitySummaryManager.activitySummaries.first(where: \.isToday)
    }

    var body: some View {
        List {
            Section {
                ActivitySummaryInfoView(activitySummary: activitySummary)
            } header: {
                Text("Activity").font(.title3)
            } footer: {
                if activitySummary == nil {
                    Text("No activity summary for today. If this is a mistake, please make sure that permissions are enabled in the Health app.")
                }
            }
            .textCase(nil)

            Section {
                ForEach(competitionsManager.competitions) { competition in
                    CompetitionListItem(competition: competition)
                }
            } header: {
                HStack {
                    Text("Competitions").font(.title3)
                    Spacer()
                    Button(action: { competitionsFiltered.toggle() }) {
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
            .textCase(nil)

            Section {
                ForEach(viewModel.friends) { friend in
                    HStack {
                        ActivityRingView(activitySummary: friend.tempActivitySummary?.hkActivitySummary)
                            .frame(width: 35, height: 35)
                        Text(friend.name)
                        Spacer()
                    }
                }
                .onDelete { indexSet in
                    viewModel.delete(friendsAtIndex: indexSet)
                }
                ForEach(viewModel.friendRequests) { friendRequest in
                    HStack {
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .font(.title)
                            .frame(width: 35, height: 35)
                        Text(friendRequest.name)
                        Spacer()
                        Button("Accept", action: { viewModel.accept(friendRequest) })
                            .foregroundColor(.blue)
                            .buttonStyle(.borderless)
                        Text("/")
                            .fontWeight(.ultraLight)
                        Button("Decline", action: { viewModel.decline(friendRequest) })
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
                if viewModel.friends.isEmpty && viewModel.friendRequests.isEmpty {
                    Text("Add friends to get started!")
                }
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
        .sheet(isPresented: $presentSettings) { Settings() }
        .sheet(isPresented: $presentSearchFriendsSheet) { AddFriendView(sharedFriendId: sharedFriendId) }
        .sheet(isPresented: $presentNewCompetition) { NewCompetitionView(friends: viewModel.friends) }
        .sheet(isPresented: $viewModel.shouldPresentPermissions) { PermissionsView() }
        .environmentObject(competitionsManager)
        .onOpenURL { url in
            guard url.absoluteString.contains("invite") else { return }
            sharedFriendId = url.lastPathComponent
            presentSearchFriendsSheet.toggle()
        }
    }
}

struct HomeView_Previews: PreviewProvider {

    private static let activitySummaryManager: AnyActivitySummaryManager = {
        let activitySummaryManager = AnyActivitySummaryManager()
        activitySummaryManager.activitySummaries = [.mock]
        return activitySummaryManager
    }()

    private static let competitionManager: AnyCompetitionsManager = {
        let competitionManager = AnyCompetitionsManager()
        competitionManager.competitions = [.mock, .mockInvited]
        return competitionManager
    }()

    static var previews: some View {
        Resolver.Name.mode = .mock
        return HomeView()
            .environmentObject(User.evan)
            .environmentObject(activitySummaryManager)
            .environmentObject(competitionManager)
    }
}
