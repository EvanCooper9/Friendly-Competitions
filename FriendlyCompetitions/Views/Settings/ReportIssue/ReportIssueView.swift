import SwiftUI

struct ReportIssueView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ReportIssueViewModel()

    var body: some View {
        Form {
            TextField("Title", text: $viewModel.title)
            TextField("Description", text: $viewModel.description)
            Button("Submit", action: viewModel.submit)
        }
        .withLoadingOverlay(isLoading: viewModel.loading)
        .errorAlert(error: $viewModel.error)
        .alert("Issue submitted", isPresented: $viewModel.showSuccess) {
            Button("Ok") { dismiss() }
        } message: {
            Text("Your issue has been submitted. We will review it as soon as possible.")
        }
        .navigationTitle("Report an issue")
    }
}

#if DEBUG
struct ReportIssueView_Previews: PreviewProvider {
    static var previews: some View {
        setupMocks {
            storageManager.setDataReturnValue = .just(())
                .delay(for: .seconds(2), scheduler: RunLoop.main)
                .eraseToAnyPublisher()
        }
        return ReportIssueView()
            .embeddedInNavigationView()
    }
}
#endif
