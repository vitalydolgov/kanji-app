import Foundation
import Combine

final class SettingsViewModel<I: SettingsProviderPr>: ObservableObject {
    @Published var items = [SettingsItemViewModel]()
    private var settings: Settings
    private var saveEventSubsc: AnyCancellable?
    private let saveEvent = PassthroughSubject<(), Never>()
    private let interactor: I
    
    init(interactor: I) {
        self.settings = interactor.fetchSettings() ?? interactor.default()
        self.interactor = interactor
        setupSubscriptions()
        setupItems()
    }
    
    private func setupSubscriptions() {
        saveEventSubsc = saveEvent
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [self] _ in
                do {
                    try interactor.saveSettings(settings)
                } catch {
                    assertionFailure()
                }
            }
    }
    
    private func setupItems() {
        let maxCardsTotal = SettingsItemViewModel(label: "Total maximum of cards",
                                                  value: NonnegIntegerSettingsItem(settings.maxCardsTotal),
                                                  formatter: NonnegIntegerSettingsItemFormatter()) { [weak self] item in
            guard let self, let item = item as? NonnegIntegerSettingsItem, item.isValid else {
                assertionFailure(); return
            }
            settings.maxCardsTotal = item.value
            saveEvent.send(())
        }
        let maxAdditionalCards = SettingsItemViewModel(label: "Maximum of additional cards",
                                                       value: NonnegIntegerSettingsItem(settings.maxAdditionalCards),
                                                       formatter: NonnegIntegerSettingsItemFormatter()) { [weak self] item in
            guard let self, let item = item as? NonnegIntegerSettingsItem, item.isValid else {
                assertionFailure(); return
            }
            settings.maxAdditionalCards = item.value
            saveEvent.send(())
        }
        let newLearnedRatio = SettingsItemViewModel(label: "Percentage of new cards",
                                                    value: Float01SettingsItem(settings.newLearnedRatio),
                                                    formatter: Float01SettingsItemFormatter()) { [weak self] item in
            guard let self, let item = item as? Float01SettingsItem, item.isValid else {
                assertionFailure(); return
            }
            settings.newLearnedRatio = item.value
            saveEvent.send(())
        }
        items = [maxCardsTotal, maxAdditionalCards, newLearnedRatio]
    }
}
