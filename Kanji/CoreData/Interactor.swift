import CoreData

protocol Transformer {
    associatedtype Target
    func transform() -> Target?
}

protocol CardInteractorPr {
    associatedtype Record: Transformer where Record.Target == Instance
    associatedtype Instance
    var didSavePub: NotificationCenter.Publisher { get }
    func fetchData() throws -> [Instance]
    func updateState(for card: Instance, with state: CardState) throws
    func deleteAllData() throws
    func saveCards(_ cards: [Instance]) throws
    func importRecords(_ records: [Record], insertContext: NSManagedObjectContext) throws
    func exportRecords() throws  -> [Record]
}

extension CardInteractorPr {
    func make(from record: Record) -> Instance? {
        record.transform()
    }
}

struct CardInteractor: CardInteractorPr {
    typealias Record = CDCard
    typealias Instance = Card
    
    let didSavePub: NotificationCenter.Publisher
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
        self.didSavePub = NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave,
                                                               object: context)
    }
    
    func fetchData() throws -> [Card] {
        let request = CDCard.fetchRequest()
        let records = try context.fetch(request)
        return records.compactMap { $0.transform() }
    }
    
    func updateState(for card: Card, with state: CardState) throws {
        guard let record = context.object(with: card.id) as? CDCard else {
            assertionFailure(); return
        }
        record.state = Int16(state.rawValue)
        try context.save()
    }
    
    func deleteAllData() throws {
        let request = NSBatchDeleteRequest(fetchRequest: CDCard.fetchRequest())
        try context.execute(request)
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
    
    func importRecords(_ records: [CDCard], insertContext: NSManagedObjectContext) throws {
        insertContext.parent = context
        try insertContext.save()
        try context.save()
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

struct Card: CardPr, Identifiable {
    let id: NSManagedObjectID
    let kanji: Kanji
    var state: CardState
}
