import SwiftUI
import SwiftData

// MARK: - App Mode

enum AppTab: String, CaseIterable, Identifiable {
    case dictionary
    case sentence
    case translation
    case question
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dictionary:   return "词典"
        case .sentence:     return "句子分析"
        case .translation:  return "翻译"
        case .question:     return "提问"
        case .settings:     return "设置"
        }
    }

    var icon: String {
        switch self {
        case .dictionary:   return "book"
        case .sentence:     return "text.magnifyingglass"
        case .translation:  return "arrow.left.arrow.right"
        case .question:     return "questionmark.bubble"
        case .settings:     return "gear"
        }
    }
}

// MARK: - ContentView

struct ContentView: View {
    @State private var selectedTab: AppTab? = .dictionary
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// Shared NetworkMonitor — observed for the offline banner.
    private let network = NetworkMonitor.shared

    var body: some View {
        ZStack(alignment: .top) {
            // Main layout
            if horizontalSizeClass == .compact {
                compactLayout
            } else {
                regularLayout
            }

            // Offline banner overlaid at the very top
            if !network.isConnected {
                VStack {
                    OfflineBanner()
                    Spacer()
                }
                .ignoresSafeArea(edges: .horizontal)
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(100)
                .animation(.spring(duration: 0.3), value: network.isConnected)
            }
        }
        // Allow any child view to navigate to Settings for API key setup
        .environment(\.navigateToSettings, { selectedTab = .settings })
    }

    // MARK: - Compact (iPhone) — TabView

    private var compactLayout: some View {
        TabView(selection: $selectedTab) {
            ForEach(AppTab.allCases) { tab in
                tabContent(tab)
                    .tabItem { Label(tab.title, systemImage: tab.icon) }
                    .tag(tab as AppTab?)
            }
        }
    }

    // MARK: - Regular (iPad / Mac) — NavigationSplitView

    private var regularLayout: some View {
        NavigationSplitView {
            List(selection: $selectedTab) {
                ForEach(AppTab.allCases) { tab in
                    Label(tab.title, systemImage: tab.icon)
                        .tag(tab)
                }
            }
            .navigationTitle("PolyGlot")
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            tabContent(selectedTab ?? .dictionary)
        }
    }

    // MARK: - Shared Content Router

    @ViewBuilder
    private func tabContent(_ tab: AppTab) -> some View {
        switch tab {
        case .dictionary:   DictionaryView()
        case .sentence:     SentenceView()
        case .translation:  TranslationView()
        case .question:     QuestionView()
        case .settings:     SettingsView()
        }
    }
}

// MARK: - Environment Key: navigateToSettings

private struct NavigateToSettingsKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

extension EnvironmentValues {
    var navigateToSettings: () -> Void {
        get { self[NavigateToSettingsKey.self] }
        set { self[NavigateToSettingsKey.self] = newValue }
    }
}

#Preview("Compact") {
    ContentView()
        .environment(\.horizontalSizeClass, .compact)
        .modelContainer(for: [Settings.self, QueryHistory.self], inMemory: true)
}

#Preview("Regular") {
    ContentView()
        .environment(\.horizontalSizeClass, .regular)
        .modelContainer(for: [Settings.self, QueryHistory.self], inMemory: true)
}
