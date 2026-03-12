import SwiftUI

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
            .accessibilityLabel("\(language.displayName)语言")
            .accessibilityAddTraits(.isStaticText)
    }
}

// MARK: - LoadingView

/// Centered spinner with an optional message, used while AI is working.
struct LoadingView: View {
    var message: String = "AI 分析中..."

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
                    Text("出错了")
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
                    Button("重试") { retry() }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                }

                if rawResponse != nil {
                    Button(showRaw ? "隐藏原始响应" : "查看原始响应") {
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
    let title: String
    var icon: String? = nil
    var accentColor: Color = .secondary
    @State private var isExpanded: Bool
    @ViewBuilder let content: () -> Content

    init(
        title: String,
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
    let title: String
    var subtitle: String = ""

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 52))
                .foregroundStyle(.tertiary)
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
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
            Text("无网络连接")
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
                Text("配置 API Key 可启用云端 AI — 前往设置")
                    .font(.subheadline.bold())
                Spacer()
                Image(systemName: "chevron.right")
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
        .accessibilityLabel("配置 API Key 以启用云端 AI 功能")
        .accessibilityHint("前往设置页面填写 API Key")
        .accessibilityAddTraits(.isButton)
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
                message: "API Key 未设置，请在设置中填写对应的 API Key。",
                rawResponse: "{\"error\": \"unauthorized\"}",
                retryAction: {}
            )
            CollapsibleSection(title: "语法分析", icon: "text.alignleft", accentColor: .blue) {
                Text("这里是折叠内容")
            }
            EmptyStateView(systemImage: "text.magnifyingglass",
                          title: "输入单词开始查词",
                          subtitle: "支持中文、英文、日语、韩语")
        }
        .padding()
    }
}
