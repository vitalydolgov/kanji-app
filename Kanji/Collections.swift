struct Stack<T> {
    private var arr = [T]()
    
    var isEmpty: Bool {
        arr.isEmpty
    }
    
    mutating func push(_ elt: T) {
        arr.append(elt)
    }
    
    mutating func pop() -> T? {
        guard !arr.isEmpty else {
            return nil
        }
        return arr.removeLast()
    }
}
