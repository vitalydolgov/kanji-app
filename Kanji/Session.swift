import Foundation
import Combine

protocol SessionPr {
    associatedtype Card: CardPr
    // state
    var takenCard: Card? { get }
    var cardsLeft: Int { get }
    var isStarted: Bool { get }
    var isFinished: Bool { get }
    // start/back
    func start() throws
    func backToStart()
    // take/return card
    func takeNextCard() throws
    func returnTakenCard()
    // mark/unmark card
    func markCard(as guess: GuessResult)
    func unmarkCard(as guess: GuessResult)
    // operation history
    func pushOperation(_ operation: Operation)
    func popOperation() -> Operation?
    // save/reset
    func saveCards() throws
    func reset()
}

protocol Updatable {
    associatedtype OperationID
    var updatePub: PassthroughSubject<OperationID, Never> { get }
    func update(_ id: OperationID)
}

final class Session<I: CardInteractorPr, S: SettingsProviderPr>: SessionPr, Updatable
                    where I.Record == CDCard, I.Instance == Card {
    let updatePub = PassthroughSubject<UUID, Never>()
    private var operationHistory = OperationHistory()
    private var changeHistory = Stack<Card>()
    private var deck = SessionDeck()
    private let interactor: I
    private let settingsProvider: S
    
    init(interactor: I, settingsProvider: S) {
        self.interactor = interactor
        self.settingsProvider = settingsProvider
    }
        
    var takenCard: Card? {
        deck.value.takenCard
    }
    
    var cardsLeft: Int {
        deck.value.cardsLeft
    }
    
    var isStarted: Bool {
        !operationHistory.isEmpty
    }
    
    var isFinished: Bool {
        !operationHistory.isEmpty && cardsLeft == 0
    }
    
    func reset() {
        operationHistory = OperationHistory()
        changeHistory = Stack()
        deck = SessionDeck()
    }
    
    func start() throws {
        let settings = getSettings(using: settingsProvider)
        let maxCardsTotal = settings.maxCardsTotal == 0 ? Int.max : settings.maxCardsTotal
        let repeatCards = try interactor.fetchDataRandomized()
            .filter { $0.value.state == .repeat }
        if repeatCards.count > maxCardsTotal {
            let originalCards = Array(repeatCards.prefix(maxCardsTotal))
            let cards = originalCards.map { $0.value }
            deck = SessionDeck(value: Deck(cards: cards), originalCards: originalCards)
            return
        }
        let maxAdditonalCards = min(maxCardsTotal - repeatCards.count, settings.maxAdditionalCards)
        let newLearnedRatio = settings.newLearnedRatio
        let maxNewCards = Int(Double(maxAdditonalCards) * newLearnedRatio)
        let newCards = try interactor.fetchData()
            .filter { $0.value.state == .new }
            .prefix(maxNewCards)
        let recallCards = try interactor.fetchDataRandomized()
            .filter { $0.value.state == .learned }
            .prefix(maxAdditonalCards - newCards.count)
        let originalCards = Array((repeatCards + newCards + recallCards).shuffled())
        let cards = originalCards.map { $0.value }
        deck = SessionDeck(value: Deck(cards: cards), originalCards: originalCards)
    }
    
    func backToStart() {
        assert(operationHistory.isEmpty)
        assert(changeHistory.isEmpty)
        deck = SessionDeck()
    }
    
    private func getSettings(using provider: some SettingsProviderPr) -> Settings {
        guard let settings = provider.fetchSettings() else {
            return provider.default()
        }
        return settings
    }
    
    func takeNextCard() throws {
        try deck.value.takeRandomCard()
    }
    
    func returnTakenCard() {
        deck.value.returnTakenCard()
    }
    
    func markCard(as guess: GuessResult) {
        guard var card = deck.value.takenCard else {
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
        deck.value.putBackCard(card, success: guess == .good)
    }
    
    func unmarkCard(as guess: GuessResult) {
        guard let card = changeHistory.pop() else {
            assertionFailure(); return
        }
        deck.value.replaceCard(card, prevGuess: guess)
    }
    
    func saveCards() throws {
        let deckCards = deck.value.allCards
        var results = [TransformedCard]()
        for var card in deck.originalCards {
            guard let updatedCard = deckCards.first(where: { $0.id == card.value.id }) else {
                assertionFailure(); continue
            }
            card.value = updatedCard
            results.append(card)
        }
        try interactor.saveCards(results)
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

private struct SessionDeck {
    var value: Deck<Card>
    let originalCards: [TransformedCard]
    
    init() {
        self.value = Deck()
        self.originalCards = []
    }
    
    init(value: Deck<Card>, originalCards: [TransformedCard]) {
        self.value = value
        self.originalCards = originalCards
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
