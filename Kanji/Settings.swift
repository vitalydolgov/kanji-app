import Foundation

protocol DefaultPr {
    func `default`() -> Settings
}

protocol SettingsInteractorPr {
    func fetchSettings() -> Settings?
    func saveSettings(_ settings: borrowing Settings) throws
}

typealias SettingsProviderPr = SettingsInteractorPr & DefaultPr

struct Settings: ~Copyable {
    var maxCardsTotal: Int
    var maxAdditionalCards: Int
    var newLearnedRatio: Double
}

struct SettingsInteractorUserDefaults: SettingsProviderPr {
    func `default`() -> Settings {
        Settings(maxCardsTotal: 0, maxAdditionalCards: 20, newLearnedRatio: 0.8)
    }
    
    func fetchSettings() -> Settings? {
        guard let settings = UserDefaults.standard.dictionary(forKey: "settings"),
              let maxCardsTotal = settings["maxCardsTotal"] as? Int,
              let maxAdditionalCards = settings["maxAdditionalCards"] as? Int,
              let newLearnedRatio = settings["newLearnedRatio"] as? Double else {
            return nil
        }
        return Settings(maxCardsTotal: maxCardsTotal,
                        maxAdditionalCards: maxAdditionalCards,
                        newLearnedRatio: newLearnedRatio)
    }
    
    func saveSettings(_ settings: borrowing Settings) throws {
        let export: [String: Any] = [
            "maxCardsTotal": settings.maxCardsTotal,
            "maxAdditionalCards": settings.maxAdditionalCards,
            "newLearnedRatio": settings.newLearnedRatio
        ]
        UserDefaults.standard.setValue(export, forKey: "settings")
    }
}

