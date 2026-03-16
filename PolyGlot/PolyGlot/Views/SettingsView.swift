import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var settingsList: [Settings]
    @State private var viewModel = SettingsViewModel()

    private var settings: Settings {
        settingsList.first ?? Settings()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    languageCard
                    learningLanguagesCard
                    offlineCapabilitiesCard
                    apiKeysCard
                    providerCard
                    connectionTestCard
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .background(.background.secondary)
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

    // MARK: - Language Card (Interface/Native Language)

    private var languageCard: some View {
        SettingsCard(
            icon: "globe",
            title: "Interface Language",
            subtitle: "App display language & native language",
            iconColor: Color(red: 0.20, green: 0.55, blue: 0.95)
        ) {
            HStack(spacing: 12) {
                Image(systemName: "character.bubble")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(red: 0.20, green: 0.55, blue: 0.95))
                    .frame(width: 28)
                Text("Interface Language")
                    .font(.subheadline)
                Spacer()
                Picker("", selection: $viewModel.interfaceLanguage) {
                    ForEach(InterfaceLanguage.allCases) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }
                .labelsHidden()
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Learning Languages Card

    private var learningLanguagesCard: some View {
        SettingsCard(
            icon: "book.fill",
            title: "Learning Languages",
            subtitle: "Choose up to 3 languages to learn",
            iconColor: Color(red: 0.62, green: 0.25, blue: 0.83)
        ) {
            VStack(spacing: 12) {
                // Current learning languages
                ForEach(Array(viewModel.learningLanguages.enumerated()), id: \.element) { index, lang in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.language(lang))
                            .frame(width: 8, height: 8)
                        Text(lang.displayName)
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        if viewModel.learningLanguages.count > 1 {
                            Button {
                                viewModel.removeLanguage(at: index)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.red.opacity(0.7))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                    if index < viewModel.learningLanguages.count - 1 {
                        Divider().padding(.leading, 28)
                    }
                }

                // Add language button
                if viewModel.canAddMoreLanguages {
                    Divider()
                    Menu {
                        ForEach(viewModel.availableLanguagesToAdd) { lang in
                            Button(lang.displayName) {
                                viewModel.addLanguage(lang)
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(Color(red: 0.62, green: 0.25, blue: 0.83))
                            Text("Add Language")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Color(red: 0.62, green: 0.25, blue: 0.83))
                            Spacer()
                            Text("\(viewModel.learningLanguages.count)/3")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                } else {
                    HStack {
                        Spacer()
                        Text("Maximum 3 languages reached")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Offline Capabilities Card

    private var offlineCapabilitiesCard: some View {
        SettingsCard(
            icon: "arrow.down.circle.fill",
            title: "Offline & Local Capabilities",
            subtitle: "Features available without API Key",
            iconColor: Color(red: 0.18, green: 0.72, blue: 0.45)
        ) {
            VStack(spacing: 12) {
                // Apple Intelligence status
                HStack(spacing: 12) {
                    Image(systemName: "brain")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.purple)
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Apple Intelligence")
                            .font(.subheadline.weight(.medium))
                        Text(AppleIntelligenceAvailability.statusDescription)
                            .font(.caption)
                            .foregroundStyle(AppleIntelligenceAvailability.isAvailable ? .green : .secondary)
                    }
                    Spacer()
                    Circle()
                        .fill(AppleIntelligenceAvailability.isAvailable ? Color.green : Color.secondary.opacity(0.25))
                        .frame(width: 7, height: 7)
                }
                .padding(.vertical, 4)

                Divider().padding(.leading, 44)

                // System Dictionary toggle
                HStack(spacing: 12) {
                    Image(systemName: "character.book.closed.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.blue)
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("System Dictionary")
                            .font(.subheadline.weight(.medium))
                        Text("Show system dictionary definitions in dictionary mode")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: $viewModel.useSystemDictionary)
                        .labelsHidden()
                }
                .padding(.vertical, 4)

                Divider().padding(.leading, 44)

                // Local capabilities summary
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                            .frame(width: 28)
                        Text("Local Text-to-Speech (TTS)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                            .frame(width: 28)
                        Text("Apple Translation (no API Key needed)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                            .frame(width: 28)
                        Text("System Dictionary Lookup")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - API Keys Card

    private var apiKeysCard: some View {
        SettingsCard(
            icon: "key.fill",
            title: "API Keys (Optional)",
            subtitle: "Configure to enable cloud AI analysis",
            iconColor: Color(red: 0.95, green: 0.65, blue: 0.10)
        ) {
            VStack(spacing: 0) {
                APIKeyRow(
                    provider: "OpenAI",
                    icon: "circle.fill",
                    iconColor: Color(red: 0.09, green: 0.65, blue: 0.44),
                    placeholder: "sk-...",
                    text: $viewModel.openaiAPIKey
                )
                Divider().padding(.leading, 44)
                APIKeyRow(
                    provider: "Claude",
                    icon: "sparkle",
                    iconColor: Color(red: 0.78, green: 0.47, blue: 0.22),
                    placeholder: "sk-ant-...",
                    text: $viewModel.claudeAPIKey
                )
                Divider().padding(.leading, 44)
                APIKeyRow(
                    provider: "Gemini",
                    icon: "wand.and.stars",
                    iconColor: Color(red: 0.26, green: 0.52, blue: 0.96),
                    placeholder: "AIza...",
                    text: $viewModel.geminiAPIKey
                )
            }
        }
    }

    // MARK: - Provider Card

    private var providerCard: some View {
        SettingsCard(
            icon: "cpu.fill",
            title: "Service Providers",
            subtitle: "Choose AI and voice engines",
            iconColor: Color(red: 0.55, green: 0.35, blue: 0.90)
        ) {
            VStack(spacing: 0) {
                ProviderPickerRow(
                    label: "LLM Engine",
                    icon: "brain.head.profile",
                    iconColor: Color(red: 0.55, green: 0.35, blue: 0.90)
                ) {
                    Picker("", selection: $viewModel.selectedLLMProvider) {
                        ForEach(LLMProvider.allCases) { provider in
                            Text(provider.displayName).tag(provider)
                        }
                    }
                }
                Divider().padding(.leading, 44)
                ProviderPickerRow(
                    label: "Voice Synthesis",
                    icon: "waveform",
                    iconColor: Color(red: 0.20, green: 0.60, blue: 0.90)
                ) {
                    Picker("", selection: $viewModel.selectedTTSProvider) {
                        ForEach(TTSProvider.allCases) { provider in
                            Text(provider.displayName).tag(provider)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Connection Test Card

    private var connectionTestCard: some View {
        SettingsCard(
            icon: "antenna.radiowaves.left.and.right",
            title: "Connection Test",
            subtitle: "Verify current LLM service availability",
            iconColor: Color(red: 0.18, green: 0.72, blue: 0.45)
        ) {
            VStack(spacing: 12) {
                Button {
                    Task { await viewModel.testConnection(settings: settings) }
                } label: {
                    HStack(spacing: 8) {
                        if viewModel.isTesting {
                            ProgressView()
                                .controlSize(.small)
                                .tint(.white)
                        } else {
                            Image(systemName: "bolt.fill")
                        }
                        Text(viewModel.isTesting ? LocalizedStringKey("Testing...") : LocalizedStringKey("Test Connection"))
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        viewModel.isTesting
                            ? Color.secondary.opacity(0.3)
                            : Color(red: 0.18, green: 0.72, blue: 0.45)
                    )
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(viewModel.isTesting)
                .buttonStyle(.plain)

                if viewModel.showTestResult {
                    TestResultBanner(
                        message: viewModel.testResultMessage,
                        isSuccess: viewModel.testResultIsSuccess
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.spring(duration: 0.35), value: viewModel.showTestResult)
        }
    }
}

// MARK: - SettingsCard

private struct SettingsCard<Content: View>: View {
    let icon: String
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let iconColor: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(iconColor)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            Divider()
                .padding(.horizontal, 16)

            // Content
            VStack(alignment: .leading, spacing: 0) {
                content()
            }
            .padding(16)
        }
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}

// MARK: - APIKeyRow

private struct APIKeyRow: View {
    let provider: String
    let icon: String
    let iconColor: Color
    let placeholder: String
    @Binding var text: String

    @State private var isRevealed = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(provider)
                    .font(.subheadline.weight(.medium))
                if isRevealed {
                    TextField(placeholder, text: $text)
                        .font(.caption.monospaced())
                        .foregroundStyle(.primary)
                        .autocorrectionDisabled()
                } else {
                    SecureField(placeholder, text: $text)
                        .font(.caption.monospaced())
                }
            }

            Spacer()

            Button {
                isRevealed.toggle()
            } label: {
                Image(systemName: isRevealed ? "eye.slash" : "eye")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)

            // Filled indicator dot
            Circle()
                .fill(text.isEmpty ? Color.secondary.opacity(0.25) : Color.green)
                .frame(width: 7, height: 7)
        }
        .padding(.vertical, 10)
    }
}

// MARK: - ProviderPickerRow

private struct ProviderPickerRow<PickerContent: View>: View {
    let label: LocalizedStringKey
    let icon: String
    let iconColor: Color
    @ViewBuilder let picker: () -> PickerContent

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 28)
            Text(label)
                .font(.subheadline)
            Spacer()
            picker()
                .labelsHidden()
        }
        .padding(.vertical, 6)
    }
}

// MARK: - TestResultBanner

private struct TestResultBanner: View {
    let message: String
    let isSuccess: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(isSuccess ? Color.green : Color.red)
                .font(.body)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(isSuccess ? Color.green : Color.red)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .padding(12)
        .background((isSuccess ? Color.green : Color.red).opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(
                    (isSuccess ? Color.green : Color.red).opacity(0.25),
                    lineWidth: 1
                )
        )
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: Settings.self, inMemory: true)
}
