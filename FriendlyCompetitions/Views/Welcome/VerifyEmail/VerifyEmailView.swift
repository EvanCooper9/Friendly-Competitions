import Factory
import SwiftUI

struct VerifyEmailView: View {

    @StateObject private var viewModel = VerifyEmailViewModel()

    var body: some View {
        VStack(spacing: 50) {

            Button(L10n.VerifyEmail.signIn, systemImage: .chevronLeft, action: viewModel.back)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            Image(systemName: .envelopeBadge)
                .font(.system(size: 100))
                .padding(50)
                .background(Color(uiColor: .systemGray6))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 10) {
                Text(L10n.VerifyEmail.title)
                    .font(.title)
                    .padding(.bottom, -5)
                if let email = viewModel.user.email {
                    Text(L10n.VerifyEmail.instructions(email))
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundColor(.gray)
                }
                Button(L10n.VerifyEmail.sendAgain, systemImage: .paperplaneFill, action: viewModel.resendVerification)
            }

            Spacer()
            Spacer()
            Spacer()
        }
        .padding(.horizontal)
    }
}

#if DEBUG
struct VerifyEmailView_Previews: PreviewProvider {
    static var previews: some View {
        VerifyEmailView()
            .setupMocks()
    }
}
#endif
