import Factory
import SwiftUI

struct VerifyEmail: View {
    
    @StateObject private var viewModel = VerifyEmailViewModel()
    
    var body: some View {
        VStack(spacing: 50) {
            
            Button("Sign in", systemImage: "chevron.left", action: viewModel.back)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            Image(systemName: .envelopeBadge)
                .font(.system(size: 100))
                .padding(50)
                .background(Color(uiColor: .systemGray6))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Verify your account")
                    .font(.title)
                    .padding(.bottom, -5)
                Text("Follow the instructions sent to \(viewModel.user.email) to complete your account")
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundColor(.gray)
                Button("Send again", systemImage: .paperplaneFill, action: viewModel.resendVerification)
            }
            
            Spacer()
            Spacer()
            Spacer()
        }
        .padding(.horizontal)
    }
}

struct VerifyEmail_Previews: PreviewProvider {
    static var previews: some View {
        VerifyEmail()
            .setupMocks()
    }
}
