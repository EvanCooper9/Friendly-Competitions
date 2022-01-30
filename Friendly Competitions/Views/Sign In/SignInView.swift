import SwiftUI

struct SignInView: View {

    @State private var email = ""
    @State private var password = ""

    private let viewModel = SignInViewModel()

    var body: some View {
        VStack(spacing: 10) {
            Spacer()
            Text("Friendly Competitions")
                .font(.largeTitle)
                .fontWeight(.light)
            Spacer()
            Image("logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding()
                .background(
                    Circle()
                        .fill(.white)
                        .shadow(color: .white, radius: 10)
                )
            Text("Friendly Competitions allows you to compete against groups of friends in fitness.")
                .fontWeight(.light)
                .multilineTextAlignment(.center)
                .padding()
            Spacer()
            if viewModel.isLoading { ProgressView() }
            SignInWithAppleButton()
                .frame(maxWidth: .infinity, maxHeight: 60)
                .onTapGesture(perform: viewModel.signInWithApple)
                .disabled(viewModel.isLoading)
        }
        .padding()
        .background(Color(red: 242/255, green: 242/255, blue: 247/255))
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SignInView()
        }
    }
}
