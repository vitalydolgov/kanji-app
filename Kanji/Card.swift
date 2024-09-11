import Foundation

protocol CardPr {
    var kanji: Kanji { get }
    var state: CardState { get set }
}

struct CardImport: CardPr {
    let kanji: Kanji
    var state: CardState
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

struct KanjiData {
    let kanji: Kanji
    let yomi: [Yomi]
        
    var onyomi: [Yomi] {
        yomi.filter { $0.type == .on }
    }

    var kunyomi: [Yomi] {
        yomi.filter { $0.type == .kun }
    }
}

struct Kanji {
    let value: Unicode.Scalar
    
    init?(_ value: Int32) {
        guard let value = Unicode.Scalar(Int(value)) else {
            return nil
        }
        self.value = value
    }
    
    init?(_ character: Character) {
        guard let scalar = character.unicodeScalars.first else {
            return nil
        }
        value = scalar
    }
    
    var character: Character {
        Character(value)
    }
    
    var description: String {
        "\(character)"
    }
}

struct Yomi: Hashable {
    let type: YomiType
    let value: String
    
    enum YomiType {
        case on, kun
    }
}
