import SwiftUI
import SwiftData

@main
struct PolyGlotApp: App {
    let modelContainer: ModelContainer

    init() {
        let schema = Schema([Settings.self, QueryHistory.self])
        let config = ModelConfiguration(schema: schema)
        do {
            modelContainer = try ModelContainer(for: schema, configurations: config)
        } catch {
            // Schema migration failed — delete the store and recreate from scratch.
            let storeURL = config.url
            try? FileManager.default.removeItem(at: storeURL)
            try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("shm"))
            try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("wal"))
            do {
                modelContainer = try ModelContainer(for: schema, configurations: config)
            } catch {
                fatalError("Failed to create ModelContainer: \(error)")
            }
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

        #if os(macOS)
        SwiftUI.Settings {
            SettingsView()
                .modelContainer(modelContainer)
                .frame(minWidth: 500, minHeight: 500)
        }
        #endif
    }
}

/// Root view that applies the user's chosen interface language.
///
/// Setting only `.locale` is the correct Apple-recommended approach: SwiftUI
/// automatically derives the layout direction from the locale, so leading/trailing
/// semantics, text alignment, and SF Symbol mirroring all work correctly without
/// any manual `.layoutDirection` override.
private struct RootView: View {
    @Query private var settingsList: [Settings]

    private var interfaceLanguage: InterfaceLanguage {
        settingsList.first?.interfaceLanguage ?? .system
    }

    var body: some View {
        if let locale = interfaceLanguage.locale {
            ContentView()
                .environment(\.locale, locale)
        } else {
            ContentView()
        }
    }
}
