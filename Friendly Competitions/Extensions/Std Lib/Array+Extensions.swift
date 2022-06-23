extension Array {
    func appending(_ element: Element) -> Array<Element> {
        var a = self
        a.append(element)
        return a
    }

    func appending(contentsOf elements: Array<Element>) -> Array<Element> {
        var a = self
        a.append(contentsOf: elements)
        return a
    }
    
    var isNotEmpty: Bool { !isEmpty }
}

extension Array where Element: Equatable {
    mutating func remove(_ element: Element) {
        guard let index = firstIndex(of: element) else { return }
        remove(at: index)
    }

    func removing(_ element: Element) -> Array<Element> {
        var a = self
        a.remove(element)
        return a
    }

    mutating func toggle(_ element: Element) {
        contains(element) ? remove(element) : append(element)
    }
}
