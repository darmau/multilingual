import SwiftUI

struct DictionaryView: View {
    @State private var viewModel = DictionaryViewModel()

    var body: some View {
        NavigationStack {
            Text("词典功能开发中...")
                .font(.title2)
                .foregroundStyle(.secondary)
                .navigationTitle("词典")
        }
    }
}

#Preview {
    DictionaryView()
}
