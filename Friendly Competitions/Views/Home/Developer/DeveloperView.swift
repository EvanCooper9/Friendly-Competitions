import ECKit
import Factory
import SwiftUI

struct DeveloperView: View {

    @StateObject private var viewModel = DeveloperViewModel()

    var body: some View {
        List {
            Section(L10n.Developer.Environment.title) {
                HStack {
                    Text(L10n.Developer.Environment.environmentType)
                    Spacer()
                    Picker("", selection: $viewModel.environmentType) {
                        ForEach(FirestoreEnvironment.EnvironmentType.allCases) { environment in
                            Text(environment.rawValue).tag(environment)
                        }
                    }
                }
                if viewModel.environmentType == .debug {
                    HStack {
                        Text(L10n.Developer.Environment.Emulation.type)
                        Spacer()
                        Picker("", selection: $viewModel.environmentEmulationType) {
                            ForEach(FirestoreEnvironment.EmulationType.allCases) { emulation in
                                Text(emulation.rawValue).tag(emulation)
                            }
                        }
                    }
                    if viewModel.environmentEmulationType == .custom {
                        HStack {
                            Text(L10n.Developer.Environment.Emulation.destination)
                            TextField("", text: $viewModel.emulationDestination)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }

                Button(L10n.Generics.save, action: viewModel.saveTapped)
            }
        }
        .navigationBarTitle(L10n.Developer.title)
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
