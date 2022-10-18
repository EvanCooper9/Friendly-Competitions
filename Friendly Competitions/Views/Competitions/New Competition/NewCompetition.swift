import ECKit
import Factory
import SwiftUI
import SwiftUIX
import HealthKit

struct NewCompetition: View {
    
    @StateObject private var viewModel = NewCompetitionViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var presentAddFriends = false

    var body: some View {
        Form {
            CompetitionInfo(
                competition: $viewModel.competition,
                editing: true,
                canSaveEdits: { _ in }
            )

            friendsView

            Section {
                Button("Create", action: viewModel.create)
                    .disabled(viewModel.createDisabled)
                    .frame(maxWidth: .infinity)
            } footer: {
                Text(viewModel.disabledReason ?? "")
            }
        }
        .navigationTitle("New Competition")
        .embeddedInNavigationView()
        .sheet(isPresented: $presentAddFriends) { InviteFriends(action: .addFriend) }
        .registerScreenView(name: "New Competition")
        .onChange(of: viewModel.dismiss) { _ in dismiss() }
    }

    private var friendsView: some View {
        Section("Invite friends") {
            if viewModel.friendRows.isEmpty {
                LazyHStack {
                    Text("Nothing here, yet!")
                    Button("Add friends.", toggling: $presentAddFriends)
                }
                .padding(.vertical, 6)
            }

            ForEach(viewModel.friendRows) { rowConfig in
                HStack {
                    Text(rowConfig.name)
                    Spacer()
                    if rowConfig.invited {
                        Image(systemName: .checkmarkCircleFill)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture(perform: rowConfig.onTap)
            }
        }
    }
}

#if DEBUG
struct NewCompetitionView_Previews: PreviewProvider {

    private static func setupMocks() {
        friendsManager.friends = .just([.gabby])
    }

    static var previews: some View {
        NewCompetition()
            .setupMocks(setupMocks)
    }
}
#endif
