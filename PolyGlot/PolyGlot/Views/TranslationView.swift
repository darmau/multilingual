import SwiftUI
import SwiftData
import Translation

struct TranslationView: View {
    @State private var viewModel = TranslationViewModel()
    @Query private var settingsList: [Settings]
    @FocusState private var isEditorFocused: Bool

    private var settings: Settings {
        settingsList.first ?? Settings()
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Source section
                sourceSection

                // Swap & Translate buttons
                controlBar

                Divider()

                // Result section
                resultSection

                Spacer(minLength: 0)

                // Local/Cloud toggle
                toggleBar
            }
            .navigationTitle("翻译")
            .modifier(LocalTranslationModifier(viewModel: viewModel))
        }
    }

    // MARK: - Source Section

    private var sourceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Picker("源语言", selection: $viewModel.sourceLanguage) {
                    ForEach(SupportedLanguage.allCases) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }
                .labelsHidden()
                #if os(iOS)
                .pickerStyle(.menu)
                #endif

                Spacer()

                SpeakButton(text: viewModel.sourceText, language: viewModel.sourceLanguage)
            }

            TextEditor(text: $viewModel.sourceText)
                .frame(minHeight: 80, maxHeight: 140)
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(Color.secondary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .focused($isEditorFocused)
        }
        .padding(.horizontal)
        .padding(.top)
    }

    // MARK: - Control Bar

    private var controlBar: some View {
        HStack(spacing: 16) {
            if !viewModel.sourceText.isEmpty {
                Button("清除", role: .destructive) {
                    viewModel.clear()
                }
                .buttonStyle(.borderless)
            }

            Spacer()

            Button {
                viewModel.swapLanguages()
            } label: {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.title3)
            }
            .disabled(viewModel.isLoading)
            .accessibilityLabel("交换语言")

            Spacer()

            Button {
                isEditorFocused = false
                if viewModel.useLocalTranslation {
                    if #available(macOS 15.0, iOS 18.0, *) {
                        viewModel.prepareLocalTranslation()
                    }
                } else {
                    Task {
                        await viewModel.translateWithLLM(settings: settings)
                    }
                }
            } label: {
                Label("翻译", systemImage: "arrow.right.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.canTranslate)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Result Section

    private var resultSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Picker("目标语言", selection: $viewModel.targetLanguage) {
                    ForEach(SupportedLanguage.allCases) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }
                .labelsHidden()
                #if os(iOS)
                .pickerStyle(.menu)
                #endif

                Spacer()

                if !viewModel.translatedText.isEmpty {
                    SpeakButton(text: viewModel.translatedText, language: viewModel.targetLanguage)
                }
            }

            ScrollView {
                Group {
                    if viewModel.isLoading {
                        HStack {
                            Spacer()
                            ProgressView("翻译中…")
                            Spacer()
                        }
                        .padding(.top, 24)
                    } else if let error = viewModel.errorMessage {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                    } else if !viewModel.translatedText.isEmpty {
                        Text(viewModel.translatedText)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Text("翻译结果将显示在这里")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(8)
            }
            .frame(minHeight: 80)
            .background(Color.secondary.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // MARK: - Toggle Bar

    private var toggleBar: some View {
        Toggle(isOn: $viewModel.useLocalTranslation) {
            Label(
                viewModel.useLocalTranslation ? "本地翻译" : "云端 AI 翻译",
                systemImage: viewModel.useLocalTranslation ? "iphone" : "cloud"
            )
            .font(.subheadline)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

/// ViewModifier that conditionally applies `.translationTask` on macOS 15+ / iOS 18+
private struct LocalTranslationModifier: ViewModifier {
    var viewModel: TranslationViewModel

    func body(content: Content) -> some View {
        if #available(macOS 15.0, iOS 18.0, *) {
            content.translationTask(
                viewModel.translationConfiguration as? TranslationSession.Configuration
            ) { session in
                await viewModel.translateWithSession(session)
            }
        } else {
            content
        }
    }
}

#Preview {
    TranslationView()
        .modelContainer(for: Settings.self, inMemory: true)
}
