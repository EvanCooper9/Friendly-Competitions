import ECKit
import Factory
import SwiftUI

struct DeveloperMenu: View {

    @StateObject private var viewModel = DeveloperMenuViewModel()

    var body: some View {
        Menu {
            Picker("", selection: $viewModel.environment) {
                ForEach(DeveloperMenuViewModel.UnderlyingEnvironment.allCases) { environment in
                    Text(viewModel.text(for: environment))
                        .tag(environment)
                }
            }
            Button(action: viewModel.featureFlagButtonTapped) {
                Label("Feature flags", systemImage: .flagFill)
            }
        } label: {
            Image(systemName: .hammerCircleFill)
        }
        .registerScreenView(name: "Developer")
        .alert("Environment Destination", isPresented: $viewModel.showDestinationAlert) {
            TextField("Destination", text: $viewModel.destination)
                .textInputAutocapitalization(.never)
                .font(.body)
        }
        .sheet(isPresented: $viewModel.showFeatureFlag) {
            FeatureFlagOverrideView()
        }
    }
}

#if DEBUG
struct DeveloperMenu_Previews: PreviewProvider {
    static var previews: some View {
        DeveloperMenu()
            .setupMocks()
    }
}
#endif
