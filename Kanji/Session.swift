import Foundation
import Combine

protocol SessionPr {
    associatedtype Card: CardPr
    var takenCard: Card? { get }
    var cardsLeft: Int { get }
    func takeNextCard() throws
    func returnTakenCard()
    func markCard(as guess: GuessResult)
    func unmarkCard(as guess: GuessResult)
    func pushOperation(_ operation: Operation)
    func popOperation() -> Operation?
}

protocol Updatable {
    associatedtype OperationID
    var updatePub: PassthroughSubject<OperationID, Never> { get }
    func update(_ id: OperationID)
}

class Session<I: CardInteractorPr>: SessionPr, Updatable where I.Instance == Card {
    let updatePub = PassthroughSubject<UUID, Never>()
    private var operationHistory = OperationHistory()
    private var changeHistory = Stack<Card>()
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
    
    private static func getSettings(using provider: some SettingsProviderPr) -> Settings {
        guard let settings = provider.fetchSettings() else {
            return provider.default()
        }
        return settings
    }
    
    var takenCard: Card? {
        deck.takenCard
    }
    
    var cardsLeft: Int {
        deck.cardsLeft
    }
    
    func takeNextCard() throws {
        try deck.takeRandomCard()
    }
    
    func returnTakenCard() {
        deck.returnTakenCard()
    }
    
    func markCard(as guess: GuessResult) {
        guard var card = deck.takenCard else {
            assertionFailure(); return
        }
        changeHistory.push(card)
        switch guess {
        case .good:
            card.state = switch card.state {
            case .new: .repeat
            case .repeat, .learned: .learned
            }
        case .again:
            card.state = .new
        }
        deck.putBackCard(card, success: guess == .good)
    }
    
    func unmarkCard(as guess: GuessResult) {
        guard let card = changeHistory.pop() else {
            assertionFailure(); return
        }
        deck.replaceCard(card, prevGuess: guess)
    }
    
    func saveCards() throws {
        let cards = deck.allCards
        try interactor.saveCards(cards)
    }
    
    func pushOperation(_ operation: Operation) {
        operationHistory.add(operation)
    }
    
    func popOperation() -> Operation? {
        operationHistory.remove()
    }
    
    func update(_ id: UUID) {
        updatePub.send(id)
    }
}

enum GuessResult {
    case good, again
    
    var operation: OperationType {
        switch self {
        case .good: .markGood
        case .again: .markRepeat
        }
    }
}
