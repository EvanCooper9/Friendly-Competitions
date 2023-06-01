import SwiftUI

struct WelcomeView: View {

    @StateObject private var viewModel = WelcomeViewModel()

    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 15) {
                AppIcon()
                VStack(alignment: .leading) {
                    Text("Welcome to")
                        .font(.title)
                        .bold()
                    Text("Friendly Competitions")
                        .font(.title)
                        .bold()
                        .foregroundColor(.blue)
                }
                Text("Compete against friends in fitness.")
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
            Text("Signing in anonymously will disable certain features like receiving notifications & creating compettions. However, you can always upgrade your account later.")
        }
        .withLoadingOverlay(isLoading: viewModel.loading)
        .sheet(isPresented: $viewModel.showEmailSignIn, content: EmailSignInView.init)
    }

    @ViewBuilder
    private var buttons: some View {
        SignInWithAppleButton(action: viewModel.signInWithAppleTapped)

        Button(action: viewModel.signInWithEmailTapped) {
            Label(L10n.SignIn.email, systemImage: .envelopeFill)
                .signInStyle()
        }
        .buttonStyle(.borderedProminent)

        Button(action: viewModel.signInAnonymouslyTapped) {
            Label("Sign in Anonymously", systemImage: .personCropCircleBadgeQuestionmarkFill)
                .signInStyle()
        }
        .buttonStyle(.bordered)
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
