import Foundation
import Combine

enum LearnViewModelState: Equatable {
    case start, finish
    case front, back(guess: GuessResult?)
    case loading, error
}

@MainActor
final class LearnViewModel<S, D>: ObservableObject
                                  where S: SessionPr & Updatable & Cached, S.OperationID == UUID,
                                        D: ExampleInteractorPr {
    @Published var state: LearnViewModelState = .start
    var kanjiData: KanjiData?
    var cardsLeft: Int = 0
    var undoManager: UndoManager?
    private var subsc = Set<AnyCancellable>()
    let databaseInteractor: D
    private let session: S
    private let dataProvider: KanjiDataProviderPr
    private let lock = NSLock()

    init(session: S, databaseInteractor: D, dataProvider: some KanjiDataProviderPr) {
        self.session = session
        self.dataProvider = dataProvider
        self.databaseInteractor = databaseInteractor
        session.updatePub
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] id in self?.update(id) }
            .store(in: &subsc)
    }
    
    var examples: [String] {
        session.takenCard?.words ?? []
    }
    
    var kanji: Kanji? {
        session.takenCard?.kanji
    }
    
    private func update(_ id: S.OperationID) {
        Task { await update(id) }
    }
        
    private func update(_ id: S.OperationID) async {
        cardsLeft = session.cardsLeft
        if case .loading = state, let currentCard = session.takenCard {
            guard let kanji = currentCard.kanji else {
                return
            }
            do {
                if let cache = session.cache.getData(for: currentCard) {
                    kanjiData = cache
                } else {
                    let newData = try await dataProvider.getKanjiData(for: kanji)
                    try? session.cache.setData(newData, for: currentCard)
                    kanjiData = newData
                }
                state = .front
            } catch {
                state = .error
                kanjiData = nil
                try? await Task.sleep(for: .seconds(2))
                returnCardUnchanged()
                takeNextCard()
            }
        } else if session.isFinished {
            state = .finish
        } else {
            state = .start
        }
    }
    
    func takeNextCard() {
        state = .loading
        let operation = Operation(type: .take)
        OperationDispatch.execute(operation, for: session)
        registerUndo()
    }
    
    private func returnCardUnchanged() {
        OperationDispatch.unexecute(for: session, count: 1)
    }
    
    func putBackTakeNext(_ guess: GuessResult) {
        state = .back(guess: guess)
        Task {
            try await Task.sleep(for: .seconds(0.5))
            returnCard(guess)
            takeNextCard()
        }
    }
    
    private func returnCard(_ guess: GuessResult) {
        let operation = Operation(type: guess.operation)
        OperationDispatch.execute(operation, for: session)
        registerUndo()
    }
    
    @MainActor func showAnswer() {
        state = .back(guess: nil)
    }
    
    func restartSession() {
        session.reset()
        startSession()
    }
    
    func startSession() {
        let operation = Operation(type: .start)
        OperationDispatch.execute(operation, for: session)
        takeNextCard()
    }
    
    private func registerUndo() {
        undoManager?.registerUndo(withTarget: self) { targetSelf in
            Task { @MainActor in
                OperationDispatch.unexecute(for: targetSelf.session, count: 1)
                targetSelf.state = .loading
            }
        }
    }
}
