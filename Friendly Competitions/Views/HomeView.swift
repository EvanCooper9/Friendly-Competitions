import FirebaseAuth
import FirebaseFirestore
import HealthKit
import SwiftUI
import Resolver
import WatchConnectivity
import OrderedCollections

struct HomeView: View {

    @ObservedObject private var viewModel = HomeViewModel()

    @State private var presentSettings = false
    @State private var presentAddFriendsAlert = false
    @State private var presentNewCompetition = false
    @State private var presentSearchFriendsSheet = false
    @State private var sharedFriendId: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                List {
                    Section {
                        ActivitySummaryInfoView(activitySummary: viewModel.activitySummary)
                    } header: {
                        Text("Activity").font(.title3)
                    } footer: {
                        if viewModel.activitySummary == nil {
                            Text("No activity summary for today. If this is a mistake, please make sure that permissions are enabled in the Health app.")
                        }
                    }
                    .textCase(nil)

                    Section {
                        ForEach(viewModel.competitions) { competition in
                            CompetitionListView(competition: competition)
                        }
                    } header: {
                        HStack {
                            Text("Competitions")
                                .font(.title3)
                            Spacer()
                            Button(action: {
                                viewModel.user.friends.isEmpty ?
                                presentAddFriendsAlert.toggle() :
                                presentNewCompetition.toggle()
                            }) {
                                Image(systemName: "plus.circle")
                                    .font(.title2)
                            }
                        }
                    } footer: {
                        if viewModel.competitions.isEmpty {
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
                                Text("/")
                                    .fontWeight(.ultraLight)
                                Button("Decline", action: { viewModel.decline(friendRequest) })
                                    .foregroundColor(.red)
                                    .padding(.trailing, 10)
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
                .listStyle(.insetGrouped)
            }
            .navigationBarTitle(viewModel.user.name)
            .toolbar {
                Button(action: { presentSettings.toggle() }) {
                    Image(systemName: "person.crop.circle")
                }
            }
        }
        .alert("Oops!", isPresented: $presentAddFriendsAlert, actions: {
            Button("Ok", role: .cancel) {}
        }, message: {
            Text("You cannot start a competition against yourself, add friends to continue!")
        })
        .sheet(isPresented: $presentSettings) { SettingsView() }
        .sheet(isPresented: $presentSearchFriendsSheet) { AddFriendView(sharedFriendId: sharedFriendId) }
        .sheet(isPresented: $presentNewCompetition) { NewCompetitionView(friends: viewModel.friends) }
        .onOpenURL { url in
            guard url.absoluteString.contains("invite") else { return }
            sharedFriendId = url.lastPathComponent
            presentSearchFriendsSheet.toggle()
        }
    }
}

fileprivate final class HomeViewModel: ObservableObject {

    @Published private(set) var activitySummary: HKActivitySummary?
    @Published private(set) var competitions = [Competition]()
    @Published private(set) var friends = [User]()
    @Published private(set) var friendRequests = [User]()

    @LazyInjected private var activitySummaryManager: ActivitySummaryManaging
    @LazyInjected private var database: Firestore
    @LazyInjected var user: User

    private var listenerRegistrations = [ListenerRegistration]()

    init() {
        activitySummaryManager.addHandler { [weak self] hkActivitySummaries in
            DispatchQueue.main.async {
                self?.activitySummary = hkActivitySummaries.first { $0.activitySummary.date.isToday }
            }
        }

        let userListener = database.document("users/\(user.id)")
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self = self, let user = try? snapshot?.decoded(as: User.self) else { return }
                self.user = user
                Task(priority: .high) {
                    try? await self.updateFriends()
                    try? await self.updateFriendRequests()
                }
            }

        let competitionListener = database.collection("competitions")
            .whereField("participants", arrayContains: user.id)
            .addSnapshotListener { snapshot, _ in
                let competitions = snapshot?.documents
                    .decoded(asArrayOf: Competition.self)
                    .sorted(by: \.start)

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.competitions = competitions ?? []
                }
            }

        listenerRegistrations.append(contentsOf: [userListener, competitionListener])
    }

    // MARK: - Public Methods

    func accept(_ friendRequest: User) {
        let batch = database.batch()

        let userDocument = database.document("users/\(user.id)")
        let myRequests = user.incomingFriendRequests.removing(friendRequest.id)
        let myFriends = user.friends.appending(friendRequest.id)
        batch.updateData(["incomingFriendRequests": myRequests], forDocument: userDocument)
        batch.updateData(["friends": myFriends], forDocument: userDocument)

        let requestorDocument = database.document("users/\(friendRequest.id)")
        let theirRequests = friendRequest.outgoingFriendRequests.removing(user.id)
        let theirFriends = friendRequest.friends.appending(user.id)
        batch.updateData(["outgoingFriendRequests": theirRequests], forDocument: requestorDocument)
        batch.updateData(["friends": theirFriends], forDocument: requestorDocument)

        batch.commit()
    }

    func decline(_ friendRequest: User) {
        let batch = database.batch()

        let myRequests = user.incomingFriendRequests.removing(friendRequest.id)
        batch.updateData(["incomingFriendRequests": myRequests], forDocument: database.document("users/\(user.id)"))

        let theirRequests = friendRequest.outgoingFriendRequests.removing(user.id)
        batch.updateData(["outgoingFriendRequests": theirRequests], forDocument: database.document("users/\(friendRequest.id)"))

        batch.commit()
    }

    func delete(friendsAtIndex indexSet: IndexSet) {
        guard let index = indexSet.first else { return }
        let friend = friends[index]

        let batch = database.batch()

        let myFriends = user.friends.removing(friend.id)
        batch.updateData(["friends": myFriends], forDocument: database.document("users/\(user.id)"))

        let theirFriends = friend.friends.removing(user.id)
        batch.updateData(["friends": theirFriends], forDocument: database.document("users/\(friend.id)"))

        batch.commit()
    }

    @MainActor
    func updateFriends() async throws {
        guard !user.friends.isEmpty else {
            friends = []
            return
        }

        let friends = try await database.collection("users")
            .whereField("id", in: user.friends)
            .getDocuments()
            .documents
            .decoded(asArrayOf: User.self)

        for (index, friend) in friends.enumerated() {
            let activitySummary = try await database.collection("users/\(friend.id)/activitySummaries")
                .getDocuments()
                .documents
                .decoded(asArrayOf: ActivitySummary.self)
                .first { $0.date.isToday }

            friends[index].tempActivitySummary = activitySummary
        }

        self.friends = friends
    }

    @MainActor
    func updateFriendRequests() async throws {
        guard !user.incomingFriendRequests.isEmpty else {
            friendRequests = []
            return
        }

        self.friendRequests = try await database.collection("users")
            .whereField("id", in: user.incomingFriendRequests)
            .getDocuments()
            .documents
            .decoded(asArrayOf: User.self)
    }

    // MARK: - Private Methods
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        Resolver.Name.mode = .mock
        return Group {
            HomeView()
                .environmentObject(User.mock)
        }
    }
}
