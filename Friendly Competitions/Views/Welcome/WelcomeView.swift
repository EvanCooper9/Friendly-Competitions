import SwiftUI

struct WelcomeView: View {

    @StateObject private var viewModel = WelcomeViewModel()

    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 15) {
                AppIcon()
                VStack(alignment: .leading) {
                    Text(L10n.Welcome.welcomeTo)
                        .font(.title)
                        .bold()
                    Text(Bundle.main.name)
                        .font(.title)
                        .bold()
                        .foregroundColor(.blue)
                }
                Text(L10n.Welcome.description)
                    .font(.title3)
                    .foregroundColor(.secondaryLabel)
            }
            .maxHeight(.infinity)

            buttons
                .padding(.horizontal)
        }
        .confirmationDialog(L10n.Confirmation.areYouSure, isPresented: $viewModel.showAnonymousSignInConfirmation, titleVisibility: .visible) {
            Button(L10n.Generics.continue, action: viewModel.confirmAnonymousSignIn)
        } message: {
            Text(L10n.Welcome.anonymousDisclaimer)
        }
        .withLoadingOverlay(isLoading: viewModel.loading)
        .sheet(isPresented: $viewModel.showEmailSignIn) {
            EmailSignInView()
        }
        .animation(.default, value: viewModel.signInOptions)
    }

    @ViewBuilder
    private var buttons: some View {

        #if DEBUG
        DeveloperMenu()
            .font(.title)
            .padding()
        #endif

        ForEach(Array(viewModel.signInOptions.enumerated()), id: \.element.id) { index, option in
            switch option {
            case .anonymous:
                Button(action: viewModel.signInAnonymouslyTapped) {
                    Label(L10n.SignIn.anonymously, systemImage: .personCropCircleBadgeQuestionmarkFill)
                        .signInStyle()
                }
                .buttonStyle(.bordered)
                .zIndex(Double(viewModel.signInOptions.count - index))
                .id(option.id)
            case .apple:
                SignInWithAppleButton(action: viewModel.signInWithAppleTapped)
                    .zIndex(Double(viewModel.signInOptions.count - index))
                    .id(option.id)
            case .email:
                Button(action: viewModel.signInWithEmailTapped) {
                    Label(L10n.SignIn.email, systemImage: .envelopeFill)
                        .signInStyle()
                }
                .buttonStyle(.borderedProminent)
                .zIndex(Double(viewModel.signInOptions.count - index))
                .id(option.id)
            }
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))

        if viewModel.showMoreSignInOptionsButton {
            Divider()
                .padding(.vertical)
            Button("More options", action: viewModel.moreOptionsTapped)
        }
    }
}

extension Label {
    func signInStyle() -> some View {
        self.font(.title2.weight(.semibold))
            .padding(8)
            .frame(maxWidth: .infinity)
    }
}

#if DEBUG
struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
            .setupMocks()
    }
}
#endif
