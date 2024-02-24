import Combine
import CombineExt
import ECKit
import Factory
import FCKit
import SwiftUI

final class FeatureFlagOverrideViewModel: ObservableObject {

    struct ListModel: Identifiable {
        let name: String
        let value: String
        let overridden: Bool

        var id: String { name }
    }

    // MARK: - Public Properties

    @Published private(set) var listModels = [ListModel]()
    @Published var searchText = ""

    // MARK: - Private Properties

    @Injected(\.featureFlagManager) private var featureFlagManager: FeatureFlagManaging

    private var flags = [ListModel.ID: any FeatureFlag]()
    private let recalculateListModelsSubject = PassthroughSubject<Void, Never>()

    private var cancellables = Cancellables()

    // MARK: - Lifecycle

    init() {
        let allListModelsPublisher = recalculateListModelsSubject
            .prepend(())
            .map { [weak self] in self?.calculateListModels() ?? [] }

        Publishers
            .CombineLatest($searchText, allListModelsPublisher)
            .map { text, allListModels in
                if text.isEmpty {
                    return allListModels
                } else {
                    return allListModels.filter { model in
                        model.name.localizedStandardContains(text)
                    }
                }
            }
            .assign(to: &$listModels)
    }

    // MARK: - Public Methods

    func dataBinding<Value>(for listModel: ListModel, ofType: Value.Type) -> Binding<Value>? {
        // swiftlint:disable force_cast
        if Value.self == Bool.self, let flag = flags[listModel.id] as? FeatureFlagBool {
            return Binding<Value>(
                get: { self.featureFlagManager.value(forBool: flag) as! Value },
                set: {
                    self.featureFlagManager.override(flag: flag, with: $0 as? Bool)
                    self.recalculateListModelsSubject.send()
                }
            )
        } else if Value.self == Double.self, let flag = flags[listModel.id] as? FeatureFlagDouble {
            return Binding<Value>(
                get: { self.featureFlagManager.value(forDouble: flag) as! Value },
                set: {
                    self.featureFlagManager.override(flag: flag, with: $0 as? Double)
                    self.recalculateListModelsSubject.send()
                }
            )
        } else if Value.self == String.self, let flag = flags[listModel.id] as? FeatureFlagString {
            return Binding<Value>(
                get: { self.featureFlagManager.value(forString: flag) as! Value },
                set: {
                    self.featureFlagManager.override(flag: flag, with: $0 as? String)
                    self.recalculateListModelsSubject.send()
                }
            )
        }
        // swiftlint:enable force_cast
        return nil
    }

    func clearOverride(for listModel: ListModel) {
        if let flag = flags[listModel.id] as? FeatureFlagBool {
            featureFlagManager.override(flag: flag, with: nil)
        } else if let flag = flags[listModel.id] as? FeatureFlagDouble {
            featureFlagManager.override(flag: flag, with: nil)
        } else if let flag = flags[listModel.id] as? FeatureFlagString {
            featureFlagManager.override(flag: flag, with: nil)
        }
        recalculateListModelsSubject.send()
    }

    // MARK: - Private Methods

    private func calculateListModels() -> [ListModel] {
        var allListModels = [ListModel]()
        FeatureFlagBool.allCases.forEach { flag in
            let model = ListModel(
                name: flag.stringValue,
                value: featureFlagManager.value(forBool: flag).description,
                overridden: featureFlagManager.isOverridden(flag: flag)
            )
            allListModels.append(model)
            flags[model.id] = flag
        }
        FeatureFlagDouble.allCases.forEach { flag in
            let model = ListModel(
                name: flag.stringValue,
                value: featureFlagManager.value(forDouble: flag).description,
                overridden: featureFlagManager.isOverridden(flag: flag)
            )
            allListModels.append(model)
            flags[model.id] = flag
        }
        FeatureFlagString.allCases.forEach { flag in
            let model = ListModel(
                name: flag.stringValue,
                value: featureFlagManager.value(forString: flag).description,
                overridden: featureFlagManager.isOverridden(flag: flag)
            )
            allListModels.append(model)
            flags[model.id] = flag
        }
        return allListModels
    }
}
