import CoreData

struct CardImportExport<I: CardInteractorPr> where I.Record == CDCard {
    let interactor: I
    
    func importFile(_ file: URL) throws {
        let lines = try readFile(file)?.split(separator: "\n")
        guard let lines, !lines.isEmpty else {
            return
        }
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        var records = [CDCard]()
        for line in lines {
            let fields = line.split(separator: ";")
            guard let kanjiUtf8 = fields[0].unicodeScalars.first?.value,
                  let state = Int16(fields[1]) else {
                continue
            }
            let record = CDCard(context: context)
            record.kanjiUtf8 = Int32(kanjiUtf8)
            record.state = state
            records.append(record)
        }
        try interactor.importRecords(records, insertContext: context)
    }
    
    private func readFile(_ file: URL) throws -> String? {
        guard file.startAccessingSecurityScopedResource() else {
            return nil
        }
        defer { file.stopAccessingSecurityScopedResource() }
        return try String(contentsOf: file)
    }
    
    func exportText() throws -> String {
        let records = try interactor.exportRecords()
        let lines = records.compactMap { record -> String? in
            guard let kanji = Kanji(record.kanjiUtf8) else {
                return nil
            }
            return "\(kanji.character);\(record.state)"
        }
        return lines.joined(separator: "\n")
    }
}
