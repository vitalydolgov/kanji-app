import Foundation

enum OperationType {
    case start
    case take
    case markGood
    case markRepeat
}

struct Operation {
    let type: OperationType
    var succeeded = true
}

enum OperationError: Error {
    case cannotPerform
}

struct OperationHistory {
    private var stack = Stack<Operation>()
    
    var isEmpty: Bool {
        stack.isEmpty
    }
    
    mutating func add(_ operation: Operation) {
        stack.push(operation)
    }
    
    mutating func remove() -> Operation? {
        guard !stack.isEmpty else {
            return nil
        }
        return stack.pop()
    }
}

struct OperationDispatch<S: SessionPr & Updatable> where S.OperationID == UUID {
    static func execute(_ operation: Operation, for session: S) {
        var operation = operation
        do {
            switch operation.type {
            case .start:
                try StartOperation.execute(for: session)
            case .take:
                try TakeOperation.execute(for: session)
            case .markGood:
                MarkGoodOperation.execute(for: session)
            case .markRepeat:
                MarkRepeatOperation.execute(for: session)
            }
        } catch {
            operation.succeeded = false
        }
        session.pushOperation(operation)
        session.update(UUID())
    }
    
    static func unexecute(for session: S, count: Int) {
        for _ in 1 ... count {
            guard let operation = session.popOperation() else {
                return
            }
            guard operation.succeeded else {
                continue
            }
            switch operation.type {
            case .start:
                StartOperation.unexecute(for: session)
            case .take:
                TakeOperation.unexecute(for: session)
            case .markGood:
                MarkGoodOperation.unexecute(for: session)
            case .markRepeat:
                MarkRepeatOperation.unexecute(for: session)
            }
        }
        session.update(UUID())
    }
}

private protocol OperationProtocol {
    associatedtype T
    static func execute(for obj: T) throws
    static func unexecute(for obj: T)
}

private struct StartOperation<S: SessionPr>: OperationProtocol {
    static func execute(for session: S) throws {
        try session.start()
    }
    
    static func unexecute(for session: S) {
        session.backToStart()
    }
}

private struct TakeOperation<S: SessionPr>: OperationProtocol {
    static func execute(for session: S) throws {
        try session.takeNextCard()
    }
    
    static func unexecute(for session: S) {
        session.returnTakenCard()
    }
}

private struct MarkGoodOperation<S: SessionPr>: OperationProtocol {
    static func execute(for session: S) {
        session.markCard(as: .good)
    }
    
    static func unexecute(for session: S) {
        session.unmarkCard(as: .good)
    }
}

private struct MarkRepeatOperation<S: SessionPr>: OperationProtocol {
    static func execute(for session: S) {
        session.markCard(as: .again)
    }
    
    static func unexecute(for session: S) {
        session.unmarkCard(as: .again)
    }
}
