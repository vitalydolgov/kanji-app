struct Deck<Card: CardPr> {
    private(set) var takenCard: Card?
    private let repeatPile: Pile<Card>
    private let goodPile: Pile<Card>
    
    init() {
        self.init(cards: [])
    }
    
    init(cards: [Card]) {
        repeatPile = Pile(cards: cards)
        goodPile = Pile(cards: [])
    }
    
    mutating func replaceCard(_ id: Card.ID, prevGuess: GuessResult) {
        let card = switch prevGuess {
        case .good:
            goodPile.remove(id)
        case .again:
            repeatPile.remove(id)
        }
        guard let card else {
            assertionFailure(); return
        }
        takenCard = card
    }
    
    mutating func takeRandomCard() throws(OperationError) {
        guard let card = repeatPile.takeRandomCard() else {
            throw .cannotPerform
        }
        takenCard = card
    }
    
    mutating func returnTakenCard() {
        guard let card = takenCard else {
            assertionFailure(); return
        }
        repeatPile.append(card)
        takenCard = nil
    }
    
    mutating func putBackCard(_ card: Card, success: Bool) {
        if success {
            goodPile.append(card)
        } else {
            repeatPile.append(card)
        }
        takenCard = nil
    }
    
    var allCards: [Card] {
        var results = goodPile.cards + repeatPile.cards
        if let takenCard {
            results.append(takenCard)
        }
        return results
    }
    
    var cardsLeft: Int {
        repeatPile.size + (takenCard == nil ? 0 : 1)
    }
}

private class Pile<Card: CardPr> {
    private var cardDic = [Card.ID: Card]()
    
    init(cards: [Card]) {
        for card in cards {
            cardDic[card.id] = card
        }
    }
    
    var size: Int { cardDic.count }
    
    var cards: [Card] {
        var results = [Card]()
        for card in cardDic.values {
            results.append(card)
        }
        return results
    }
    
    func append(_ card: Card) {
        cardDic[card.id] = card
    }
    
    func remove(_ id: Card.ID) -> Card? {
        let card = cardDic[id]
        cardDic[id] = nil
        return card
    }
    
    func takeRandomCard() -> Card? {
        guard let (id, card) = cardDic.randomElement() else {
            return nil
        }
        cardDic[id] = nil
        return card
    }
}
