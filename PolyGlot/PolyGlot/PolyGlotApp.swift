import SwiftUI
import SwiftData

@main
struct PolyGlotApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [Settings.self, QueryHistory.self])
    }
}

/// Root view that applies the user's chosen interface language (locale + layout direction)
/// before rendering the main content.
private struct RootView: View {
    @Query private var settingsList: [Settings]

    private var interfaceLanguage: InterfaceLanguage {
        settingsList.first?.interfaceLanguage ?? .system
    }

    var body: some View {
        Group {
            if let locale = interfaceLanguage.locale {
                ContentView()
                    .environment(\.locale, locale)
                    .environment(\.layoutDirection, interfaceLanguage.isRTL ? .rightToLeft : .leftToRight)
            } else {
                ContentView()
            }
        }
    }
}
