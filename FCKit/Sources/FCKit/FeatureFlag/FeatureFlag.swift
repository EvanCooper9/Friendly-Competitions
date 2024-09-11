public protocol FeatureFlag: CaseIterable, RawRepresentable {
    associatedtype Data: Codable
    var stringValue: String { get }
    var defaultValue: Data { get }
}

extension FeatureFlag where RawValue == String {
    public var stringValue: String { rawValue }
}
