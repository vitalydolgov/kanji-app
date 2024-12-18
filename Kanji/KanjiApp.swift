import SwiftUI

@main
struct KanjiApp: App {
    @ObservedObject var state: AppState<SettingsInteractorUserDefaults>
    @FocusedValue(\.window) var secondaryWindow: FocusedWindow?
    
    init() {
        self.state = try! AppState(persistence: PersistenceController().container,
                                   settingsInteractor: SettingsInteractorUserDefaults())
    }
    
    var body: some Scene {
        Window("Learn", id: "learn") {
            LearnView(viewModel: state.learnViewModel)
        }
        .commands {
            CommandGroup(after: .newItem, addition: {
                Group {
                    Button("Undo") {
                        guard state.learnViewModel.state != .start else {
                            return
                        }
                        OperationDispatch.unexecute(for: state.session, count: 2)
                        state.learnViewModel.state = .loading
                    }
                    .keyboardShortcut("z")
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

final class AppState<S: SettingsProviderPr>: ObservableObject {
    typealias SessionCo = Session<Interactor, S, DataCacheService>
    @ObservedObject var databaseViewModel: DatabaseViewModel<Interactor>
    @ObservedObject var learnViewModel: LearnViewModel<SessionCo>
    @ObservedObject var settingsViewModel: SettingsViewModel<S>
    let interactor: Interactor
    let session: SessionCo
    
    init(persistence: NSPersistentContainer, settingsInteractor: S) throws {
        self.interactor = Interactor(persistence: persistence)
        self.session = Session(interactor: interactor,
                               settingsProvider: settingsInteractor,
                               cache: DataCacheService())
        self.learnViewModel = LearnViewModel(session: session, dataProvider: KanjipediaService())
        self.databaseViewModel = DatabaseViewModel(interactor: interactor)
        self.settingsViewModel = SettingsViewModel(interactor: settingsInteractor)
    }
}
