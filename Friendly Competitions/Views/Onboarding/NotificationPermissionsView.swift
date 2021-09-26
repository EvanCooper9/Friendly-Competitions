import SwiftUI
import Contacts
import Resolver

struct NotificationPermissionsView: View {

    @ObservedObject private var viewModel = NotificationPermissionsViewModel()

    let done: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: "app.badge")
                .foregroundColor(.pink)
                .font(.system(size: 100))
            Text("Notification Permissions")
                .font(.title)
            Text("So you can stay up to date")
                .multilineTextAlignment(.center)
            Spacer()
            Button(action: { viewModel.requestAccess(completion: done) }) {
                Text("Continue")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .background(Color.pink)
                    .cornerRadius(10)
            }
        }
        .padding()
        .padding(.bottom, 30)
    }
}

fileprivate final class NotificationPermissionsViewModel: ObservableObject {

    @LazyInjected private var notificationManager: NotificationManaging

    func requestAccess(completion: @escaping () -> Void) {
        notificationManager.requestPermissions { _, _ in
            DispatchQueue.main.async {
                completion()
            }
        }
    }
}

struct NotificationPermissionsView_Previews: PreviewProvider {
    static var previews: some View {
        TabView {
            NotificationPermissionsView(done: {})
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
    }
}
