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
                    Picker("", selection: $viewModel.environmentType) {
                        ForEach(FirestoreEnvironment.EnvironmentType.allCases) { environment in
                            Text(environment.rawValue).tag(environment)
                        }
                    }
                }
                if viewModel.environmentType == .debug {
                    HStack {
                        Text("Emulation type")
                        Spacer()
                        Picker("", selection: $viewModel.environmentEmulationType) {
                            ForEach(FirestoreEnvironment.EmulationType.allCases) { emulation in
                                Text(emulation.rawValue).tag(emulation)
                            }
                        }
                    }
                    if viewModel.environmentEmulationType == .custom {
                        HStack {
                            Text("Emulation destination")
                            TextField("Emulation destination", text: $viewModel.emulationDestination)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
                
                Button("Save", action: viewModel.saveTapped)
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
