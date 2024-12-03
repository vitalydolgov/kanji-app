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
    // reset
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
    private var deck = Deck<Card>()
    private let interactor: I
    private let settingsProvider: S
    
    init(interactor: I, settingsProvider: S, cache: Z) {
        self.interactor = interactor
        self.settingsProvider = settingsProvider
        self.cache = cache
    }
        
    var takenCard: Card? {
        deck.takenCard
    }
    
    var cardsLeft: Int {
        deck.cardsLeft
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
        deck = Deck()
    }
    
    func start() throws {
        let settings = getSettings(using: settingsProvider)
        let maxCardsTotal = settings.maxCardsTotal == 0 ? Int.max : settings.maxCardsTotal
        let repeatCards = try interactor.fetchDataRandomized()
            .filter { $0.state == .repeat }
        if repeatCards.count > maxCardsTotal {
            let cards = Array(repeatCards.prefix(maxCardsTotal))
            deck = Deck(cards: cards)
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
        let cards = Array((repeatCards + newCards + recallCards).shuffled())
        deck = Deck(cards: cards)
    }
    
    func backToStart() {
        assert(operationHistory.isEmpty)
        assert(changeHistory.isEmpty)
        deck = Deck()
    }
    
    private func getSettings(using provider: some SettingsProviderPr) -> Settings {
        guard let settings = provider.fetchSettings() else {
            return provider.default()
        }
        return settings
    }
    
    func takeNextCard() throws {
        try deck.takeRandomCard()
    }
    
    func returnTakenCard() {
        deck.returnTakenCard()
    }
    
    func markCard(as guess: GuessResult) {
        guard let card = deck.takenCard else {
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
        deck.putBackCard(card, success: guess == .good)
        try? interactor.save()
    }
    
    func unmarkCard(as guess: GuessResult) {
        guard let history = changeHistory.pop() else {
            assertionFailure(); return
        }
        deck.replaceCard(history.id, prevGuess: guess)
        guard let card = deck.takenCard else {
            return
        }
        history.recover(card)
        try? interactor.save()
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
