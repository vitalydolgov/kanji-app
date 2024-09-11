import Foundation

actor MockSession: SessionPr {
    typealias Card = MockCard
    
    func takeNext() async -> Card? {
        MockCard()
    }
    
    func putBack(_ card: Card, guess: GuessResult) async {
        
    }
    
    func cardsLeft() async -> Int {
        1
    }
}

struct MockCard: CardPr {
    var state: CardState = .repeat
    var kanji: Kanji {
        Kanji("\u{751F}")!
    }
}
