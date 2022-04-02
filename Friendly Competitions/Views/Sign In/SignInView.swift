import SwiftUI

struct SignInView: View {

    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel = SignInViewModel()
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        VStack(spacing: 10) {
            Spacer()
            Image("logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding()
                .background(content: {
                    ActivityRingView(activitySummary: nil)
                        .clipShape(Circle())
                        .if(!isPreview) { v in
                            v.shadow(radius: 10)
                        }
                })
            
            Spacer()
            Text("Friendly Competitions")
                .font(.largeTitle)
                .fontWeight(.light)
            Text("Compete against groups of friends in fitness.")
                .fontWeight(.light)
                .multilineTextAlignment(.center)
            Spacer()
            if viewModel.isLoading { ProgressView() }
            SignInWithAppleButton()
                .frame(maxWidth: .infinity, maxHeight: 60)
                .onTapGesture(perform: viewModel.signInWithApple)
                .disabled(viewModel.isLoading)
        }
        .padding()
        .background(content: {
            let color: Color = {
                switch colorScheme {
                case .dark:
                    return .black
                default:
                    return Color(red: 242/255, green: 242/255, blue: 247/255)
                }
            }()
            color.ignoresSafeArea()
        })
        .registerScreenView(name: "Sign In")
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView()
        SignInView()
            .preferredColorScheme(.dark)
    }
}
