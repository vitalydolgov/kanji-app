import SwiftUI

struct SettingsItemView: View {
    @StateObject var viewModel: SettingsItemViewModel
    
    var body: some View {
        HStack {
            Text(viewModel.label)
         
            Spacer()
            
            TextField("", value: $viewModel.value, formatter: viewModel.formatter)
                .frame(maxWidth: 40)
        }
    }
}
