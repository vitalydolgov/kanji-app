import SwiftUI

struct DatabaseView<I, CardX, ExampleX>: View where I: CardInteractorPr & ExampleInteractorPr,
                                                    CardX: RecordImportExportPr, CardX.Record == Card,
                                                    ExampleX: RecordImportExportPr, ExampleX.Record == Example {
    @StateObject private var window = FocusedWindow(.database)
    let interactor: I
    let cardImporter: CardX
    let exampleImporter: ExampleX

    var body: some View {
        TabView {
            Tab("Cards", systemImage: "lanyardcard") {
                let viewModel = CardDatabaseViewModel(interactor: interactor, importer: cardImporter)
                CardDatabaseView(viewModel: viewModel)
            }
            Tab("Examples", systemImage: "text.bubble") {
                let viewModel = ExampleDatabaseViewModel(interactor: interactor, importer: exampleImporter)
                ExampleDatabaseView(viewModel: viewModel)
            }
        }
        .focusedValue(\.window, window)
    }
}

// MARK: - Cards

struct CardDatabaseView<I, X>: View where I: CardInteractorPr,
                                          X: RecordImportExportPr, X.Record == Card {
    @StateObject var viewModel: CardDatabaseViewModel<I, X>
    @State private var searchText = ""
    @State private var showingAddRecord = false
    @State private var recordToDelete: Card?
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack {
            Table(viewModel.filter(by: searchText)) {
                TableColumn("Character") { card in
                    if let kanji = card.kanji {
                        Text("\(kanji.character)")
                            .font(.system(size: 20))
                    }
                }
                TableColumn("Level") { card in
                    CardStateView(selected: card.state) { newValue in
                        viewModel.updateState(for: card, with: newValue)
                    }
                    .id(UUID())
                }
                TableColumn("") { card in
                    Button {
                        recordToDelete = card
                        showingDeleteAlert = true
                    } label: {
                        Image(systemName: "trash")
                    }
                }
                .width(24)
            }
            HStack {
                Text("Records: \(viewModel.filteredRecordsNum)")
                
                Spacer()
                
                Button {
                    showingAddRecord = true
                } label: {
                    Image(systemName: "plus")
                }
                
                ImportButton(importer: CardFileImportExport(interactor: viewModel.importer))
                
                ExportButton(exporter: CardFileImportExport(interactor: viewModel.importer))
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
        }
        .searchable(text: $searchText)
        .onAppear {
            try? viewModel.fetchData()
        }
        .onReceive(viewModel.didSavePub.receive(on: RunLoop.main)) { _ in
            try? viewModel.fetchData()
        }
        .sheet(isPresented: $showingAddRecord) {
            let viewModel = NewCardViewModel(interactor: viewModel.interactor)
            NewRecordView(showingDialog: $showingAddRecord,
                          viewModel: viewModel)
        }
        .confirmationDialog(Text("Record will be deleted!"),
                            isPresented: $showingDeleteAlert) {
            Button("Remove", role: .destructive) {
                guard let record = recordToDelete else {
                    assertionFailure(); return
                }
                viewModel.remove(record)
                recordToDelete = nil
            }
        }
    }
}

struct CardStateView: View {
    @State var selected: CardState
    let onUpdate: (CardState) -> ()
    
    var color: Color {
        Color(white: 1 - Double(selected.rawValue + 1) / 5)
    }
    
    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 20)
                
                Text("\(selected.rawValue)")
                    .foregroundStyle(.white)
            }
            
            Picker("", selection: $selected) {
                ForEach(CardState.allCases) { option in
                    Text("\(option)")
                }
                .pickerStyle(.automatic)
            }
            .onChange(of: selected) { _, newValue in
                onUpdate(newValue)
            }
        }
    }
}

// MARK: - Examples

struct ExampleDatabaseView<I, X>: View where I: ExampleInteractorPr,
                                             X: RecordImportExportPr, X.Record == Example {
    @StateObject var viewModel: ExampleDatabaseViewModel<I, X>
    @State private var searchText = ""
    @State private var showingAddRecord = false
    @State private var recordToDelete: Example?
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack {
            Table(viewModel.filter(by: searchText)) {
                TableColumn("Word") { example in
                    if let word = example.word {
                        Text(word)
                            .font(.system(size: 20))
                    }
                }
                TableColumn("Cards") { example in
                    Text("\(example.kanji?.count ?? 0)")
                }
                TableColumn("") { example in
                    Button {
                        recordToDelete = example
                        showingDeleteAlert = true
                    } label: {
                        Image(systemName: "trash")
                    }
                }
                .width(24)
            }
            HStack {
                Text("Records: \(viewModel.filteredRecordsNum)")
                
                Spacer()
                
                Button {
                    showingAddRecord = true
                } label: {
                    Image(systemName: "plus")
                }
                
                ImportButton(importer: ExampleFileImportExport(interactor: viewModel.importer))
                
                ExportButton(exporter: ExampleFileImportExport(interactor: viewModel.importer))
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
        }
        .searchable(text: $searchText)
        .onAppear {
            try? viewModel.fetchData()
        }
        .onReceive(viewModel.didSavePub.receive(on: RunLoop.main)) { _ in
            try? viewModel.fetchData()
        }
        .sheet(isPresented: $showingAddRecord) {
            let viewModel = NewExampleViewModel(interactor: viewModel.interactor)
            NewRecordView(showingDialog: $showingAddRecord,
                          viewModel: viewModel)
        }
        .confirmationDialog(Text("Record will be deleted!"),
                            isPresented: $showingDeleteAlert) {
            Button("Remove", role: .destructive) {
                guard let record = recordToDelete else {
                    assertionFailure(); return
                }
                viewModel.remove(record)
                recordToDelete = nil
            }
        }
    }
}
