import SwiftUI
import SwiftData

struct SpeakButton: View {
    let text: String
    let language: SupportedLanguage

    @State private var ttsManager = TTSManager()
    @Query private var settingsList: [Settings]

    private var settings: Settings {
        settingsList.first ?? Settings()
    }

    var body: some View {
        Button {
            if ttsManager.isSpeaking {
                ttsManager.stop()
            } else {
                ttsManager.speak(text: text, language: language, settings: settings)
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
        .buttonStyle(.plain)
        .accessibilityLabel(ttsManager.isSpeaking ? "Stop" : "Speak")
        .accessibilityHint(ttsManager.isSpeaking ? "Tap to stop" : "Tap to read this text aloud")
    }
}

#Preview {
    SpeakButton(text: "Hello, world!", language: .english)
        .modelContainer(for: Settings.self, inMemory: true)
}
