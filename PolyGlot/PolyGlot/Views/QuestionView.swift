import SwiftUI

struct QuestionView: View {
    @State private var viewModel = QuestionViewModel()

    var body: some View {
        NavigationStack {
            Text("提问功能开发中...")
                .font(.title2)
                .foregroundStyle(.secondary)
                .navigationTitle("提问")
        }
    }
}

#Preview {
    QuestionView()
}
