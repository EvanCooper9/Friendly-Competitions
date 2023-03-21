extension Array where Element == Bool {
    func allTrue() -> Bool {
        allSatisfy { $0 }
    }
    
    func allFalse() -> Bool {
        allSatisfy { !$0 }
    }
}
