import SwiftUI

struct TranslationView: View {
    @State private var viewModel = TranslationViewModel()

    var body: some View {
        NavigationStack {
            Text("翻译功能开发中...")
                .font(.title2)
                .foregroundStyle(.secondary)
                .navigationTitle("翻译")
        }
    }
}

#Preview {
    TranslationView()
}
