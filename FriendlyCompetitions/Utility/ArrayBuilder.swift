@resultBuilder
enum ArrayBuilder<Element> {
    static func buildEither(first component: [Element]) -> [Element] { component }
    static func buildEither(second component: [Element]) -> [Element] { component }
    static func buildOptional(_ component: [Element]?) -> [Element] { component ?? [] }
    static func buildExpression(_ expression: Element) -> [Element] { [expression] }
    static func buildExpression(_ expression: ()) -> [Element] { [] }
    static func buildBlock(_ components: [Element]...) -> [Element] { components.flatMap { $0 } }
    static func buildArray(_ components: [[Element]]) -> [Element] { Array(components.joined()) }
}

extension Array {
    static func build(@ArrayBuilder<Element> _ builder: () -> [Element]) -> [Element] {
        self.init(builder())
    }
}
