import SwiftUI

// MARK: - Language Locale Modifier

/// Applies the correct CJK glyph variant locale for a given language.
/// Only has an effect for .chinese and .japanese; other languages are left alone.
struct LanguageLocaleModifier: ViewModifier {
    let language: SupportedLanguage

    func body(content: Content) -> some View {
        content.environment(\.locale, language.locale)
    }
}

// MARK: - Language Identity Colors

extension Color {
    /// Fixed language colors — consistent across Light and Dark mode.
    static let languageEnglish    = Color(red: 0.20, green: 0.47, blue: 0.95)   // blue
    static let languageChinese    = Color(red: 0.95, green: 0.38, blue: 0.20)   // orange-red
    static let languageJapanese   = Color(red: 0.62, green: 0.25, blue: 0.83)   // purple
    static let languageKorean     = Color(red: 0.18, green: 0.72, blue: 0.45)   // green
    static let languageFrench     = Color(red: 0.15, green: 0.40, blue: 0.75)   // navy blue
    static let languageSpanish    = Color(red: 0.90, green: 0.55, blue: 0.10)   // amber
    static let languageArabic     = Color(red: 0.10, green: 0.60, blue: 0.55)   // teal
    static let languageGerman     = Color(red: 0.70, green: 0.20, blue: 0.20)   // dark red
    static let languagePortuguese = Color(red: 0.20, green: 0.65, blue: 0.35)   // forest green

    static func language(_ lang: SupportedLanguage) -> Color {
        switch lang {
        case .english:    return .languageEnglish
        case .chinese:    return .languageChinese
        case .japanese:   return .languageJapanese
        case .korean:     return .languageKorean
        case .french:     return .languageFrench
        case .spanish:    return .languageSpanish
        case .arabic:     return .languageArabic
        case .german:     return .languageGerman
        case .portuguese: return .languagePortuguese
        }
    }
}

// MARK: - Card Background Helper

extension ShapeStyle where Self == Color {
    // Used as .cardBackground on views — adapts to color scheme automatically
    // via the system .background.secondary material.
}

// MARK: - View Modifier: Card Style

struct CardStyle: ViewModifier {
    var accentColor: Color = .clear
    var cornerRadius: CGFloat = 12

    func body(content: Content) -> some View {
        content
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background.secondary)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(accentColor.opacity(0.25), lineWidth: accentColor == .clear ? 0 : 1)
            )
    }
}

extension View {
    func cardStyle(accentColor: Color = .clear, cornerRadius: CGFloat = 12) -> some View {
        modifier(CardStyle(accentColor: accentColor, cornerRadius: cornerRadius))
    }

    /// Forces all descendant Text views to use Simplified Chinese glyph variants.
    /// Apply to any container that displays Chinese text to prevent the system
    /// from accidentally using Japanese CJK glyph shapes.
    func chineseLocale() -> some View {
        environment(\.locale, Locale(identifier: "zh-Hans"))
    }

    /// Forces all descendant Text views to use Japanese glyph variants.
    func japaneseLocale() -> some View {
        environment(\.locale, Locale(identifier: "ja-JP"))
    }
}
