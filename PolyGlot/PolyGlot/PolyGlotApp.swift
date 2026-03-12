import SwiftUI
import SwiftData

@main
struct PolyGlotApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(for: Settings.self, QueryHistory.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        // Seed a single Settings object if none exists, so @Query is never empty.
        let context = modelContainer.mainContext
        let count = (try? context.fetchCount(FetchDescriptor<Settings>())) ?? 0
        if count == 0 {
            context.insert(Settings())
            try? context.save()
        } else if count > 1 {
            // Clean up duplicates: keep the first, delete the rest.
            if let all = try? context.fetch(FetchDescriptor<Settings>()) {
                for extra in all.dropFirst() {
                    context.delete(extra)
                }
                try? context.save()
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(modelContainer)
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
