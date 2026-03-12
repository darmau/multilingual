import SwiftUI
import SwiftData

struct QuestionView: View {
    @State private var viewModel = QuestionViewModel()
    @Query private var settingsList: [Settings]
    @FocusState private var isEditorFocused: Bool

    private var settings: Settings {
        settingsList.first ?? Settings()
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                inputArea
                Divider()
                responseArea
            }
            .navigationTitle("提问")
        }
    }

    // MARK: - Input Area

    private var inputArea: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextEditor(text: $viewModel.questionText)
                .frame(minHeight: 80, maxHeight: 140)
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .focused($isEditorFocused)
                .overlay(alignment: .topLeading) {
                    if viewModel.questionText.isEmpty {
                        Text("输入任何语言的问题...")
                            .font(.body)
                            .foregroundStyle(.tertiary)
                            .padding(.top, 14)
                            .padding(.leading, 12)
                            .allowsHitTesting(false)
                    }
                }
                .onSubmit { sendQuestion() }

            HStack {
                Spacer()
                if !viewModel.questionText.isEmpty {
                    Button("清除", role: .destructive) {
                        viewModel.clear()
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.small)
                }
                Button {
                    sendQuestion()
                } label: {
                    Label("发送", systemImage: "paperplane.fill")
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return, modifiers: .command)
                .accessibilityLabel("发送问题")
                .accessibilityHint("发送到 AI 获取回答")
                .disabled(!viewModel.canSend)
            }
        }
        .padding()
        .background(.bar)
    }

    // MARK: - Response Area

    @ViewBuilder
    private var responseArea: some View {
        if viewModel.isLoading {
            LoadingView(message: "思考中...")
        } else if let error = viewModel.errorMessage {
            ScrollView {
                ErrorBanner(message: error, retryAction: { sendQuestion() },
                            isAPIKeyError: viewModel.isAPIKeyError)
                    .padding()
            }
        } else if !viewModel.answerText.isEmpty {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Language badge for detected language
                    if let lang = viewModel.answerLanguage {
                        HStack {
                            LanguageBadge(language: lang)
                            Spacer()
                            SpeakButton(text: viewModel.answerText, language: lang)
                        }
                    }

                    // Answer text
                    if viewModel.answerLanguage == .japanese {
                        FuriganaText(viewModel.answerText, font: .body)
                    } else {
                        Text(viewModel.answerText)
                            .font(.body)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
                .cardStyle()
                .padding()
            }
        } else {
            EmptyStateView(
                systemImage: "questionmark.bubble",
                title: "输入问题开始对话",
                subtitle: "支持中文、英语、日语、韩语提问"
            )
        }
    }

    private func sendQuestion() {
        guard viewModel.canSend else { return }
        isEditorFocused = false
        viewModel.send(settings: settings)
    }
}

#Preview {
    QuestionView()
        .modelContainer(for: Settings.self, inMemory: true)
}
