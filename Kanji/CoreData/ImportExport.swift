import CoreData

protocol RecordImportExportPr {
    associatedtype Record
    func importRecords(_ records: [Record]) throws
    func exportRecords() throws  -> [Record]
}

protocol FileImportExportPr {
    func importFile(_ file: URL) throws
    func exportText() throws -> String
    var defaultFilename: String { get }
}

struct CardFileImportExport<I>: FileImportExportPr where I: RecordImportExportPr, I.Record == Card {
    let interactor: I
    
    func importFile(_ file: URL) throws {
        let lines = try readFile(file)?.split(separator: "\n")
        guard let lines, !lines.isEmpty else {
            return
        }
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        var records = [Card]()
        for line in lines {
            let fields = line.split(separator: ";")
            let kanjiRaw = fields[0].utf16.map { UInt16($0) }
            guard !kanjiRaw.isEmpty,
                  let stateRaw = fields.count == 2 ? Int16(fields[1]) : 0 else {
                continue
            }
            let record = Card(context: context)
            record.kanjiRaw = kanjiRaw
            record.stateRaw = stateRaw
            records.append(record)
        }
        try interactor.importRecords(records)
    }
    
    private func readFile(_ file: URL) throws -> String? {
        guard file.startAccessingSecurityScopedResource() else {
            return nil
        }
        defer { file.stopAccessingSecurityScopedResource() }
        return try String(contentsOf: file, encoding: .utf8)
    }
    
    func exportText() throws -> String {
        let records = try interactor.exportRecords()
        let lines = records.compactMap { record -> String? in
            guard let kanji = Kanji(record.kanjiRaw ?? []) else {
                return nil
            }
            return "\(kanji.character);\(record.state.rawValue)"
        }
        return lines.joined(separator: "\n")
    }
    
    var defaultFilename: String {
        "cards.csv"
    }
}

struct CardRecordImportExport<I>: RecordImportExportPr where I: CardInteractorPr {
    let interactor: I
    
    var viewContext: NSManagedObjectContext {
        interactor.viewContext
    }
    
    func importRecords(_ insertRecords: [Card]) throws {
        // dictionary for efficiency
        var cardDic = [Kanji: Card]()
        for card in try viewContext.fetch(Card.fetchRequest()) {
            guard let key = card.kanji else {
                continue
            }
            cardDic[key] = card
        }
        // partition records: insert or update
        var newInsertRecords = [Card]()
        for record in insertRecords {
            if let kanji = record.kanji, let existingRecord = cardDic[kanji] {
                existingRecord.stateRaw = record.stateRaw
            } else {
                newInsertRecords.append(record)
            }
        }
        // actual insert
        var index = 0
        let batchInsert = NSBatchInsertRequest(entity: Card.entity(),
                                               managedObjectHandler: { object in
            guard index < newInsertRecords.count,
                  let record = object as? Card else {
                return true
            }
            let data = newInsertRecords[index]
            record.kanjiRaw = data.kanjiRaw
            record.stateRaw = data.stateRaw
            index += 1
            return false
        })
        try viewContext.execute(batchInsert)
        // update relationships
        let updateContext = interactor.makeBackgroundContext()
        let records = interactor.execute(Card.fetchRequest(), in: updateContext)
        for card in records {
            interactor.linkWithExamples(card)
        }
        try updateContext.save()
        try viewContext.save()
    }
    
    func exportRecords() throws  -> [Card] {
        let request = Card.fetchRequest()
        return try viewContext.fetch(request)
    }
}

struct ExampleFileImportExport<I>: FileImportExportPr where I: RecordImportExportPr, I.Record == Example {
    let interactor: I
    
    func importFile(_ file: URL) throws {
        let lines = try readFile(file)?.split(separator: "\n")
        guard let lines, !lines.isEmpty else {
            return
        }
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        var records = [Example]()
        for line in lines {
            let record = Example(context: context)
            record.word = String(line)
            records.append(record)
        }
        try interactor.importRecords(records)
    }
    
    private func readFile(_ file: URL) throws -> String? {
        guard file.startAccessingSecurityScopedResource() else {
            return nil
        }
        defer { file.stopAccessingSecurityScopedResource() }
        return try String(contentsOf: file, encoding: .utf8)
    }
    
    func exportText() throws -> String {
        let records = try interactor.exportRecords()
        let lines = records.compactMap { record -> String? in
            guard let word = record.word else {
                return nil
            }
            return word
        }
        return lines.joined(separator: "\n")
    }
    
    var defaultFilename: String {
        "examples.csv"
    }
}

struct ExampleRecordImportExport<I>: RecordImportExportPr where I: ExampleInteractorPr {
    let interactor: I
    
    var viewContext: NSManagedObjectContext {
        interactor.viewContext
    }
    
    func importRecords(_ records: [Example]) throws {
        // dictionary for efficiency
        var exampleDic = [String: Example]()
        for example in try viewContext.fetch(Example.fetchRequest()) {
            guard let key = example.word else {
                continue
            }
            exampleDic[key] = example
        }
        // filter existing
        let newInsertRecords = records.filter { record in
            if let word = record.word, exampleDic[word] != nil {
                return false
            }
            return true
        }
        // actual insert
        var index = 0
        let batchInsert = NSBatchInsertRequest(entity: Example.entity(),
                                               managedObjectHandler: { object in
            guard index < newInsertRecords.count,
                  let record = object as? Example else {
                return true
            }
            let data = newInsertRecords[index]
            record.word = data.word
            index += 1
            return false
        })
        try viewContext.execute(batchInsert)
        // update relationships
        let updateContext = interactor.makeBackgroundContext()
        let records = interactor.execute(Example.fetchRequest(), in: updateContext)
        for example in records {
            interactor.linkWithCards(example)
        }
        try updateContext.save()
        try viewContext.save()
    }
    
    func exportRecords() throws -> [Example] {
        let request = Example.fetchRequest()
        return try viewContext.fetch(request)
    }
}
