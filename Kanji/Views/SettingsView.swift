import SwiftUI

struct SettingsView: View {
    @StateObject var viewModel: SettingsViewModel<SettingsInteractorUserDefaults>
    
    var body: some View {
        VStack {
            ForEach(viewModel.items) { item in
                SettingsItemView(viewModel: item)
            }
        }
        .padding(.horizontal)
        .frame(width: 300, height: 100)
    }
}
