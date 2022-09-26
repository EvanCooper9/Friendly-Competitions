import ECKit
import Resolver
import SwiftUI
import SwiftUIX
import HealthKit

struct NewCompetition: View {

    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel = Resolver.resolve(NewCompetitionViewModel.self)
    @State private var presentAddFriends = false

    var body: some View {
        Form {
            CompetitionInfo(
                competition: $viewModel.competition,
                editing: true,
                canSaveEdits: viewModel.canSaveEdits
            )
            friendsView
            Section {
                Button("Create") {
                    viewModel.create()
                    dismiss()
                }
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

struct NewCompetitionView_Previews: PreviewProvider {

    private static func setupMocks() {
        friendsManager.friends = .just([.gabby])
    }

    static var previews: some View {
        NewCompetition()
            .setupMocks(setupMocks)
    }
}
