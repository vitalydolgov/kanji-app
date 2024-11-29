import SwiftUI

struct DatabaseView<I: CardInteractorPr>: View {
    @ObservedObject var viewModel: DatabaseViewModel<I>
    @StateObject private var window = FocusedWindow(.database)
    @State private var searchText = ""

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
                        try? viewModel.updateState(for: card, with: newValue)
                    }
                    .id(UUID())
                }
            }
            HStack {
                Text("Records: \(viewModel.filteredRecordsNum)")
                Spacer()
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
        .confirmationDialog(Text("All cards will be deleted!"), 
                            isPresented: $viewModel.showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                try? viewModel.deleteAllData()
            }
        }
        .focusedValue(\.window, window)
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
