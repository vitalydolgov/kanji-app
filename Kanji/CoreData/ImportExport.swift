import CoreData

struct CardImportExport<I: ImportExportPr> where I.Record == Card {
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
        return try String(contentsOf: file)
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
}
