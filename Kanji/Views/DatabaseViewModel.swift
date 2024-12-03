import Foundation
import CoreData

final class DatabaseViewModel<I: CardInteractorPr>: NSObject,
                                                    ObservableObject,
                                                    NSFetchedResultsControllerDelegate {
    @Published var cards = [Card]()
    @Published var showingDeleteConfirmation = false
    var filteredRecordsNum = 0
    let didSavePub: NotificationCenter.Publisher
    private let interactor: I
    private let fetchResultsController: NSFetchedResultsController<Card>

    init(interactor: I) {
        self.interactor = interactor
        self.didSavePub = interactor.didSavePub
        let fetchRequest = Card.fetchRequest()
        fetchRequest.sortDescriptors = []
        fetchResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                            managedObjectContext: interactor.viewContext,
                                                            sectionNameKeyPath: nil,
                                                            cacheName: nil)
        super.init()
        fetchResultsController.delegate = self
    }

    func fetchData() throws {
        try fetchResultsController.performFetch()
        cards = fetchResultsController.fetchedObjects ?? []
    }
    
    func updateState(for card: Card, with state: CardState) throws {
        card.state = state
        try interactor.save()
    }
    
    func deleteAllData() throws {
        try interactor.deleteAllData()
    }
    
    func filter(by string: String) -> [Card] {
        if string.isEmpty {
            filteredRecordsNum = cards.count
            return cards
        }
        let filteredCards = cards.filter { card in
            guard let kanji = card.kanji else {
                return false
            }
            return string.contains(kanji.character)
        }
        filteredRecordsNum = filteredCards.count
        return filteredCards
    }
    
    // MARK: NSFetchedResultsControllerDelegate
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        cards = controller.fetchedObjects as? [Card] ?? []
    }
}
