import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var settingsList: [Settings]
    @State private var viewModel = SettingsViewModel()

    private var settings: Settings {
        settingsList.first ?? Settings()
    }

    var body: some View {
        Form {
            // MARK: - Language
            Section {
                Picker("Interface Language", selection: $viewModel.interfaceLanguage) {
                    ForEach(InterfaceLanguage.allCases) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }
            } header: {
                Text("Interface Language")
            } footer: {
                Text("Also determines the language used for AI explanations")
            }

            // MARK: - Learning Languages
            Section {
                ForEach(Array(viewModel.learningLanguages.enumerated()), id: \.element) { index, lang in
                    HStack {
                        Circle()
                            .fill(Color.language(lang))
                            .frame(width: 8, height: 8)
                        Text(lang.displayName)
                    }
                    .swipeActions(edge: .trailing) {
                        if viewModel.learningLanguages.count > 1 {
                            Button(role: .destructive) {
                                viewModel.removeLanguage(at: index)
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                    }
                }

                if viewModel.canAddMoreLanguages {
                    Menu {
                        ForEach(viewModel.availableLanguagesToAdd) { lang in
                            Button(lang.displayName) {
                                viewModel.addLanguage(lang)
                            }
                        }
                    } label: {
                        Label("Add Language", systemImage: "plus.circle")
                    }
                }
            } header: {
                Text("Learning Languages")
            } footer: {
                Text("Choose up to 3 languages (\(viewModel.learningLanguages.count)/3)")
            }

            // MARK: - Service Providers
            Section("Service Providers") {
                Picker("LLM Engine", selection: $viewModel.selectedLLMProvider) {
                    ForEach(LLMProvider.allCases) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }

                Picker("Voice Synthesis", selection: $viewModel.selectedTTSProvider) {
                    ForEach(TTSProvider.allCases) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }
            }

            // MARK: - API Keys
            Section {
                APIKeyField(label: "OpenAI", placeholder: "sk-...", text: $viewModel.openaiAPIKey)
                APIKeyField(label: "Claude", placeholder: "sk-ant-...", text: $viewModel.claudeAPIKey)
                APIKeyField(label: "Gemini", placeholder: "AIza...", text: $viewModel.geminiAPIKey)
            } header: {
                Text("API Keys")
            } footer: {
                Text("Optional — configure to enable cloud AI analysis")
            }

            // MARK: - Connection Test
            Section {
                Button {
                    Task { await viewModel.testConnection(settings: settings) }
                } label: {
                    HStack {
                        Text("Test Connection")
                        Spacer()
                        if viewModel.isTesting {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                }
                .disabled(viewModel.isTesting || !settings.hasActiveAPIKey)

                if viewModel.showTestResult {
                    HStack(spacing: 8) {
                        Image(systemName: viewModel.testResultIsSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(viewModel.testResultIsSuccess ? .green : .red)
                        Text(viewModel.testResultMessage)
                            .font(.subheadline)
                            .foregroundStyle(viewModel.testResultIsSuccess ? .green : .red)
                    }
                    .transition(.opacity)
                }
            }
            .animation(.default, value: viewModel.showTestResult)

            // MARK: - Local Capabilities
            Section {
                Toggle("System Dictionary", isOn: $viewModel.useSystemDictionary)

                LabeledContent("Apple Intelligence") {
                    Text(AppleIntelligenceAvailability.isAvailable ? String(localized: "Available") : String(localized: "Unavailable"))
                        .foregroundStyle(AppleIntelligenceAvailability.isAvailable ? .green : .secondary)
                }

                LabeledContent("Local TTS") {
                    Text("Available")
                        .foregroundStyle(.green)
                }

                LabeledContent("Apple Translation") {
                    Text("Available")
                        .foregroundStyle(.green)
                }
            } header: {
                Text("Local Capabilities")
            } footer: {
                Text("Features available without API Key")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
        .onAppear {
            viewModel.load(from: settings)
        }
        .onChange(of: viewModel.openaiAPIKey) { _, _ in viewModel.save(to: settings) }
        .onChange(of: viewModel.claudeAPIKey) { _, _ in viewModel.save(to: settings) }
        .onChange(of: viewModel.geminiAPIKey) { _, _ in viewModel.save(to: settings) }
        .onChange(of: viewModel.selectedLLMProvider) { _, _ in viewModel.save(to: settings) }
        .onChange(of: viewModel.selectedTTSProvider) { _, _ in viewModel.save(to: settings) }
        .onChange(of: viewModel.useSystemDictionary) { _, _ in viewModel.save(to: settings) }
        .onChange(of: viewModel.interfaceLanguage) { _, _ in
            viewModel.syncLearningLanguagesWithNative()
            viewModel.save(to: settings)
        }
        .onChange(of: viewModel.learningLanguages) { _, _ in viewModel.save(to: settings) }
    }
}

// MARK: - API Key Field

private struct APIKeyField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    @State private var isRevealed = false

    var body: some View {
        HStack {
            Text(label)
                .frame(width: 60, alignment: .leading)
            if isRevealed {
                TextField(placeholder, text: $text)
                    .font(.footnote.monospaced())
                    .autocorrectionDisabled()
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    #endif
            } else {
                SecureField(placeholder, text: $text)
                    .font(.footnote.monospaced())
            }
            Button {
                isRevealed.toggle()
            } label: {
                Image(systemName: isRevealed ? "eye.slash" : "eye")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
            .buttonStyle(.plain)

            Circle()
                .fill(text.isEmpty ? Color.secondary.opacity(0.3) : Color.green)
                .frame(width: 7, height: 7)
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(for: Settings.self, inMemory: true)
}
