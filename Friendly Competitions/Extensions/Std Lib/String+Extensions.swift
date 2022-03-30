extension String {
    func after(prefix: String) -> String? {
        guard starts(with: prefix) else { return nil }
        return String(dropFirst(prefix.count))
    }

    func before(suffix: String) -> String? {
        guard hasSuffix(suffix) else { return nil }
        return String(dropLast(suffix.count))
    }

    func ifEmpty(_ string: String) -> String {
        isEmpty ? string : self
    }
}

extension Optional where Wrapped == String {
    var emptyIfNil: String {
        switch self {
        case .none:
            return ""
        case .some(let wrapped):
            return wrapped
        }
    }
}
