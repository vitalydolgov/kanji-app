import SwiftUI

final class FocusedWindow: ObservableObject {
    let type: FocusedWindowType
    
    init(_ type: FocusedWindowType) {
        self.type = type
    }
}

enum FocusedWindowType {
    case database
}

struct FocusedWindowValueKey: FocusedValueKey {
    typealias Value = FocusedWindow
}

extension FocusedValues {
    typealias FocusedWindow = FocusedWindowValueKey
    
    var window: FocusedWindow.Value? {
        get {
            self[FocusedWindow.self]
        }
        set {
            self[FocusedWindow.self] = newValue
        }
    }
}
