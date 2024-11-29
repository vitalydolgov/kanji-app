import Foundation
import Combine

protocol SessionPr {
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

protocol Cached {
    associatedtype Cache: DataCacheServicePr
    var cache: Cache { get }
}

final class Session<I, S, Z>: SessionPr, Updatable, Cached
                              where I: CardInteractorPr,
                                    S: SettingsProviderPr,
                                    Z: DataCacheServicePr {
    let updatePub = PassthroughSubject<UUID, Never>()
    let cache: Z
    private var operationHistory = OperationHistory()
    private var changeHistory = Stack<HistoryCard>()
    private var deck = SessionDeck()
    private let interactor: I
    private let settingsProvider: S
    
    init(interactor: I, settingsProvider: S, cache: Z) {
        self.interactor = interactor
        self.settingsProvider = settingsProvider
        self.cache = cache
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
            .filter { $0.state == .repeat }
        if repeatCards.count > maxCardsTotal {
            let originalCards = Array(repeatCards.prefix(maxCardsTotal))
            deck = SessionDeck(cards: originalCards)
            return
        }
        let maxAdditonalCards = min(maxCardsTotal - repeatCards.count, settings.maxAdditionalCards)
        let newLearnedRatio = settings.newLearnedRatio
        let maxNewCards = Int(Double(maxAdditonalCards) * newLearnedRatio)
        let newCards = try interactor.fetchData()
            .filter { $0.state == .new }
            .prefix(maxNewCards)
        let recallCards = try interactor.fetchDataRandomized()
            .filter { $0.state == .learned }
            .prefix(maxAdditonalCards - newCards.count)
        let originalCards = Array((repeatCards + newCards + recallCards).shuffled())
        deck = SessionDeck(cards: originalCards)
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
        guard let card = deck.value.takenCard else {
            assertionFailure(); return
        }
        changeHistory.push(HistoryCard(from: card))
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
        guard let history = changeHistory.pop() else {
            assertionFailure(); return
        }
        deck.value.replaceCard(history.id, prevGuess: guess)
        guard let card = deck.value.takenCard else {
            return
        }
        history.recover(card)
    }
    
    func saveCards() throws {
        try interactor.save()
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
    let originalCards: [Card]
    
    init() {
        self.value = Deck()
        self.originalCards = []
    }
    
    init(cards: [Card]) {
        self.value = Deck(cards: cards)
        self.originalCards = cards
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

private struct HistoryCard {
    let id: ObjectIdentifier
    let state: CardState
    
    init(from card: Card) {
        id = card.id
        state = card.state
    }
    
    func recover(_ card: Card) {
        card.state = state
    }
}
