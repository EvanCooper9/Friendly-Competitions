import ECKit
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
                    Text(AppInfo.name)
                        .foregroundLinearGradient(.init(colors: [
                            Asset.Colors.Branded.red.swiftUIColor,
                            Asset.Colors.Branded.green.swiftUIColor,
                            Asset.Colors.Branded.blue.swiftUIColor
                        ]))
                        .font(.title)
                        .bold()
                }
                Text(L10n.Welcome.description)
                    .font(.title3)
                    .foregroundColor(.secondaryLabel)
            }
            .maxHeight(.infinity)

            if viewModel.showDeveloper {
                DeveloperMenu()
                    .font(.title)
            }

            VStack {
                buttons
            }
            .padding(.top)
            .padding(.horizontal)
            .padding(.bottom, .extraLarge)
            .background(.tertiarySystemBackground)
            .cornerRadius(25, corners: [.topLeft, .topRight])
            .shadow(color: .gray.opacity(0.25), radius: 10)
        }
        .ignoresSafeArea()
        .animation(.default, value: viewModel.signInOptions)
        .navigationDestination(for: WelcomeNavigationDestination.self) { destination in
            VStack {
                destination.view
                Spacer()
            }
        }
        .embeddedInNavigationStack(path: $viewModel.navigationPath)
        .confirmationDialog(L10n.Confirmation.areYouSure, isPresented: $viewModel.showAnonymousSignInConfirmation, titleVisibility: .visible) {
            Button(L10n.Generics.continue, action: viewModel.confirmAnonymousSignIn)
        } message: {
            Text(L10n.Welcome.anonymousDisclaimer)
        }
        .withLoadingOverlay(isLoading: viewModel.loading)
    }

    @ViewBuilder
    private var buttons: some View {
        ForEach(enumerated: viewModel.signInOptions) { index, option in
            switch option {
            case .anonymous:
                Button(action: viewModel.signInAnonymouslyTapped) {
                    Label(L10n.SignIn.anonymously, systemImage: .personCropCircleBadgeQuestionmarkFill)
                        .signInStyle()
                }
                .buttonStyle(.bordered)
                .zIndex(Double(viewModel.signInOptions.count - index))
            case .apple:
                SignInWithAppleButton(action: viewModel.signInWithAppleTapped)
                    .zIndex(Double(viewModel.signInOptions.count - index))
            case .email:
                Button(action: viewModel.signInWithEmailTapped) {
                    Label(L10n.SignIn.email, systemImage: .envelopeFill)
                        .signInStyle()
                }
                .buttonStyle(.borderedProminent)
                .zIndex(Double(viewModel.signInOptions.count - index))
            }
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))

        if viewModel.showMoreSignInOptionsButton {
            Divider()
                .padding(.vertical)
            Button(L10n.CreateAccount.moreOptions, action: viewModel.moreOptionsTapped)
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
