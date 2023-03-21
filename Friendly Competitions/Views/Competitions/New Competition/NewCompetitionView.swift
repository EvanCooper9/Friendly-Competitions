import ECKit
import Factory
import SwiftUI
import SwiftUIX
import HealthKit

struct NewCompetitionView: View {

    @StateObject private var viewModel = NewCompetitionViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var presentAddFriends = false

    var body: some View {
        Form {
            EditCompetitionSection(
                name: $viewModel.name,
                scoringModel: $viewModel.scoringModel,
                start: $viewModel.start,
                end: $viewModel.end,
                repeats: $viewModel.repeats,
                isPublic: $viewModel.isPublic
            )

            friends

            Section {
                Button(L10n.NewCompetition.create, action: viewModel.create)
                    .disabled(viewModel.createDisabled)
                    .frame(maxWidth: .infinity)
            } footer: {
                if let disabledReason = viewModel.disabledReason {
                    Text(disabledReason)
                }
            }
        }
        .navigationTitle(L10n.NewCompetition.titile)
        .embeddedInNavigationView()
        .sheet(isPresented: $presentAddFriends) { InviteFriendsView(action: .addFriend) }
        .registerScreenView(name: "New Competition")
        .withLoadingOverlay(isLoading: viewModel.loading)
        .onChange(of: viewModel.dismiss) { _ in dismiss() }
    }

    private var friends: some View {
        Section {
            ForEach($viewModel.friendRows) { $friend in
                HStack {
                    Text(friend.name)
                    Spacer()
                    if friend.invited {
                        Image(systemName: .checkmarkCircleFill)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { friend.onTap() }
            }

            if viewModel.friendRows.isEmpty {
                HStack {
                    Text(L10n.NewCompetition.Friends.nothingHere)
                    Button(L10n.NewCompetition.Friends.addFriends, toggling: $presentAddFriends)
                }
            }
        } header: {
            Text(L10n.NewCompetition.Friends.title)
        }
    }
}

#if DEBUG
struct NewCompetitionView_Previews: PreviewProvider {

    private static func setupMocks() {
        friendsManager.friends = .just([.gabby])
    }

    static var previews: some View {
        NewCompetitionView()
            .setupMocks(setupMocks)
    }
}
#endif
