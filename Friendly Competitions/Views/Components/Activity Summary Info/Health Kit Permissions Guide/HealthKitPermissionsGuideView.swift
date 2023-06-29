import SwiftUI

struct HealthKitPermissionsGuideView: View {

    @StateObject private var viewModel = HealthKitPermissionsGuideViewModel()

//    init() {
//        let viewModel = HealthKitPermissionsGuideViewModel()
//        _viewModel = .init(wrappedValue: viewModel)
//    }

    var body: some View {
//        TabView {
//            Summary()
            Summary()
//        }
//        .tabViewStyle(.page(indexDisplayMode: .always))
        .padding(.extraExtraLarge)
        .background(.red)
    }
}

private struct Summary: View {
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                Text("Some title")
                    .redacted(reason: .placeholder)
                Text("Some content")
//                    .maxWidth(.infinity)
//                    .padding(.extraLarge)
                    .redacted(reason: .placeholder)
                Spacer()
            }
            .navigationTitle("Summary")
        }
        .frame(height: 500)
    }
}

#if DEBUG
struct HealthKitPermissionsGuideView_Previews: PreviewProvider {
    static var previews: some View {
        HealthKitPermissionsGuideView()
            .setupMocks()
    }
}
#endif
