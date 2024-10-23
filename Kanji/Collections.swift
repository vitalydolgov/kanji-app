struct Stack<T> {
    private var arr = [T]()
    
    var count: Int {
        arr.count
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
