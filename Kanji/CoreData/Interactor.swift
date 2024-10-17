import CoreData

protocol Transformer {
    associatedtype Target
    func transform() -> Target?
}

protocol CardInteractorPr {
    associatedtype Record: Transformer where Record.Target == Instance
    associatedtype Instance
    var didSavePub: NotificationCenter.Publisher { get }
    func fetchData() throws -> IndexingIterator<[Instance]>
    func fetchDataRandomized() throws -> IndexingIterator<[Instance]>
    func updateState(for card: Instance, with state: CardState) throws
    func deleteAllData() throws
    func saveCards(_ cards: [Instance]) throws
}

protocol ImportExportPr {
    associatedtype Record
    func importRecords(_ records: [Record]) throws
    func exportRecords() throws  -> [Record]
}

extension CardInteractorPr {
    func make(from record: Record) -> Instance? {
        record.transform()
    }
}

struct CardInteractor: CardInteractorPr, ImportExportPr {
    typealias Record = CDCard
    typealias Instance = Card
    
    let didSavePub: NotificationCenter.Publisher
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
        self.didSavePub = NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave,
                                                               object: context)
    }
    
    func fetchData() throws -> IndexingIterator<[Card]> {
        let request = CDCard.fetchRequest()
        let records = try context.fetch(request)
        return records.compactMap { $0.transform() }.makeIterator()
    }
    
    func fetchDataRandomized() throws -> IndexingIterator<[Card]> {
        Array(try fetchData()).shuffled().makeIterator()
    }
    
    func updateState(for card: Card, with state: CardState) throws {
        guard let record = context.object(with: card.id) as? CDCard else {
            assertionFailure(); return
        }
        record.state = Int16(state.rawValue)
        try context.save()
    }
    
    func deleteAllData() throws {
        let batchDelete = NSBatchDeleteRequest(fetchRequest: CDCard.fetchRequest())
        try context.execute(batchDelete)
        notifyDidSave()
    }
    
    func saveCards(_ cards: [Card]) throws {
        for card in cards {
            guard let export = context.registeredObject(for: card.id) as? CDCard else {
                assertionFailure(); continue
            }
            export.state = Int16(card.state.rawValue)
        }
        try context.save()
    }
    
    func importRecords(_ records: [CDCard]) throws {
        var index = 0
        let batchInsert = NSBatchInsertRequest(entity: CDCard.entity(), 
                                               managedObjectHandler: { object in
            guard index < records.count, 
                  let record = object as? CDCard else {
                return true
            }
            let data = records[index]
            record.kanjiUtf8 = data.kanjiUtf8
            record.state = data.state
            index += 1
            return false
        })
        try context.execute(batchInsert)
        notifyDidSave()
    }
    
    func exportRecords() throws  -> [CDCard] {
        let request = CDCard.fetchRequest()
        return try context.fetch(request)
    }
    
    private func notifyDidSave() {
        NotificationCenter.default.post(name: .NSManagedObjectContextDidSave,
                                        object: context)
    }
}

// MARK: Model

extension CDCard: Transformer {
    typealias Target = Card
    
    func transform() -> Card? {
        guard let kanji = Kanji(kanjiUtf8),
              let state = CardState(rawValue: Int(state)) else {
            assertionFailure(); return nil
        }
        return Card(id: objectID, kanji: kanji, state: state)
    }
}

struct Card: CardPr {
    let id: NSManagedObjectID
    let kanji: Kanji
    var state: CardState
}
