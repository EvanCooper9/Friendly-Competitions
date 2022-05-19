import SwiftUI

struct FriendView: View {

    let friend: User
    
    @StateObject private var viewModel: FriendViewModel
    
    @State private var showConfirmDelete = false
    
    init(friend: User) {
        self.friend = friend
        _viewModel = .init(wrappedValue: .init(friend: friend))
    }
    
    var body: some View {
        List {
            Section("Today's activity") {
                ActivitySummaryInfoView(activitySummary: viewModel.activitySummary)
            }

            Section("Stats") {
                StatisticsView(statistics: viewModel.statistics)
            }

            Section {
                Button(toggling: $showConfirmDelete) {
                    Label("Remove friend", systemImage: .personCropCircleBadgeMinus)
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle(friend.name)
        .confirmationDialog("Are you sure?", isPresented: $viewModel.showDeleteConfirmation, titleVisibility: .visible) {
            Button("Yes", role: .destructive, action: viewModel.confirm)
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
            .setupMocks()
            .embeddedInNavigationView()
    }
}
