import ECKit
import Factory
import SwiftUI
import SwiftUIX

struct UserView: View {
    
    @StateObject private var viewModel: UserViewModel
        
    init(user: User) {
        _viewModel = .init(wrappedValue: .init(user: user))
    }
    
    var body: some View {
        List {
            Section {
                ActivitySummaryInfoView(activitySummary: viewModel.activitySummary)
            } header: {
                Text(L10n.User.Activity.title)
            }

            Section {
                MedalsView(statistics: viewModel.medals)
            } header: {
                Text(L10n.User.Medals.title)
            }

            Section {
                ForEach(viewModel.actions, id: \.self) { action in
                    Button {
                        viewModel.perform(action)
                    } label: {
                        Label(action.buttonTitle, systemImage: action.systemImage)
                            .if(action.destructive) { view in
                                view.foregroundColor(.red)
                            }
                    }
                }
            }
        }
        .navigationTitle(viewModel.title)
        .confirmationDialog(L10n.Confirmation.areYouSure, isPresented: $viewModel.confirmationRequired, titleVisibility: .visible) {
            Button(L10n.Generics.yes, role: .destructive, action: viewModel.confirm)
            Button(L10n.Generics.cancel, role: .cancel) {}
        }
        .withLoadingOverlay(isLoading: viewModel.loading)
        .registerScreenView(name: "User")
    }
}

struct UserView_Previews: PreviewProvider {
    static var previews: some View {
        UserView(user: .gabby)
            .setupMocks()
            .embeddedInNavigationView()
    }
}
