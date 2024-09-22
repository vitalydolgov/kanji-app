import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel<SettingsInteractorUserDefaults>
    
    var body: some View {
        VStack {
            HStack {
                Text("Maximum additional cards")
             
                Spacer()
                
                TextField("", value: $viewModel.maxAdditionalCards, format: .number)
                    .frame(maxWidth: 40)
            }
                
            HStack {
                Text("Percentage of new cards")
                
                Spacer()

                TextField("Percentage of new cards", value: $viewModel.newLearnedRatio, format: .percent)
                    .frame(maxWidth: 40)
            }
        }
        .padding()
        .frame(width: 300, height: 100)
        .onAppear {
            viewModel.setupSubscriptions()
        }
    }
}
