import Foundation

final class DatabaseViewModel<I: CardInteractorPr, T: Transformer>: ObservableObject
                             where I.Record == T, I.Instance == Card {
    typealias TransformedCard = TransformedValue<T.PersistenceID, Card>
    
    @Published var cards = [TransformedCard]()
    @Published var showingDeleteConfirmation = false
    let didSavePub: NotificationCenter.Publisher
    private let interactor: I

    init(interactor: I) {
        self.interactor = interactor
        self.didSavePub = interactor.didSavePub
    }

    func fetchData() throws {
        cards = Array(try interactor.fetchData())
    }
    
    func updateState(for card: TransformedCard, with state: CardState) throws {
        try interactor.updateState(for: card, with: state)
    }
    
    func deleteAllData() throws {
        try interactor.deleteAllData()
    }
}
