import Foundation

actor Deck<Card: CardPr> {
    var takenCard: Card?
    private let repeatPile: Pile<Card>
    private let goodPile: Pile<Card>
    
    init(cards: [Card]) {
        repeatPile = Pile(cards: cards)
        goodPile = Pile(cards: [])
    }
    
    func takeRandomCard() async -> Card? {
        if let card = repeatPile.takeRandomCard() {
            takenCard = card
            return card
        } else {
            return nil
        }
    }
    
    func putBackCard(_ card: Card, success: Bool) async {
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
    
    func takeRandomCard() -> Card? {
        guard let (id, card) = cardDic.randomElement() else {
            return nil
        }
        cardDic[id] = nil
        return card
    }
}
