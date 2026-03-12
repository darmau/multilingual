import SwiftUI
import SwiftData

// MARK: - Environment Keys

/// Environment key for per-query TTS provider override, set by each feature view.
private struct QueryTTSProviderKey: EnvironmentKey {
    static let defaultValue: TTSProvider? = nil
}

extension EnvironmentValues {
    /// Per-query TTS provider override injected by feature views.
    /// SpeakButton reads this automatically so sub-components don't need
    /// explicit ttsProvider parameters.
    var queryTTSProvider: TTSProvider? {
        get { self[QueryTTSProviderKey.self] }
        set { self[QueryTTSProviderKey.self] = newValue }
    }
}

// MARK: - LanguageBadge

/// A pill-shaped label showing a language name with its identity color.
struct LanguageBadge: View {
    let language: SupportedLanguage
    var style: BadgeStyle = .filled

    enum BadgeStyle { case filled, outline }

    var body: some View {
        let color = Color.language(language)
        Text(language.displayName)
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(style == .filled ? color.opacity(0.15) : .clear)
            .foregroundStyle(color)
            .clipShape(Capsule())
            .overlay(
                Capsule().strokeBorder(
                    style == .outline ? color.opacity(0.5) : .clear,
                    lineWidth: 1
                )
            )
            .accessibilityLabel(Text("\(language.displayName) language"))
            .accessibilityAddTraits(.isStaticText)
    }
}

// MARK: - LoadingView

/// Centered spinner with an optional message, used while AI is working.
struct LoadingView: View {
    var message: LocalizedStringKey = "AI analyzing..."

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.4)
                .tint(.secondary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - ErrorBanner

/// Inline error banner with a retry action.
/// When `isAPIKeyError` is true, an extra tappable prompt to open Settings is shown.
struct ErrorBanner: View {
    let message: String
    var rawResponse: String? = nil
    var retryAction: (() -> Void)? = nil
    /// Set to true when the error requires the user to go set up an API key.
    var isAPIKeyError: Bool = false

    @State private var showRaw = false
    @Environment(\.navigateToSettings) private var navigateToSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Error occurred")
                        .font(.headline)
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
            }

            if isAPIKeyError {
                APIKeyMissingBanner(navigateToSettings: navigateToSettings)
            }

            HStack(spacing: 10) {
                if let retry = retryAction {
                    Button("Retry") { retry() }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                }

                if rawResponse != nil {
                    Button(showRaw ? "Hide Raw Response" : "View Raw Response") {
                        showRaw.toggle()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }

            if showRaw, let raw = rawResponse {
                ScrollView {
                    Text(raw)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                }
                .frame(maxHeight: 180)
                .background(.quaternary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.orange.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(.orange.opacity(0.25), lineWidth: 1)
        )
    }
}

// MARK: - CollapsibleSection

/// A DisclosureGroup-based collapsible section with a styled header.
struct CollapsibleSection<Content: View>: View {
    let title: LocalizedStringKey
    var icon: String? = nil
    var accentColor: Color = .secondary
    @State private var isExpanded: Bool
    @ViewBuilder let content: () -> Content

    init(
        title: LocalizedStringKey,
        icon: String? = nil,
        accentColor: Color = .secondary,
        initiallyExpanded: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.accentColor = accentColor
        self._isExpanded = State(initialValue: initiallyExpanded)
        self.content = content
    }

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 10) {
                content()
            }
            .padding(.top, 8)
        } label: {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                        .font(.subheadline)
                        .foregroundStyle(accentColor)
                }
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(accentColor)
            }
        }
        .tint(accentColor)
    }
}

// MARK: - EmptyStateView

/// Generic empty state with icon, title, and subtitle.
struct EmptyStateView: View {
    let systemImage: String
    let title: LocalizedStringKey
    var subtitle: LocalizedStringKey = ""

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 52))
                .foregroundStyle(.tertiary)
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - OfflineBanner

/// Thin banner shown at the top of the screen when the device has no network.
struct OfflineBanner: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
                .font(.caption.bold())
            Text("No Network Connection")
                .font(.caption.bold())
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.9))
        .foregroundStyle(.white)
    }
}

// MARK: - APIKeyMissingBanner

/// Banner shown when cloud AI features are unavailable due to missing API key.
/// Tapping it navigates the user to the Settings tab. Uses a non-alarming purple style
/// since the app can still function with local capabilities.
struct APIKeyMissingBanner: View {
    var navigateToSettings: () -> Void

    var body: some View {
        Button(action: navigateToSettings) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.subheadline)
                Text("Configure API Key to enable cloud AI — Go to Settings")
                    .font(.subheadline.bold())
                Spacer()
                Image(systemName: "chevron.forward")
                    .font(.caption)
            }
            .padding(12)
            .background(Color.purple.opacity(0.08))
            .foregroundStyle(Color.purple)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.purple.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Configure API Key to enable cloud AI")
        .accessibilityHint("Go to Settings to enter API Key")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - ModelSelectorBar

/// A compact bar for selecting LLM model and TTS voice on a per-query basis.
/// Place above the action button in Dictionary, Sentence, Translation and Question views.
struct ModelSelectorBar: View {
    let settings: Settings
    @Binding var selectedLLM: LLMProvider?
    @Binding var selectedTTS: TTSProvider?

    private var effectiveLLM: LLMProvider { selectedLLM ?? settings.selectedLLMProvider }
    private var effectiveTTS: TTSProvider { selectedTTS ?? settings.selectedTTSProvider }

    var body: some View {
        HStack(spacing: 4) {
            // LLM model picker
            Menu {
                ForEach(LLMProvider.allCases) { provider in
                    Button {
                        selectedLLM = provider
                    } label: {
                        if selectedLLM == provider {
                            Label(provider.displayName, systemImage: "checkmark")
                        } else {
                            Text(provider.displayName)
                        }
                    }
                }
                if selectedLLM != nil {
                    Divider()
                    Button {
                        selectedLLM = nil
                    } label: {
                        Label(String(localized: "Default (\(settings.selectedLLMProvider.displayName))"), systemImage: "arrow.counterclockwise")
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "cpu")
                    Text(effectiveLLM.displayName)
                    if selectedLLM != nil {
                        Image(systemName: "pencil")
                            .font(.caption2)
                    }
                }
                .font(.caption)
                .foregroundStyle(selectedLLM != nil ? .primary : .secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(selectedLLM != nil ? Color.accentColor.opacity(0.12) : Color.secondary.opacity(0.1))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Select AI model: \(effectiveLLM.displayName)")

            // TTS voice picker
            Menu {
                ForEach(TTSProvider.allCases) { provider in
                    Button {
                        selectedTTS = provider
                    } label: {
                        if selectedTTS == provider {
                            Label(provider.displayName, systemImage: "checkmark")
                        } else {
                            Text(provider.displayName)
                        }
                    }
                }
                if selectedTTS != nil {
                    Divider()
                    Button {
                        selectedTTS = nil
                    } label: {
                        Label(String(localized: "Default (\(settings.selectedTTSProvider.displayName))"), systemImage: "arrow.counterclockwise")
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "speaker.wave.2")
                    Text(effectiveTTS.displayName)
                    if selectedTTS != nil {
                        Image(systemName: "pencil")
                            .font(.caption2)
                    }
                }
                .font(.caption)
                .foregroundStyle(selectedTTS != nil ? .primary : .secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(selectedTTS != nil ? Color.accentColor.opacity(0.12) : Color.secondary.opacity(0.1))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Select voice: \(effectiveTTS.displayName)")

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

// MARK: - Previews

#Preview("Components") {
    ScrollView {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                ForEach(SupportedLanguage.allCases) { lang in
                    LanguageBadge(language: lang)
                }
            }
            HStack {
                ForEach(SupportedLanguage.allCases) { lang in
                    LanguageBadge(language: lang, style: .outline)
                }
            }
            ErrorBanner(
                message: "API Key not set.",
                rawResponse: "{\"error\": \"unauthorized\"}",
                retryAction: {}
            )
            CollapsibleSection(title: "Grammar Analysis", icon: "text.alignleft", accentColor: .blue) {
                Text("Collapsible content here")
            }
            EmptyStateView(systemImage: "text.magnifyingglass",
                          title: "Enter a word to look up",
                          subtitle: "Supports Chinese, English, Japanese, Korean")
        }
        .padding()
    }
}
