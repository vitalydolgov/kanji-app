import Foundation

actor Deck<Card: CardPr> {
    fileprivate let repeatPile: Pile<Card>
    fileprivate let goodPile: Pile<Card>
    
    init(cards: [Card]) {
        repeatPile = Pile(cards: cards)
        goodPile = Pile(cards: [])
    }
    
    func takeRandomCard() async -> Card? {
        if let card = repeatPile.takeRandomCard() {
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
    }
    
    var allCards: [Card] {
        goodPile.cards + repeatPile.cards
    }
    
    var cardsLeft: Int {
        repeatPile.cards.count
    }
}

fileprivate class Pile<Card: CardPr> {
    var cards: [Card]
    
    init(cards: [Card]) {
        self.cards = cards
    }
    
    var size: Int { cards.count }
    
    func append(_ card: Card) {
        cards.append(card)
    }
    
    func takeRandomCard() -> Card? {
        guard !cards.isEmpty else {
            return nil
        }
        let index = Int.random(in: 0 ..< cards.count)
        return cards.remove(at: index)
    }
}
