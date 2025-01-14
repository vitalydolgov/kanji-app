import SwiftUI
import UniformTypeIdentifiers

struct ImportButton<I: FileImportExportPr>: View {
    @State private var importing = false
    let importer: I

    var body: some View {
        Button {
            importing = true
        } label: {
            Image(systemName: "square.and.arrow.down")
        }
        .fileImporter(isPresented: $importing,
                      allowedContentTypes: [.plainText]) { result in
            switch result {
            case .success(let file):
                do {
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

struct ExportButton<I: FileImportExportPr>: View {
    @State private var exporting = false
    @State private var document: TextDocument?
    let exporter: I
    
    var body: some View {
        Button {
            do {
                let text = try exporter.exportText()
                document = TextDocument(text)
                exporting = true
            } catch (let error) {
                print(error.localizedDescription)
            }
        } label: {
            Image(systemName: "document.badge.arrow.up")
        }
        .fileExporter(isPresented: $exporting,
                      document: document,
                      contentType: .plainText,
                      defaultFilename: exporter.defaultFilename) { result in
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
