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
        }
        
        Window("Database", id: "database") {
            DatabaseView(interactor: state.interactor,
                         cardImporter: state.cardImporter,
                         exampleImporter: state.exampleImporter)
        }
        
        Window("Settings", id: "settings") {
            SettingsView(viewModel: state.settingsViewModel)
        }
        .windowResizability(.contentSize)
    }
}

enum Exception: Error {
    case invalidResponse, invalidData, duplicate
}

final class AppState<S: SettingsProviderPr>: ObservableObject {
    typealias SessionConcrete = Session<Interactor, S, DataCacheService>
    @ObservedObject var learnViewModel: LearnViewModel<SessionConcrete, Interactor>
    @ObservedObject var settingsViewModel: SettingsViewModel<S>
    let interactor: Interactor
    let session: SessionConcrete
    let cardImporter: CardRecordImportExport<Interactor>
    let exampleImporter: ExampleRecordImportExport<Interactor>

    init(persistence: NSPersistentContainer, settingsInteractor: S) throws {
        self.interactor = Interactor(persistence: persistence)
        self.session = Session(interactor: interactor,
                               settingsProvider: settingsInteractor,
                               cache: DataCacheService())
        self.learnViewModel = LearnViewModel(session: session,
                                             databaseInteractor: interactor,
                                             dataProvider: KanjipediaService())
        self.cardImporter = CardRecordImportExport(interactor: interactor)
        self.exampleImporter = ExampleRecordImportExport(interactor: interactor)
        self.settingsViewModel = SettingsViewModel(interactor: settingsInteractor)
    }
}
