import SwiftUI
import SwiftData

@main
struct PolyGlotApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Settings.self, QueryHistory.self])
    }
}
