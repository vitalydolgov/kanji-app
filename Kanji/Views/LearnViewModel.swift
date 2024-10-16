import Foundation

enum LearnViewModelState: Equatable {
    case front, back(guess: GuessResult), loading, error
}

@MainActor
final class LearnViewModel<Session: SessionPr>: ObservableObject {
    @Published var state: LearnViewModelState = .loading
    var kanjiData: KanjiData?
    var currentCard: Session.Card?
    var cardsLeft: Int = 0
    
    let session: Session
    let dataProvider: KanjiDataProviderPr

    init(session: Session, dataProvider: some KanjiDataProviderPr) {
        self.session = session
        self.dataProvider = dataProvider
    }
    
    func takeNextCard() async throws {
        currentCard = await session.takeNext()
        cardsLeft = await session.cardsLeft()
        if let currentCard {
            let kanji = currentCard.kanji
            do {
                kanjiData = try await dataProvider.getKanjiData(for: kanji)
                state = .front
            } catch {
                kanjiData = nil
                state = .error
                try await Task.sleep(for: .seconds(2))
                putBackTakeNext(.unknown)
            }
        } else {
            kanjiData = nil
            state = .front
        }
    }
    
    func putBackTakeNext(_ guess: GuessResult) {
        state = .back(guess: guess)
        Task {
            try await Task.sleep(for: .seconds(0.5))
            await putBackCard(guess)
            try await takeNextCard()
        }
    }
    
    private func putBackCard(_ guess: GuessResult) async {
        guard let card = currentCard else {
            return
        }
        await session.putBack(card, guess: guess)
    }
    
    func showAnswer() {
        Task {
            state = .back(guess: .unknown)
        }
    }
}
