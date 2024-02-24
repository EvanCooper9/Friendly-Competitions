import ECKit
import FCKit
import SwiftUI
import SwiftUIX

struct FeatureFlagOverrideView: View {

    @StateObject private var viewModel = FeatureFlagOverrideViewModel()

    @State private var doubleBindingToPresent: Binding<Double>?
    @State private var stringBindingToPresent: Binding<String>?

    var body: some View {
        List {
            ForEach(viewModel.listModels) { listModel in
                VStack(alignment: .leading) {
                    if let binding = viewModel.dataBinding(for: listModel, ofType: Bool.self) {
                        Toggle(listModel.name, isOn: binding)
                            .font(.footnote)
                            .monospaced()
                    } else if let binding = viewModel.dataBinding(for: listModel, ofType: Double.self) {
                        view(for: listModel, binding: binding) {
                            doubleBindingToPresent = binding
                        }
                    } else if let binding = viewModel.dataBinding(for: listModel, ofType: String.self) {
                        view(for: listModel, binding: binding) {
                            stringBindingToPresent = binding
                        }
                    }
                }
            }
        }
        .navigationTitle("Feature Flags")
        .embeddedInNavigationView()
        .searchable(text: $viewModel.searchText)
        .alert("Override", isPresented: .init(get: { doubleBindingToPresent != nil }, set: { _ in doubleBindingToPresent = nil })) {
            if let doubleBindingToPresent {
                let textBinding = Binding<String>(
                    get: { doubleBindingToPresent.wrappedValue.description },
                    set: { value in
                        guard let doubleValue = Double(value) else { return }
                        doubleBindingToPresent.wrappedValue = doubleValue
                    }
                )
                TextField("Destination", text: textBinding)
                    .textInputAutocapitalization(.never)
                    .font(.body)
                    .keyboardType(.numberPad)
            }
        }
        .alert("Override", isPresented: .init(get: { stringBindingToPresent != nil }, set: { _ in stringBindingToPresent = nil })) {
            if let stringBindingToPresent {
                TextField("Destination", text: stringBindingToPresent)
                    .textInputAutocapitalization(.never)
                    .font(.body)
            }
        }
        .overlay {
            if #available(iOS 17, *), viewModel.listModels.isEmpty {
                ContentUnavailableView.search(text: viewModel.searchText)
            }
        }
    }

    private func view<Value>(for listModel: FeatureFlagOverrideViewModel.ListModel, binding: Binding<Value>, onTap: @escaping () -> Void) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text(listModel.name)
                Spacer()
                if listModel.overridden {
                    Button("Clear") {
                        viewModel.clearOverride(for: listModel)
                    }
                    .font(.caption)
                }
            }
            Button("\(binding.wrappedValue)", action: onTap)
                .buttonStyle(.bordered)
        }
        .font(.footnote)
        .monospaced()
    }
}

#if DEBUG
struct FeatureFlagOverrideView_Previews: PreviewProvider {

    static func setupMocks() {
        featureFlagManager.valueForBoolFeatureFlagFeatureFlagBoolBoolReturnValue = false
        featureFlagManager.valueForDoubleFeatureFlagFeatureFlagDoubleDoubleReturnValue = 0.1
        featureFlagManager.valueForStringFeatureFlagFeatureFlagStringStringReturnValue = "test"
        featureFlagManager.isOverriddenFlagFeatureFlagBoolBoolReturnValue = true
        featureFlagManager.isOverriddenFlagFeatureFlagDoubleBoolReturnValue = false
        featureFlagManager.isOverriddenFlagFeatureFlagStringBoolReturnValue = false
    }

    static var previews: some View {
        FeatureFlagOverrideView()
            .setupMocks(setupMocks)
    }
}
#endif
