import Foundation

protocol SessionPr {
    associatedtype Card: CardPr
    func takeNext() async -> Card?
    func putBack(_ card: Card, guess: GuessResult) async
    func cardsLeft() async -> Int
}

actor Session<I: CardInteractorPr>: SessionPr where I.Instance == Card {
    private let deck: Deck<Card>
    private let interactor: I
    
    init(interactor: I) throws {
        self.interactor = interactor
        let cards = try interactor.fetchData()
        let maxNew = 20
        let newCards = cards.lazy
            .filter { $0.state == .new }
            .prefix(maxNew)
        let recallCards = cards.lazy
            .filter { $0.state == .learned }
            .prefix(maxNew - newCards.count)
        let repeatCards = cards.filter { $0.state == .repeat }
        self.deck = Deck(cards: repeatCards + Array(newCards) + Array(recallCards))
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
    
    func putBack(_ card: Card, guess: GuessResult) async {
        var card = card
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
