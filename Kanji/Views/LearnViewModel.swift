import Foundation

enum LearnViewModelState: Equatable {
    case front, back(guess: GuessResult), loading, error
}

@MainActor
final class LearnViewModel<Session: SessionPr>: ObservableObject {
    @Published var state: LearnViewModelState = .loading
    var kanjiData: KanjiData?
    var cardsLeft: Int = 0
    
    let session: Session
    let dataProvider: KanjiDataProviderPr

    init(session: Session, dataProvider: some KanjiDataProviderPr) {
        self.session = session
        self.dataProvider = dataProvider
    }
    
    func takeNextCard() async {
        cardsLeft = await session.cardsLeft()
        if let currentCard = await session.takeNext() {
            let kanji = currentCard.kanji
            do {
                kanjiData = try await dataProvider.getKanjiData(for: kanji)
                state = .front
            } catch {
                kanjiData = nil
                state = .error
                try? await Task.sleep(for: .seconds(2))
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
            await takeNextCard()
        }
    }
    
    private func putBackCard(_ guess: GuessResult) async {
        await session.putBack(guess: guess)
    }
    
    func showAnswer() {
        Task {
            state = .back(guess: .unknown)
        }
    }
}
