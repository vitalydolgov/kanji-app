import Foundation
import Combine

final class SettingsItemViewModel: ObservableObject, Identifiable {
    @Published var value: any SettingsItem {
        didSet(newValue) {
            update(newValue)
        }
    }
    private var subscription: AnyCancellable?
    let label: String
    let formatter: Formatter
    private let update: (any SettingsItem) -> ()
    private let subject = PassthroughSubject<any SettingsItem, Never>()
    
    init(label: String,
         value: any SettingsItem,
         formatter: Formatter,
         update: @escaping (any SettingsItem) -> ())
    {
        self.label = label
        self.value = value
        self.formatter = formatter
        self.update = update
    }
    
    func connect(with receiver: PassthroughSubject<any SettingsItem, Never>) {
        subscription = subject.sink { value in
            receiver.send(value)
        }
    }
}

protocol SettingsItem {
    associatedtype T
    var value: T { get }
    var isValid: Bool { get }
}

final class NonnegIntegerSettingsItem: SettingsItem {
    let value: Int
    
    init(_ value: Int) {
        self.value = value
    }
    
    var isValid: Bool {
        value >= 0
    }
}

final class NonnegIntegerSettingsItemFormatter: Formatter {
    override func string(for obj: Any?) -> String? {
        guard let item = obj as? NonnegIntegerSettingsItem else {
            return nil
        }
        return String(item.value)
    }
    
    override
    func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?,
                        for string: String,
                        errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?)
    -> Bool {
        guard let value = Int(string) else {
            return false
        }
        obj?.pointee = NonnegIntegerSettingsItem(value)
        return true
    }
}

final class Float01SettingsItem: SettingsItem {
    let value: Double
    
    init(_ value: Double) {
        self.value = value
    }
    
    var isValid: Bool {
        (0 ... 1).contains(value)
    }
}

final class Float01SettingsItemFormatter: Formatter {
    override func string(for obj: Any?) -> String? {
        guard let item = obj as? Float01SettingsItem else {
            return nil
        }
        return String(item.value)
    }
    
    override
    func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?,
                        for string: String,
                        errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?)
    -> Bool {
        guard let value = Double(string) else {
            return false
        }
        obj?.pointee = Float01SettingsItem(value)
        return true
    }
}
