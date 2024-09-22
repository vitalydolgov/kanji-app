import Foundation
import Combine

final class SettingsViewModel<I: SettingsProviderPr>: ObservableObject {
    @Published var maxAdditionalCards: Int {
        didSet(newValue) {
            maxAdditionalCardsSubj.send(newValue)
        }
    }
    @Published var newLearnedRatio: Double {
        didSet(newValue) {
            newLearnedRatioSubj.send(newValue)
        }
    }
    
    private var subscriptions = Set<AnyCancellable>()
    private let maxAdditionalCardsSubj = PassthroughSubject<Int, Never>()
    private let newLearnedRatioSubj = PassthroughSubject<Double, Never>()
    private let interactor: I
    
    init(interactor: I) {
        let settings = interactor.fetchSettings() ?? interactor.default
        self.maxAdditionalCards = settings.maxAdditionalCards
        self.newLearnedRatio = settings.newLearnedRatio
        self.interactor = interactor
    }
    
    func setupSubscriptions() {
        maxAdditionalCardsSubj.combineLatest(newLearnedRatioSubj)
            .debounce(for: .seconds(2), scheduler: DispatchQueue.main)
            .filter { maxAdditionalCards, newLearnedRatio in
                guard maxAdditionalCards >= 0, (0 ..< 1).contains(newLearnedRatio) else {
                    return false
                }
                return true
            }
            .map { maxAdditionalCards, newLearnedRatio in
                Settings(maxAdditionalCards: maxAdditionalCards,
                         newLearnedRatio: newLearnedRatio)
            }.sink { settings in
                try? self.interactor.saveSettings(settings)
            }
            .store(in: &subscriptions)
    }
}
