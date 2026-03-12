import SwiftUI

struct SentenceView: View {
    @State private var viewModel = SentenceViewModel()

    var body: some View {
        NavigationStack {
            Text("句子分析功能开发中...")
                .font(.title2)
                .foregroundStyle(.secondary)
                .navigationTitle("句子分析")
        }
    }
}

#Preview {
    SentenceView()
}
