import CoreData

class NewRecordViewModel<F, I>: ObservableObject {
    let interactor: I
    
    init(interactor: I) {
        self.interactor = interactor
    }
    
    func save(_ input: F) throws {
   
    }
}

final class NewCardViewModel<I: CardInteractorPr>: NewRecordViewModel<String, I> {
    override func save(_ input: String) throws {
        guard input.count == 1, let kanji = Kanji(Array(input.utf16)) else {
            throw Exception.invalidData
        }
        let fetchRequest = Card.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "%K == %@",
                                             #keyPath(Card.kanjiRaw), Array(input.utf16))
        fetchRequest.fetchLimit = 1
        guard interactor.execute(fetchRequest, in: interactor.viewContext).isEmpty else {
            throw Exception.duplicate
        }
        let record = interactor.makeRecord(in: interactor.viewContext) as Card
        record.kanji = kanji
        interactor.linkWithExamples(record)
        interactor.save(in: interactor.viewContext)
    }
}

final class NewExampleViewModel<I: ExampleInteractorPr>: NewRecordViewModel<String, I> {
    override func save(_ input: String) throws {
        guard let word = input.split(separator: " ").first else {
            throw Exception.invalidData
        }
        let fetchRequest = Example.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "%K == %@",
                                             #keyPath(Example.word), String(word))
        fetchRequest.fetchLimit = 1
        guard interactor.execute(fetchRequest, in: interactor.viewContext).isEmpty else {
            throw Exception.duplicate
        }
        let record = interactor.makeRecord(in: interactor.viewContext) as Example
        record.word = String(word)
        interactor.linkWithCards(record)
        interactor.save(in: interactor.viewContext)
    }
}
