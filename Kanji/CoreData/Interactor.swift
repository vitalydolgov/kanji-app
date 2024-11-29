import CoreData

protocol InteractorPr {
    var didSavePub: NotificationCenter.Publisher { get }
    func save() throws
}

protocol CardInteractorPr: InteractorPr {
    func fetchData() throws -> IndexingIterator<[Card]>
    func fetchDataRandomized() throws -> IndexingIterator<[Card]>
    func deleteAllData() throws
}

protocol ImportExportPr {
    associatedtype Record
    func importRecords(_ records: [Record]) throws
    func exportRecords() throws  -> [Record]
}

struct Interactor: CardInteractorPr, ImportExportPr {
    let didSavePub: NotificationCenter.Publisher
    private let persistence: NSPersistentContainer

    init(persistence: NSPersistentContainer) {
        self.persistence = persistence
        self.didSavePub = NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave,
                                                               object: persistence.viewContext)
    }
    
    func fetchData() throws -> IndexingIterator<[Card]> {
        let request = Card.fetchRequest()
        let records = try persistence.viewContext.fetch(request)
        return records.makeIterator()
    }
    
    func fetchDataRandomized() throws -> IndexingIterator<[Card]> {
        Array(try fetchData()).shuffled().makeIterator()
    }
    
    func save() throws {
        try persistence.viewContext.save()
    }
    
    func deleteAllData() throws {
        let batchDelete = NSBatchDeleteRequest(fetchRequest: Card.fetchRequest())
        try persistence.viewContext.execute(batchDelete)
        notifyDidSave()
    }
    
    func importRecords(_ records: [Card]) throws {
        var index = 0
        let batchInsert = NSBatchInsertRequest(entity: Card.entity(),
                                               managedObjectHandler: { object in
            guard index < records.count, 
                  let record = object as? Card else {
                return true
            }
            let data = records[index]
            record.kanjiRaw = data.kanjiRaw
            record.stateRaw = data.stateRaw
            index += 1
            return false
        })
        try persistence.viewContext.execute(batchInsert)
        notifyDidSave()
    }
    
    func exportRecords() throws  -> [Card] {
        let request = Card.fetchRequest()
        return try persistence.viewContext.fetch(request)
    }
    
    private func notifyDidSave() {
        NotificationCenter.default.post(name: .NSManagedObjectContextDidSave,
                                        object: persistence.viewContext)
    }
}

// MARK: Model

extension Card: CardPr {
    var kanji: Kanji? {
        Kanji(kanjiRaw ?? [])
    }
    
    var state: CardState {
        get {
            CardState(rawValue: Int(stateRaw)) ?? .new
        }
        set {
            stateRaw = Int16(newValue.rawValue)
        }
    }
}
