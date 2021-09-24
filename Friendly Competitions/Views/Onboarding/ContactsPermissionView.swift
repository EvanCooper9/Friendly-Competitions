import SwiftUI
import Contacts

struct ContactsPermissionsView: View {

    @ObservedObject private var viewModel = ContactsPermissionsViewModel()

    let done: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: "person.text.rectangle")
                .foregroundColor(.pink)
                .font(.system(size: 100))
            Text("Contacts Permissions")
                .font(.title)
            Text("We need access to your contacts so you can find your friends!")
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

fileprivate final class ContactsPermissionsViewModel: ObservableObject {

    private let contactStore = CNContactStore()

    func requestAccess(completion: @escaping () -> Void) {
        contactStore.requestAccess(for: .contacts) { authorized, _ in
            DispatchQueue.main.async {
                completion()
            }
        }
    }

    func deny(completion: () -> Void) {
        completion()
    }
}

struct ContactsPermissionsView_Previews: PreviewProvider {
    static var previews: some View {
        TabView {
            ContactsPermissionsView(done: {})
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
    }
}
