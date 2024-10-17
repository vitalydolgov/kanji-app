import Foundation

protocol SessionPr {
    associatedtype Card: CardPr
    func takeNext() async -> Card?
    func putBack(guess: GuessResult) async
    func cardsLeft() async -> Int
}

actor Session<I: CardInteractorPr>: SessionPr where I.Instance == Card {
    private let deck: Deck<Card>
    private let interactor: I
    
    init(interactor: I, settingsProvider: some SettingsProviderPr) throws {
        let settings = Self.getSettings(using: settingsProvider)
        let maxAdditonalCards = settings.maxAdditionalCards
        let newLearnedRatio = settings.newLearnedRatio
        let maxNewCards = Int(Double(maxAdditonalCards) * newLearnedRatio)
        let newCards = try interactor.fetchData()
            .filter { $0.state == .new }
            .prefix(maxNewCards)
        let recallCards = try interactor.fetchDataRandomized()
            .filter { $0.state == .learned }
            .prefix(maxAdditonalCards - newCards.count)
        let repeatCards = try interactor.fetchDataRandomized()
            .filter { $0.state == .repeat }
        self.interactor = interactor
        self.deck = Deck(cards: repeatCards + Array(newCards) + Array(recallCards))
    }
    
    private static func getSettings(
        using provider: some SettingsProviderPr
    ) -> Settings {
        guard let settings = provider.fetchSettings() else {
            return provider.default()
        }
        return settings
    }
    
    func cardsLeft() async -> Int {
        await deck.cardsLeft
    }
    
    func takeNext() async -> Card? {
        guard let card = await deck.takeRandomCard() else {
            return nil
        }
        return card
    }
    
    func putBack(guess: GuessResult) async {
        guard var card = await deck.takenCard else {
            assertionFailure(); return
        }
        switch guess {
        case .good:
            card.state = switch card.state {
            case .new: .repeat
            case .repeat, .learned: .learned
            }
        case .again:
            card.state = .new
        case .unknown:
            break
        }
        await deck.putBackCard(card, success: guess == .good)
    }
    
    func saveCards() async throws {
        let cards = await deck.allCards
        try interactor.saveCards(cards)
    }
}

enum GuessResult {
    case unknown, good, again
}
