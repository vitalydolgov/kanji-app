import Foundation

final class DatabaseViewModel<I: CardInteractorPr>: ObservableObject
                                                    where I.Instance == Card {
    @Published var cards = [Card]()
    @Published var showingDeleteConfirmation = false
    let didSavePub: NotificationCenter.Publisher
    private let interactor: I

    init(interactor: I) {
        self.interactor = interactor
        self.didSavePub = interactor.didSavePub
    }

    func fetchData() throws {
        cards = try interactor.fetchData()
    }
    
    func updateState(for card: Card, with state: CardState) throws {
        try interactor.updateState(for: card, with: state)
    }
    
    func deleteAllData() throws {
        try interactor.deleteAllData()
    }
}
