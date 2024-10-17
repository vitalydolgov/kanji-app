import SwiftUI

@main
struct KanjiApp: App {
    let persistence = PersistenceController.shared
    @ObservedObject var state: AppState
    @FocusedValue(\.window) var secondaryWindow: FocusedWindow?
    
    init() {
        self.state = try! AppState(context: persistence.container.viewContext)
    }
    
    var body: some Scene {
        Window("Learn", id: "learn") {
            LearnView(viewModel: state.learnViewModel)
        }
        .commands {
            CommandGroup(after: .newItem, addition: {
                Button("Save Progress") {
                    Task {
                        try await state.session.saveCards()
                    }
                }
                .disabled(secondaryWindow != nil)
            })
            
            CommandMenu("Database") {
                Group {
                    ImportCommand(interactor: state.interactor)
                    
                    ExportCommand(interactor: state.interactor)
                    
                    Button("Delete All") {
                        state.databaseViewModel.showingDeleteConfirmation = true
                    }
                }
                .disabled(secondaryWindow?.type != .database)
            }
        }
        
        Window("Database", id: "database") {
            DatabaseView(viewModel: state.databaseViewModel)
        }
        
        Window("Settings", id: "settings") {
            SettingsView(viewModel: state.settingsViewModel)
        }
        .windowResizability(.contentSize)
    }
}

enum Exception: Error {
    case invalidResponse, invalidData
}

final class AppState: ObservableObject {
    @ObservedObject var databaseViewModel: DatabaseViewModel<CardInteractor>
    @ObservedObject var learnViewModel: LearnViewModel<Session<CardInteractor>>
    @ObservedObject var settingsViewModel: SettingsViewModel<SettingsInteractorUserDefaults>
    let interactor: CardInteractor
    let session: Session<CardInteractor>
    
    init(context: NSManagedObjectContext) throws {
        self.interactor = CardInteractor(context: context)
        self.session = try Session(interactor: interactor,
                                   settingsProvider: SettingsInteractorUserDefaults())
        self.learnViewModel = LearnViewModel(session: session, dataProvider: KanjipediaService())
        self.databaseViewModel = DatabaseViewModel(interactor: interactor)
        self.settingsViewModel = SettingsViewModel(interactor: SettingsInteractorUserDefaults())
    }
}
