import SwiftUI

struct LearnView: View {
    @ObservedObject var viewModel: LearnViewModel<Session<CardInteractor>>
    
    var body: some View {
        VStack(spacing: 20) {
            if case .front = viewModel.state, let kanjiData = viewModel.kanjiData {
                CardFrontView(kanjiData: kanjiData, showAnswer: viewModel.showAnswer)
            } else if case .back = viewModel.state, let kanjiData = viewModel.kanjiData {
                CardBackView(kanjiData: kanjiData, putBack: viewModel.putBackTakeNext)
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
            }
        }
        .padding(.vertical, 20)
        .onAppear {
            Task { try? await viewModel.takeNextCard() }
        }
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
    }
}

struct CardFrontView: View {
    let kanjiData: KanjiData
    let showAnswer: () -> ()
    
    var body: some View {
        VStack(spacing: 20) {
            KanjiView(kanji: kanjiData.kanji)
            
            Spacer()
            
            Button {
                showAnswer()
            } label: {
                Text("Show Answer")
            }
        }
    }
}

struct CardBackView: View {
    let kanjiData: KanjiData
    let putBack: (GuessResult) -> ()
    
    var body: some View {
        VStack(spacing: 40) {
            KanjiView(kanji: kanjiData.kanji)
                
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
                
                Button {
                    putBack(.good)
                } label: {
                    Text("Good")
                }
            }
        }
    }
}

struct KanjiView: View {
    let kanji: Kanji
    
    var body: some View {
        let kanji = String(kanji.value)
        
        VStack(spacing: 0) {
            Text(kanji)
                .textSelection(.enabled)
                .font(.system(size: 50))
            
            Rectangle()
                .fill(.gray)
                .frame(width: 54, height: 2)
        }
    }
}

struct YomiView: View {
    let type: Yomi.YomiType
    let yomi: [Yomi]
    
    var body: some View {
        HStack(alignment: .top) {
            let icon = if case .kun = type { "\u{97F3}" } else { "\u{8A13}" }
            Text(icon)
                .bold()
            
            table(for: yomi, columns: 3)
                .padding(.leading, 10)
        }
        .font(.system(size: 20))
    }
    
    private func table(for yomi: [Yomi], columns: Int) -> some View {
        let rows = splitYomi(by: columns)
        return VStack(alignment: .leading) {
            ForEach(rows, id: \.self) { (row: [Yomi]) in
                HStack(spacing: 0) {
                    let row = Array(row.enumerated())
                    ForEach(row, id: \.offset) { index, item in
                        Text(item.value)
                        if index != row.count - 1 {
                            Text("\u{30FB}")
                        }
                    }
                }
            }
        }
    }
    
    private func splitYomi(by n: Int) -> [[Yomi]] {
        var results = [[Yomi]]()
        var partial = [Yomi]()
        for y in yomi {
            partial.append(y)
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
