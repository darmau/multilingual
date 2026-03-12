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
                // Input area
                VStack(alignment: .leading, spacing: 8) {
                    TextEditor(text: $viewModel.questionText)
                        .frame(minHeight: 100, maxHeight: 160)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .focused($isEditorFocused)

                    HStack {
                        Spacer()

                        if !viewModel.questionText.isEmpty {
                            Button("清除", role: .destructive) {
                                viewModel.clear()
                            }
                            .buttonStyle(.borderless)
                        }

                        Button {
                            isEditorFocused = false
                            Task {
                                await viewModel.send(settings: settings)
                            }
                        } label: {
                            Label("发送", systemImage: "paperplane.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!viewModel.canSend)
                    }
                }
                .padding()

                Divider()

                // Response area
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        if viewModel.isLoading {
                            HStack {
                                Spacer()
                                ProgressView("思考中…")
                                Spacer()
                            }
                            .padding(.top, 40)
                        } else if let error = viewModel.errorMessage {
                            Label(error, systemImage: "exclamationmark.triangle")
                                .foregroundStyle(.red)
                                .padding()
                        } else if !viewModel.answerText.isEmpty {
                            HStack(alignment: .top, spacing: 8) {
                                Text(viewModel.answerText)
                                    .textSelection(.enabled)

                                if let lang = viewModel.answerLanguage {
                                    SpeakButton(text: viewModel.answerText, language: lang)
                                }
                            }
                            .padding()
                        } else {
                            ContentUnavailableView(
                                "输入问题开始对话",
                                systemImage: "questionmark.bubble",
                                description: Text("支持中文、英语、日语、韩语提问")
                            )
                            .padding(.top, 40)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .navigationTitle("提问")
        }
    }
}

#Preview {
    QuestionView()
        .modelContainer(for: Settings.self, inMemory: true)
}
