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
where I.Instance == Card {
    let updatePub = PassthroughSubject<UUID, Never>()
    private var operationHistory = OperationHistory()
    private var changeHistory = Stack<Card>()
    private var deck: Deck<Card> = Deck()
    private let interactor: I
    private let settingsProvider: S
    
    init(interactor: I, settingsProvider: S) {
        self.interactor = interactor
        self.settingsProvider = settingsProvider
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
            deck = Deck(cards: Array(repeatCards.prefix(maxCardsTotal)))
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
