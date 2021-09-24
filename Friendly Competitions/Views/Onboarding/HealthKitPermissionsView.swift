import SwiftUI
import HealthKit
import Resolver

struct HealthKitPermissionsView: View {

    @ObservedObject private var viewModel = HealthKitPermissionsViewModel()

    let done: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: "heart.fill")
                .foregroundColor(.pink)
                .font(.system(size: 100))
            Text("HealthKit Permissions")
                .font(.title)
            Text("We need access to HealthKit so you can compete against your friends!")
                .multilineTextAlignment(.center)
            Spacer()
            Button(action: { viewModel.requestAuthorization(completion: done) }) {
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

fileprivate final class HealthKitPermissionsViewModel: ObservableObject {

    @LazyInjected private var healthKitManager: HealthKitManaging

    func requestAuthorization(completion: @escaping () -> Void) {
        healthKitManager.requestPermissions { _, _ in
            DispatchQueue.main.async {
                completion()
            }
        }
    }
}

struct HealthKitPermissionsView_Previews: PreviewProvider {
    static var previews: some View {
        TabView {
            HealthKitPermissionsView(done: {})
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
    }
}
