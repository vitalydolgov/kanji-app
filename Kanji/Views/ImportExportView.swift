import SwiftUI
import UniformTypeIdentifiers

struct ImportCommand<I: CardInteractorPr>: View where I.Record == CDCard {
    @State private var importing = false
    let interactor: I

    var body: some View {
        Button("Import") {
            importing = true
        }
        .fileImporter(isPresented: $importing,
                      allowedContentTypes: [.plainText]) { result in
            switch result {
            case .success(let file):
                do {
                    let importer = CardImportExport(interactor: interactor)
                    try importer.importFile(file)
                } catch (let error) {
                    print(error.localizedDescription)
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
}

struct ExportCommand<I: CardInteractorPr>: View where I.Record == CDCard {
    @State private var exporting = false
    @State private var document: TextDocument?
    let interactor: I
    
    var body: some View {
        Button("Export") {
            do {
                let exporter = CardImportExport(interactor: interactor)
                let text = try exporter.exportText()
                document = TextDocument(text)
                exporting = true
            } catch (let error) {
                print(error.localizedDescription)
            }
        }
        .fileExporter(isPresented: $exporting,
                      document: document,
                      contentType: .plainText) { result in
            if case .failure(let error) = result {
                print(error.localizedDescription)
            }
        }
    }
}

struct TextDocument: FileDocument {
    static var readableContentTypes: [UTType] = [.plainText]
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let text = String(data: data, encoding: .utf8) else {
            throw Exception.invalidData
        }
        self.text = text
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = Data(text.utf8)
        return FileWrapper(regularFileWithContents: data)
    }
}
