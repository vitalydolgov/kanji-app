import Foundation

protocol DefaultPr {
    var `default`: Settings { get }
}

protocol SettingsInteractorPr {
    func fetchSettings() -> Settings?
    func saveSettings(_ settings: Settings) throws
}

typealias SettingsProviderPr = SettingsInteractorPr & DefaultPr

struct Settings {
    let maxAdditionalCards: Int
    let newLearnedRatio: Double
}

struct SettingsInteractorUserDefaults: SettingsProviderPr {
    var `default`: Settings {
        Settings(maxAdditionalCards: 20, newLearnedRatio: 0.8)
    }
    
    func fetchSettings() -> Settings? {
        guard let settings = UserDefaults.standard.dictionary(forKey: "settings"),
              let maxAdditionalCards = settings["maxAdditionalCards"] as? Int,
              let newLearnedRatio = settings["newLearnedRatio"] as? Double else {
            return nil
        }
        return Settings(maxAdditionalCards: maxAdditionalCards,
                        newLearnedRatio: newLearnedRatio)
    }
    
    func saveSettings(_ settings: Settings) throws {
        let export: [String: Any] = [
            "maxAdditionalCards": settings.maxAdditionalCards,
            "newLearnedRatio": settings.newLearnedRatio
        ]
        UserDefaults.standard.setValue(export, forKey: "settings")
    }
}

