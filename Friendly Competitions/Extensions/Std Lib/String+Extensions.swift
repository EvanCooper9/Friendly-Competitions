extension String {
    func after(prefix: String) -> String? {
        guard starts(with: prefix) else { return nil }
        return String(dropFirst(prefix.count))
    }

    func before(suffix: String) -> String? {
        guard hasSuffix(suffix) else { return nil }
        return String(dropLast(suffix.count))
    }
}
