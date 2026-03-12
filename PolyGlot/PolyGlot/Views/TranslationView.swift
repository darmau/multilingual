import SwiftUI
import SwiftData
import Translation

struct TranslationView: View {
    @State private var viewModel = TranslationViewModel()
    @Query private var settingsList: [Settings]
    @FocusState private var isEditorFocused: Bool
    @Environment(\.navigateToSettings) private var navigateToSettings

    private var settings: Settings {
        settingsList.first ?? Settings()
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                sourceSection
                controlBar
                Divider()
                resultSection
                Spacer(minLength: 0)
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

                // Language badge for source
                LanguageBadge(language: viewModel.sourceLanguage, style: .outline)

                Spacer()

                SpeakButton(text: viewModel.sourceText, language: viewModel.sourceLanguage)
            }

            TextEditor(text: $viewModel.sourceText)
                .frame(minHeight: 80, maxHeight: 140)
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .focused($isEditorFocused)
                .overlay(alignment: .topLeading) {
                    if viewModel.sourceText.isEmpty {
                        Text("输入要翻译的文本...")
                            .font(.body)
                            .foregroundStyle(.tertiary)
                            .padding(.top, 14)
                            .padding(.leading, 12)
                            .allowsHitTesting(false)
                    }
                }
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
                .controlSize(.small)
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
                if viewModel.shouldPreferLocalTranslation(settings: settings) {
                    if #available(macOS 15.0, iOS 18.0, *) {
                        viewModel.prepareLocalTranslation()
                    }
                } else {
                    viewModel.translateWithLLM(settings: settings)
                }
            } label: {
                Label("翻译", systemImage: "arrow.right.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.return, modifiers: .command)
            .accessibilityLabel("翻译")
            .accessibilityHint("将源语言文本翻译为目标语言")
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

                // Language badge for target
                LanguageBadge(language: viewModel.targetLanguage, style: .outline)

                Spacer()

                if !viewModel.translatedText.isEmpty {
                    SpeakButton(text: viewModel.translatedText, language: viewModel.targetLanguage)
                }
            }

            resultContent
                .frame(minHeight: 80)
                .padding(8)
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    @ViewBuilder
    private var resultContent: some View {
        if viewModel.isLoading {
            HStack {
                Spacer()
                ProgressView("翻译中…")
                Spacer()
            }
            .padding(.vertical, 16)
        } else if let error = viewModel.errorMessage {
            VStack(alignment: .leading, spacing: 8) {
                Label(error, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
                    .font(.subheadline)
                if viewModel.isAPIKeyError {
                    APIKeyMissingBanner(navigateToSettings: navigateToSettings)
                }
            }
            .padding(4)
        } else if !viewModel.translatedText.isEmpty {
            // Use FuriganaText for Japanese results
            if viewModel.targetLanguage == .japanese {
                FuriganaText(viewModel.translatedText, font: .body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            } else {
                Text(viewModel.translatedText)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            Text("翻译结果将显示在这里")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Toggle Bar

    private var toggleBar: some View {
        HStack {
            Toggle(isOn: $viewModel.useLocalTranslation) {
                Label(
                    viewModel.shouldPreferLocalTranslation(settings: settings) ? "本地翻译（Apple）" : "云端 AI 翻译",
                    systemImage: viewModel.shouldPreferLocalTranslation(settings: settings) ? "iphone" : "cloud"
                )
                .font(.subheadline)
            }

            if !LLMManager.hasAvailableLLM(settings: settings) && !viewModel.useLocalTranslation {
                Text("未配置 AI 服务，自动使用本地翻译")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - Local Translation Modifier

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
