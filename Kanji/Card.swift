import Foundation

protocol CardPr: Identifiable {
    var kanji: Kanji? { get set }
    var state: CardState { get set }
}

struct CardImport: CardPr {
    let id = UUID()
    var kanji: Kanji?
    var state: CardState
    
    init(kanji: Kanji, state: CardState) {
        self.kanji = kanji
        self.state = state
    }
}

enum CardState: Int, CaseIterable, Identifiable, CustomStringConvertible {
    case new = 0, `repeat`, learned
    
    var id: Self { self }
    
    var description: String {
        switch self {
        case .new:
            "New"
        case .repeat:
            "Repeat"
        case .learned:
            "Learned"
        }
    }
}

struct KanjiData: Codable {
    let yomi: [Yomi]
        
    var onyomi: [Yomi] {
        yomi.filter { $0.type == .on }
    }

    var kunyomi: [Yomi] {
        yomi.filter { $0.type == .kun }
    }
}

struct Kanji: Hashable {
    let character: Character
    
    init(_ character: Character) {
        self.character = character
    }

    init?(_ array: [UInt16]) {
        guard !array.isEmpty else {
            return nil
        }
        let string = array.compactMap { UnicodeScalar($0) }.reduce("") { $0 + String($1) }
        self.init(Character(string))
    }
    
    var description: String {
        "\(character)"
    }
}

public struct Yomi: Hashable, Codable {
    let type: YomiType
    let value: String
    
    enum YomiType: Codable {
        case on, kun
    }
}
