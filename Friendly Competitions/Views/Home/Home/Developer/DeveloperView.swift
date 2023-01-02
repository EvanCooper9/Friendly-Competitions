import ECKit
import Factory
import SwiftUI

struct DeveloperView: View {

    @StateObject private var viewModel = DeveloperViewModel()

    var body: some View {
        List {
            Section("Firebase Environment") {
                HStack {
                    Text("Environment type")
                    Spacer()
                    Picker("", selection: $viewModel.environment) {
                        ForEach(FirestoreEnvironment.EnvironmentType.allCases) { environment in
                            Text(environment.rawValue).tag(environment)
                        }
                    }
                }
                if viewModel.environment == .debug {
                    HStack {
                        Text("Emulation type")
                        Spacer()
                        Picker("", selection: $viewModel.emulation) {
                            ForEach(FirestoreEnvironment.EmulationType.allCases) { emulation in
                                Text(emulation.rawValue).tag(emulation)
                            }
                        }
                    }
                    if viewModel.emulation == .custom {
                        HStack {
                            Text("Emulation destination")
                            TextField("Emulation destination", text: $viewModel.emulationDestination)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
            }
        }
        .navigationBarTitle("Developer")
        .embeddedInNavigationView()
    }
}

#if DEBUG
struct DeveloperView_Previews: PreviewProvider {
    static var previews: some View {
        DeveloperView()
            .setupMocks()
    }
}
#endif
