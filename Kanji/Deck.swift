final class Deck<Card: CardPr> {
    private(set) var takenCard: Card?
    private let repeatPile: Pile<Card>
    private let goodPile: Pile<Card>
    
    init(cards: [Card]) {
        repeatPile = Pile(cards: cards)
        goodPile = Pile(cards: [])
    }
    
    func replaceCard(_ card: Card, prevGuess: GuessResult) {
        switch prevGuess {
        case .good:
            goodPile.remove(card)
            takenCard = card
        case .again:
            repeatPile.remove(card)
            takenCard = card
        }
    }
    
    func takeRandomCard() throws(OperationError) {
        guard let card = repeatPile.takeRandomCard() else {
            throw .cannotPerform
        }
        takenCard = card
    }
    
    func returnTakenCard() {
        guard let card = takenCard else {
            assertionFailure(); return
        }
        repeatPile.append(card)
        takenCard = nil
    }
    
    func putBackCard(_ card: Card, success: Bool) {
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
    
    func remove(_ card: Card) {
        cardDic[card.id] = nil
    }
    
    func takeRandomCard() -> Card? {
        guard let (id, card) = cardDic.randomElement() else {
            return nil
        }
        cardDic[id] = nil
        return card
    }
}
