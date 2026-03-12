import SwiftUI
import SwiftData

struct SpeakButton: View {
    let text: String
    let language: SupportedLanguage

    @State private var ttsManager = TTSManager()
    @State private var errorMessage: String?
    @Query private var settingsList: [Settings]

    private var settings: Settings {
        settingsList.first ?? Settings()
    }

    var body: some View {
        if language != .chinese {
            Button {
                Task {
                    await speak()
                }
            } label: {
                Group {
                    if ttsManager.isSpeaking {
                        Image(systemName: "speaker.wave.3.fill")
                            .symbolEffect(.variableColor.iterative)
                    } else {
                        Image(systemName: "speaker.wave.2")
                    }
                }
                .font(.body)
            }
            .disabled(ttsManager.isSpeaking)
            .accessibilityLabel("朗读")
            .alert("朗读失败", isPresented: .init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("确定", role: .cancel) { }
            } message: {
                if let errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }

    private func speak() async {
        errorMessage = nil
        do {
            try await ttsManager.speak(text: text, language: language, settings: settings)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    SpeakButton(text: "Hello, world!", language: .english)
        .modelContainer(for: Settings.self, inMemory: true)
}
