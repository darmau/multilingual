import SwiftUI
import SwiftData

struct QuestionView: View {
    @State private var viewModel = QuestionViewModel()
    @Query private var settingsList: [Settings]
    @Environment(\.modelContext) private var modelContext
    @FocusState private var isInputFocused: Bool

    private var settings: Settings {
        if let existing = settingsList.first {
            return existing
        }
        let newSettings = Settings()
        modelContext.insert(newSettings)
        return newSettings
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 输入区域
                inputSection

                Divider()

                // 回复区域
                responseSection
            }
            .navigationTitle("提问")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完成") {
                        isInputFocused = false
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if !viewModel.responseText.isEmpty {
                        Button("清空", role: .destructive) {
                            viewModel.clear()
                        }
                    }
                }
            }
        }
    }

    private var inputSection: some View {
        VStack(spacing: 12) {
            TextEditor(text: $viewModel.questionText)
                .focused($isInputFocused)
                .frame(minHeight: 80, maxHeight: 150)
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(alignment: .topLeading) {
                    if viewModel.questionText.isEmpty {
                        Text("输入你的问题...")
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 16)
                            .allowsHitTesting(false)
                    }
                }

            Button {
                isInputFocused = false
                Task {
                    await viewModel.send(settings: settings)
                }
            } label: {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(viewModel.isLoading ? "思考中..." : "发送")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.canSend)
        }
        .padding()
    }

    private var responseSection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if let error = viewModel.errorMessage {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .font(.callout)
                        .padding()
                }

                if !viewModel.responseText.isEmpty {
                    HStack(alignment: .top, spacing: 8) {
                        Text(LocalizedStringKey(viewModel.responseText))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if let lang = viewModel.detectedLanguage {
                            SpeakButton(text: viewModel.responseText, language: lang)
                        }
                    }
                    .padding()
                }
            }
        }
        .frame(maxHeight: .infinity)
        .animation(.default, value: viewModel.responseText)
    }
}

#Preview {
    QuestionView()
        .modelContainer(for: Settings.self, inMemory: true)
}
