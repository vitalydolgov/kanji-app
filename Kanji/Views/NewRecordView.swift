import SwiftUI

struct NewRecordView<M, I>: View where M: NewRecordViewModel<String, I> {
    @Binding var showingDialog: Bool
    var viewModel: M
    @State private var input = ""
    
    var body: some View {
        VStack {
            TextField("", text: $input)
            
            HStack {
                Button {
                    do {
                        try viewModel.save(input)
                        showingDialog = false
                    } catch {
                        
                    }
                } label: {
                    Text("Save")
                }
                .buttonStyle(.borderedProminent)
                
                Button {
                    showingDialog = false
                } label: {
                    Text("Close")
                }
            }
        }
        .padding()
        .frame(maxWidth: 200)
    }
}
