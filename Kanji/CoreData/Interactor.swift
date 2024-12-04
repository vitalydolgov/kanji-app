import CoreData

protocol InteractorPr {
    func makeRecord<R>(in context: NSManagedObjectContext) -> R where R: NSManagedObject
    func deleteRecord<R>(_ record: R, in context: NSManagedObjectContext) where R: NSManagedObject
    func execute<T>(_ request: NSFetchRequest<T>, in context: NSManagedObjectContext) -> [T]
    func save(in context: NSManagedObjectContext)
}

protocol HasViewContextPr {
    var didSavePub: NotificationCenter.Publisher { get }
    var viewContext: NSManagedObjectContext { get }
    func makeBackgroundContext() -> NSManagedObjectContext
}

protocol CardInteractorPr: InteractorPr & HasViewContextPr {
    func linkWithExamples(_ record: Card)
    func fetchCards() -> IndexingIterator<[Card]>
    func fetchCardsRandomized() -> IndexingIterator<[Card]>
}

protocol ExampleInteractorPr: InteractorPr & HasViewContextPr {
    func linkWithCards(_ record: Example)
}

struct Interactor: InteractorPr, HasViewContextPr {
    let didSavePub: NotificationCenter.Publisher
    private let persistence: NSPersistentContainer

    init(persistence: NSPersistentContainer) {
        self.persistence = persistence
        self.didSavePub = NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave,
                                                               object: persistence.viewContext)
    }
    
    var viewContext: NSManagedObjectContext {
        persistence.viewContext
    }
    
    func makeBackgroundContext() -> NSManagedObjectContext {
        persistence.newBackgroundContext()
    }
    
    func makeRecord<R>(in context: NSManagedObjectContext) -> R where R: NSManagedObject {
        R(context: context)
    }
    
    func deleteRecord<R>(_ record: R, in context: NSManagedObjectContext) where R: NSManagedObject {
        context.delete(record)
    }
    
    func execute<T>(_ request: NSFetchRequest<T>, in context: NSManagedObjectContext) -> [T] {
        guard let records = try? context.fetch(request) else {
            return []
        }
        return records
    }
    
    func save(in context: NSManagedObjectContext) {
        do {
            try context.save()
        } catch {
            assertionFailure(); context.rollback()
        }
    }
    
    func deleteAllData() throws {
        let batchDelete = NSBatchDeleteRequest(fetchRequest: Card.fetchRequest())
        try persistence.viewContext.execute(batchDelete)
        notifyDidSave()
    }
    
    private func notifyDidSave() {
        NotificationCenter.default.post(name: .NSManagedObjectContextDidSave,
                                        object: persistence.viewContext)
    }
}

extension Interactor: CardInteractorPr {
    func linkWithExamples(_ record: Card) {
        guard let context = record.managedObjectContext,
              let kanji = record.kanji else {
            return
        }
        record.examples = NSSet(array: findExamples(for: String(kanji.character), in: context))
    }
    
    private func findExamples(for kanji: String, in context: NSManagedObjectContext) -> [Example] {
        let predicate = NSPredicate(format: "%K contains %@", #keyPath(Example.word), kanji)
        let request = Example.fetchRequest()
        request.predicate = predicate
        return execute(request, in: context)
    }
    
    func fetchCards() -> IndexingIterator<[Card]> {
        let request = Card.fetchRequest()
        let records = execute(request, in: persistence.viewContext)
        return records.makeIterator()
    }
    
    func fetchCardsRandomized() -> IndexingIterator<[Card]> {
        Array(fetchCards()).shuffled().makeIterator()
    }
}

extension Interactor: ExampleInteractorPr {
    func linkWithCards(_ record: Example) {
        guard let context = record.managedObjectContext,
              let word = record.word else {
            return
        }
        record.kanji = NSSet(array: findCards(for: word, in: context))
    }
    
    private func findCards(for word: String, in context: NSManagedObjectContext) -> [Card] {
        var results = [Card]()
        for character in word {
            let array = character.utf16.map { UInt16($0) }
            let request = Card.fetchRequest()
            let predicate = NSPredicate(format: "%K == %@", #keyPath(Card.kanjiRaw), array)
            request.predicate = predicate
            request.fetchLimit = 1
            guard let card = execute(request, in: context).first else {
                continue
            }
            results.append(card)
        }
        return results
    }
}

// MARK: Model

extension Card: CardPr {
    var kanji: Kanji? {
        get {
            Kanji(kanjiRaw ?? [])
        }
        set {
            guard let newValue else {
                assertionFailure(); return
            }
            kanjiRaw = newValue.character.utf16.map { UInt16($0) }
        }
    }
    
    var state: CardState {
        get {
            CardState(rawValue: Int(stateRaw)) ?? .new
        }
        set {
            stateRaw = Int16(newValue.rawValue)
        }
    }
    
    var words: [String] {
        guard let examples = examples as? Set<Example> else {
            return []
        }
        let result = examples.compactMap { example -> String? in
            guard let word = example.word else {
                return nil
            }
            return word
        }
        return result
    }
}
