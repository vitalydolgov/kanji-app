import SwiftUI

struct LearnView: View {
    @StateObject var viewModel: LearnViewModel<Session<Interactor,
                                                       SettingsInteractorUserDefaults,
                                                       DataCacheService>,
                                               Interactor>
    @Environment(\.undoManager) var undoManager
    
    
    var body: some View {
        VStack(spacing: 20) {
            if case .front = viewModel.state {
                if let kanji = viewModel.kanji {
                    CardFrontView(state: $viewModel.state,
                                  kanji: kanji,
                                  examples: viewModel.examples,
                                  interactor: viewModel.databaseInteractor,
                                  showAnswer: viewModel.showAnswer)
                }
            } else if case .back = viewModel.state {
                if let kanji = viewModel.kanji,
                   let kanjiData = viewModel.kanjiData {
                    CardBackView(state: $viewModel.state,
                                 kanji: kanji,
                                 kanjiData: kanjiData,
                                 putBack: viewModel.putBackTakeNext)
                }
            } else if case .error = viewModel.state {
                Spacer()
                
                Text("Cannot load data \u{2639}\u{FE0F}")
                    .font(.title3)
                
                Spacer()
            } else if case .start = viewModel.state {
                Spacer()
                
                let gradient = LinearGradient(colors: [.blue, .cyan],
                                              startPoint: .leading,
                                              endPoint: .bottom)
                Button {
                    viewModel.startSession()
                } label: {
                    Text("Start Learning")
                }
                .buttonStyle(ShrinkingButton(background: gradient))
                
                Spacer()
            } else if case .finish = viewModel.state {
                Spacer()
                
                Text("No more cards \u{1F389}")
                    .font(.title3)
                
                let gradient = LinearGradient(colors: [.blue, .cyan],
                                              startPoint: .leading,
                                              endPoint: .bottom)
                Button {
                    viewModel.restartSession()
                } label: {
                    Text("Repeat")
                }
                .buttonStyle(ShrinkingButton(background: gradient))
                
                Spacer()
            } else {
                Spacer()
            }
            
            ZStack {
                let cardsLeft = viewModel.cardsLeft
                
                RoundedRectangle(cornerSize: CGSize(width: 10, height: 10))
                    .fill(.gray)
                    .frame(width: 30 + (cardsLeft < 1000 ? 0 : 10), height: 20)
                
                Text("\(cardsLeft)")
                    .foregroundStyle(.white)
                    .bold()
            }
        }
        .padding(.vertical, 20)
        .focusable(interactions: .edit)
        .focusEffectDisabled()
        .onKeyPress(.space) {
            switch viewModel.state {
            case .front:
                viewModel.showAnswer()
                return .handled
            case .back:
                viewModel.putBackTakeNext(.good)
                return .handled
            default:
                return .ignored
            }
        }
        .onKeyPress(KeyEquivalent("x")) {
            if case .back = viewModel.state {
                viewModel.putBackTakeNext(.again)
                return .handled
            }
            return .ignored
        }
        .onAppear {
            if viewModel.undoManager == nil {
                viewModel.undoManager = undoManager
            }
        }
    }
}

private struct CardFrontView<I: ExampleInteractorPr>: View {
    @Binding var state: LearnViewModelState
    @State private var showingNewExample = false
    let kanji: Kanji
    let examples: [String]
    let interactor: I
    let showAnswer: () -> ()
    
    var body: some View {
        VStack(spacing: 40) {
            VStack(spacing: 10) {
                KanjiView(kanji: kanji)
                
                AnswerIndicator(state: $state)
            }
            
            ExampleView(showingNewExample: $showingNewExample, examples: examples.sorted())
            
            Spacer()
            
            Button {
                showAnswer()
            } label: {
                Text("Show Answer")
            }
            .buttonStyle(ShrinkingButton(background: .cyan))
        }
        .sheet(isPresented: $showingNewExample, onDismiss: {
            state = state
        }) {
            let viewModel = NewExampleViewModel(interactor: interactor)
            NewRecordView(showingDialog: $showingNewExample, viewModel: viewModel)
        }
    }
}

private struct ExampleView: View {
    @Binding var showingNewExample: Bool
    let examples: [String]
    
    var body: some View {
        VStack {
            StringTableView(array: examples,
                            columns: 3,
                            spacing: 10,
                            display: { $0 })
            .font(.system(size: 20))
            
            Button {
                showingNewExample = true
            } label: {
                HStack {
                    ZStack {
                        Circle()
                            .fill(.gray)
                            .frame(width: 14)
                        
                        Image(systemName: "plus")
                            .resizable()
                            .foregroundStyle(.white)
                            .frame(width: 7, height: 7)
                        
                    }
                    
                    if examples.isEmpty {
                        Text("Example")
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }
}

private struct CardBackView: View {
    @Binding var state: LearnViewModelState
    let kanji: Kanji
    let kanjiData: KanjiData
    let putBack: (GuessResult) -> ()
    
    var body: some View {
        VStack(spacing: 40) {
            VStack(spacing: 10) {
                KanjiView(kanji: kanji)
                
                AnswerIndicator(state: $state)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                YomiView(type: .on, yomi: kanjiData.onyomi)
                
                YomiView(type: .kun, yomi: kanjiData.kunyomi)
            }
            
            Spacer()
            
            HStack {
                Button {
                    putBack(.again)
                } label: {
                    Text("Again")
                }
                .buttonStyle(ShrinkingButton(background: .brown))
                
                Button {
                    putBack(.good)
                } label: {
                    Text("Good")
                }
                .buttonStyle(ShrinkingButton(background: .cyan))
            }
        }
    }
}

private struct KanjiView: View {
    let kanji: Kanji
    
    var body: some View {
        let kanji = String(kanji.character)
        
        Text(kanji)
            .textSelection(.enabled)
            .font(.system(size: 50))
            .shadow(radius: 2)
    }
}

private struct YomiView: View {
    let type: Yomi.YomiType
    let yomi: [Yomi]
    
    var body: some View {
        HStack(alignment: .top) {
            let icon = if case .kun = type { "\u{8A13}" } else { "\u{97F3}" }
            Text(icon)
                .bold()
            
            StringTableView(array: yomi,
                            columns: 3,
                            spacing: 5,
                            display: { $0.value })
                .padding(.leading, 10)
        }
        .font(.system(size: 20))
    }
}

private struct StringTableView<T: Hashable>: View {
    let array: [T]
    let columns: Int
    let spacing: CGFloat
    let display: (T) -> String
    
    var body: some View {
        let rows = split(array, by: columns)
        VStack(alignment: .leading, spacing: spacing) {
            ForEach(rows, id: \.self) { (row: [T]) in
                HStack(spacing: 0) {
                    let row = Array(row.enumerated())
                    ForEach(row, id: \.offset) { index, item in
                        Text(display(item))
                            .textSelection(.enabled)
                        if index != row.count - 1 {
                            Text("\u{30FB}")
                        }
                    }
                }
            }
        }
    }

    private func split(_ arr: [T], by n: Int) -> [[T]] {
        var results = [[T]]()
        var partial = [T]()
        for elt in arr {
            partial.append(elt)
            if partial.count == n {
                results.append(partial)
                partial.removeAll()
            }
        }
        if !partial.isEmpty {
            results.append(partial)
        }
        return results
    }
}

private struct ShrinkingButton<S: ShapeStyle>: ButtonStyle {
    let background: S
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal)
            .padding(.vertical, 7)
            .background(background)
            .foregroundStyle(.white)
            .fontWeight(.medium)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
            .shadow(radius: 1)
    }
}

private struct AnswerIndicator: View {
    @Binding var state: LearnViewModelState
    
    var body: some View {
        let color: Color = switch state {
        case .back(.again): .brown
        case .back(.good): .green
        default: .cyan
        }
        
        Rectangle()
            .fill(color)
            .frame(width: 54, height: 2)
            .shadow(radius: 1)
    }
}
