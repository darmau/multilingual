import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DictionaryView()
                .tabItem {
                    Label("词典", systemImage: "book")
                }

            SentenceView()
                .tabItem {
                    Label("句子分析", systemImage: "text.magnifyingglass")
                }

            TranslationView()
                .tabItem {
                    Label("翻译", systemImage: "arrow.left.arrow.right")
                }

            QuestionView()
                .tabItem {
                    Label("提问", systemImage: "questionmark.bubble")
                }

            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gear")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Settings.self, inMemory: true)
}
