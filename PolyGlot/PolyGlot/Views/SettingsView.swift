import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsList: [Settings]
    @State private var viewModel = SettingsViewModel()

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
            Form {
                Section("API Keys") {
                    SecureField("OpenAI API Key", text: $viewModel.openaiAPIKey)
                        .textContentType(.password)
                    SecureField("Claude API Key", text: $viewModel.claudeAPIKey)
                        .textContentType(.password)
                    SecureField("Gemini API Key", text: $viewModel.geminiAPIKey)
                        .textContentType(.password)
                }

                Section("LLM 供应商") {
                    Picker("选择 LLM", selection: $viewModel.selectedLLMProvider) {
                        ForEach(LLMProvider.allCases) { provider in
                            Text(provider.displayName).tag(provider)
                        }
                    }
                }

                Section("TTS 供应商") {
                    Picker("选择 TTS", selection: $viewModel.selectedTTSProvider) {
                        ForEach(TTSProvider.allCases) { provider in
                            Text(provider.displayName).tag(provider)
                        }
                    }
                }

                Section("日语水平") {
                    Picker("振假名级别", selection: $viewModel.japaneseFuriganaLevel) {
                        ForEach(JapaneseProficiency.allCases) { level in
                            Text(level.displayName).tag(level)
                        }
                    }
                }
            }
            .navigationTitle("设置")
            .onAppear {
                viewModel.load(from: settings)
            }
            .onChange(of: viewModel.openaiAPIKey) { _, _ in viewModel.save(to: settings) }
            .onChange(of: viewModel.claudeAPIKey) { _, _ in viewModel.save(to: settings) }
            .onChange(of: viewModel.geminiAPIKey) { _, _ in viewModel.save(to: settings) }
            .onChange(of: viewModel.selectedLLMProvider) { _, _ in viewModel.save(to: settings) }
            .onChange(of: viewModel.selectedTTSProvider) { _, _ in viewModel.save(to: settings) }
            .onChange(of: viewModel.japaneseFuriganaLevel) { _, _ in viewModel.save(to: settings) }
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: Settings.self, inMemory: true)
}
