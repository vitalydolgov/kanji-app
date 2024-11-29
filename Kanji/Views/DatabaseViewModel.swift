import Foundation

final class DatabaseViewModel<I: CardInteractorPr>: ObservableObject {
    @Published var cards = [Card]()
    @Published var showingDeleteConfirmation = false
    var filteredRecordsNum = 0
    let didSavePub: NotificationCenter.Publisher
    private let interactor: I

    init(interactor: I) {
        self.interactor = interactor
        self.didSavePub = interactor.didSavePub
    }

    func fetchData() throws {
        cards = Array(try interactor.fetchData())
    }
    
    func updateState(for card: Card, with state: CardState) throws {
        card.state = state
        try interactor.save()
    }
    
    func deleteAllData() throws {
        try interactor.deleteAllData()
    }
    
    func filter(by string: String) -> [Card] {
        if string.isEmpty {
            filteredRecordsNum = cards.count
            return cards
        }
        let filteredCards = cards.filter { card in
            guard let kanji = card.kanji else {
                return false
            }
            return string.contains(kanji.character)
        }
        filteredRecordsNum = filteredCards.count
        return filteredCards
    }
}
