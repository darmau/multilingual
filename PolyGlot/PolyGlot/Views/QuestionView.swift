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
            .navigationTitle("Question")
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
                        Text("Ask a question in any language...")
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
                    Button("Clear", role: .destructive) {
                        viewModel.clear()
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.small)
                }
                Button {
                    sendQuestion()
                } label: {
                    Label("Send", systemImage: "paperplane.fill")
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return, modifiers: .command)
                .accessibilityLabel("Send Question")
                .accessibilityHint("Send to AI for an answer")
                .disabled(!viewModel.canSend)
            }
        }
        .padding()
        .background(.bar)
    }

    // MARK: - Response Area

    @ViewBuilder
    private var responseArea: some View {
        if !viewModel.answerText.isEmpty {
            // Show streaming/completed answer (prioritize content over loading state)
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Language badge for detected language
                    HStack {
                        if let lang = viewModel.answerLanguage {
                            LanguageBadge(language: lang)
                        }
                        Spacer()
                        if viewModel.isLoading {
                            ProgressView()
                                .controlSize(.small)
                        }
                        if let lang = viewModel.answerLanguage, !viewModel.isLoading {
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
        } else if viewModel.isLoading {
            LoadingView(message: "Thinking...")
        } else if let error = viewModel.errorMessage {
            ScrollView {
                ErrorBanner(message: error, retryAction: { sendQuestion() },
                            isAPIKeyError: viewModel.isAPIKeyError)
                    .padding()
            }
        } else {
            VStack(spacing: 16) {
                EmptyStateView(
                    systemImage: "questionmark.bubble",
                    title: "Enter a question to start",
                    subtitle: "Supports questions in Chinese, English, Japanese, Korean"
                )
                if !settings.hasActiveAPIKey && !AppleIntelligenceAvailability.isAvailable {
                    Text("This feature requires an API Key or Apple Intelligence")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
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
