import SwiftUI

struct SignInView: View {

    @State private var email = ""
    @State private var password = ""

    private let viewModel = SignInViewModel()

    var body: some View {
        VStack(spacing: 10) {
            Spacer()
            Image("logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
            Text("Welcome")
                .font(.title)
            Text("Friendly Competitions allows you to compete with friends. Sign in or Sign up to continue.")
                .multilineTextAlignment(.center)
            Spacer()
            if viewModel.isLoading { ProgressView() }
            SignInWithAppleButton()
                .frame(maxWidth: .infinity, maxHeight: 60)
                .onTapGesture(perform: viewModel.signInWithApple)
                .disabled(viewModel.isLoading)
        }
        .padding()
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SignInView()
        }
    }
}
