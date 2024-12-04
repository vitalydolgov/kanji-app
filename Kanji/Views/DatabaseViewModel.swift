import Foundation
import CoreData

protocol DatabaseViewModelPr: NSFetchedResultsControllerDelegate {
    associatedtype Record: NSManagedObject
    var records: [Record] { get set }
    var filteredRecordsNum: Int { get }
    var fetchResultsController: NSFetchedResultsController<Record> { get }
    func filter(by string: String) -> [Record]
    func remove(_ record: Record)
}

extension DatabaseViewModelPr {
    func fetchData() throws {
        try fetchResultsController.performFetch()
        records = fetchResultsController.fetchedObjects ?? []
    }
}

final class CardDatabaseViewModel<I, X>: NSObject, ObservableObject, DatabaseViewModelPr
                                         where I: CardInteractorPr,
                                               X: RecordImportExportPr {
    @Published var records = [Card]()
    var filteredRecordsNum = 0
    let didSavePub: NotificationCenter.Publisher
    let fetchResultsController: NSFetchedResultsController<Card>
    let interactor: I
    let importer: X

    init(interactor: I, importer: X) {
        self.interactor = interactor
        self.importer = importer
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
    
    func updateState(for card: Card, with state: CardState) {
        card.state = state
        interactor.save(in: interactor.viewContext)
    }
    
    func filter(by string: String) -> [Card] {
        if string.isEmpty {
            filteredRecordsNum = records.count
            return records
        }
        let filteredRecords = records.filter { card in
            guard let kanji = card.kanji else {
                return false
            }
            return string.contains(kanji.character)
        }
        filteredRecordsNum = filteredRecords.count
        return filteredRecords
    }
    
    func remove(_ card: Card) {
        interactor.deleteRecord(card, in: interactor.viewContext)
        interactor.save(in: interactor.viewContext)
    }
    
    // MARK: NSFetchedResultsControllerDelegate
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        records = controller.fetchedObjects as? [Card] ?? []
    }
}

final class ExampleDatabaseViewModel<I, X>: NSObject, ObservableObject, DatabaseViewModelPr
                                            where I: InteractorPr & HasViewContextPr,
                                                  X: RecordImportExportPr {
    @Published var records = [Example]()
    var filteredRecordsNum = 0
    let didSavePub: NotificationCenter.Publisher
    let fetchResultsController: NSFetchedResultsController<Example>
    let interactor: I
    let importer: X
    
    init(interactor: I, importer: X) {
        self.interactor = interactor
        self.importer = importer
        self.didSavePub = interactor.didSavePub
        let fetchRequest = Example.fetchRequest()
        fetchRequest.sortDescriptors = []
        fetchResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                            managedObjectContext: interactor.viewContext,
                                                            sectionNameKeyPath: nil,
                                                            cacheName: nil)
        super.init()
        fetchResultsController.delegate = self
    }
        
    func filter(by string: String) -> [Example] {
        if string.isEmpty {
            filteredRecordsNum = records.count
            return records
        }
        let filteredRecords = records.filter { record in
            record.word == string
        }
        filteredRecordsNum = filteredRecords.count
        return filteredRecords
    }
    
    func remove(_ example: Example) {
        interactor.deleteRecord(example, in: interactor.viewContext)
        interactor.save(in: interactor.viewContext)
    }
    
    // MARK: NSFetchedResultsControllerDelegate
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        records = controller.fetchedObjects as? [Example] ?? []
    }
}
