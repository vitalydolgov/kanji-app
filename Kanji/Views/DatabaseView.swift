import SwiftUI

struct DatabaseView<I: CardInteractorPr, T: Transformer>: View
                   where I.Record == T, I.Instance == Card {
    @ObservedObject var viewModel: DatabaseViewModel<I, T>
    @StateObject private var window = FocusedWindow(.database)

    var body: some View {
        Table(viewModel.cards) {
            TableColumn("Character") { card in
                Text("\(card.value.kanji.character)")
                    .font(.system(size: 20))
            }
            TableColumn("Level") { card in
                CardStateView(selected: card.value.state) { newValue in
                    try? viewModel.updateState(for: card, with: newValue)
                }
                .id(UUID())
            }
        }
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
