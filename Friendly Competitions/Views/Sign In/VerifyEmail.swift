import SwiftUI

struct VerifyEmail: View {
    
    @EnvironmentObject private var authenticationManager: AnyAuthenticationManager
    @EnvironmentObject private var userManager: AnyUserManager
    
    var body: some View {
        VStack(spacing: 50) {
            
            Button("Sign in", systemImage: "chevron.left") {
                try authenticationManager.signOut()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            Image(systemName: "envelope.badge")
                .font(.system(size: 100))
                .padding(50)
                .background(Color(uiColor: .systemGray6))
                .clipShape(Circle())
            
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Verify your account")
                    .font(.title)
                    .padding(.bottom, -5)
                Text("Follow the instructions sent to \(userManager.user.email) to complete your account")
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundColor(.gray)
                Button("Send again", systemImage: "paperplane.fill") {
                    try await authenticationManager.resendEmailVerification()
                }
            }
            
            Spacer()
            Spacer()
            Spacer()
        }
        .padding(.horizontal)
        .onAppear(perform: pollCheckEmail)
    }
    
    private func pollCheckEmail() {
        Task.detached(priority: .low) {
            guard await !authenticationManager.emailVerified else { return }
            try await authenticationManager.checkEmailVerification()
            try await Task.sleep(nanoseconds: 1_000_000_000)
            await pollCheckEmail()
        }
    }
}

struct VerifyEmail_Previews: PreviewProvider {
    static var previews: some View {
        VerifyEmail()
            .setupMocks()
    }
}
