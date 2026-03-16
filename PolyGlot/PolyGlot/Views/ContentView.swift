import SwiftUI
import SwiftData

// MARK: - App Mode

enum AppTab: String, CaseIterable, Identifiable {
    case dictionary
    case sentence
    case translation
    case question

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .dictionary:   return "Dictionary"
        case .sentence:     return "Sentence Analysis"
        case .translation:  return "Translation"
        case .question:     return "Question"
        }
    }

    var icon: String {
        switch self {
        case .dictionary:   return "book"
        case .sentence:     return "text.magnifyingglass"
        case .translation:  return "arrow.left.arrow.right"
        case .question:     return "questionmark.bubble"
        }
    }
}

// MARK: - ContentView

struct ContentView: View {
    @State private var selectedTab: AppTab? = .dictionary
    @State private var showSettings = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Query private var settingsList: [Settings]

    /// Shared NetworkMonitor — observed for the offline banner.
    private let network = NetworkMonitor.shared

    private var locale: Locale? {
        settingsList.first?.interfaceLanguage.locale
    }

    var body: some View {
        ZStack(alignment: .top) {
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
        .environment(\.navigateToSettings, { showSettings = true })
        #if os(iOS)
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { showSettings = false }
                        }
                    }
            }
        }
        #endif
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
            #if os(iOS)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    settingsButton
                }
            }
            #endif
        } detail: {
            tabContent(selectedTab ?? .dictionary)
        }
    }

    // MARK: - Settings Button (iOS only)

    #if os(iOS)
    private var settingsButton: some View {
        Button {
            showSettings = true
        } label: {
            Image(systemName: "gear")
        }
        .accessibilityLabel("Settings")
    }
    #endif

    // MARK: - Shared Content Router

    @ViewBuilder
    private func tabContent(_ tab: AppTab) -> some View {
        let content: AnyView = switch tab {
        case .dictionary:   AnyView(DictionaryView())
        case .sentence:     AnyView(SentenceView())
        case .translation:  AnyView(TranslationView())
        case .question:     AnyView(QuestionView())
        }
        if let locale {
            content.environment(\.locale, locale)
        } else {
            content
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
