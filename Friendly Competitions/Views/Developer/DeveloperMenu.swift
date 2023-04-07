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
        } label: {
            Image(systemName: .hammerCircleFill)
        }
        .alert("Environment Destination", isPresented: $viewModel.showDestinationAlert) {
            TextField("Destination", text: $viewModel.destination)
                .textInputAutocapitalization(.never)
                .font(.body)
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
