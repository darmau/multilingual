import SwiftUI
import SwiftData

struct SpeakButton: View {
    let text: String
    let language: SupportedLanguage
    /// Optional per-button TTS provider override. Overrides the view-level environment value.
    var ttsProvider: TTSProvider? = nil

    @State private var ttsManager = TTSManager()
    @Query private var settingsList: [Settings]
    @Environment(\.queryTTSProvider) private var environmentTTSProvider

    private var settings: Settings {
        settingsList.first ?? Settings()
    }

    /// Effective TTS provider: explicit param > environment > global settings (handled by TTSManager).
    private var effectiveTTSProvider: TTSProvider? {
        ttsProvider ?? environmentTTSProvider
    }

    var body: some View {
        if language != .chinese {
            Button {
                if ttsManager.isSpeaking {
                    ttsManager.stop()
                } else {
                    ttsManager.speak(text: text, language: language, settings: settings, overrideProvider: effectiveTTSProvider)
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
}

#Preview {
    SpeakButton(text: "Hello, world!", language: .english)
        .modelContainer(for: Settings.self, inMemory: true)
}
