import Foundation

// MARK: - Segment Model

/// A segment of Japanese text, either plain or annotated with furigana.
enum FuriganaSegment: Equatable {
    case plain(String)
    case annotated(kanji: String, reading: String)

    /// The display text (kanji or plain).
    var text: String {
        switch self {
        case .plain(let s): return s
        case .annotated(let k, _): return k
        }
    }
}

// MARK: - Parser

/// Parses strings containing `{漢字|かな}` furigana markup into [FuriganaSegment].
///
/// Input example:  "{食|た}べ{物|もの}が{好|す}き"
/// Output: [.annotated("食","た"), .plain("べ"), .annotated("物","もの"), .plain("が"), .annotated("好","す"), .plain("き")]
enum FuriganaParser {

    static func parse(_ text: String) -> [FuriganaSegment] {
        guard text.contains("{") else {
            return [.plain(text)]
        }

        var segments: [FuriganaSegment] = []
        var remaining = text[text.startIndex...]

        while !remaining.isEmpty {
            if let openBrace = remaining.firstIndex(of: "{") {
                // Collect plain text before the brace
                let plain = String(remaining[remaining.startIndex..<openBrace])
                if !plain.isEmpty {
                    segments.append(.plain(plain))
                }

                // Move past '{'
                let afterOpen = remaining.index(after: openBrace)
                guard afterOpen < remaining.endIndex else { break }
                remaining = remaining[afterOpen...]

                // Find '|'
                guard let pipe = remaining.firstIndex(of: "|") else {
                    // Malformed — treat rest as plain
                    segments.append(.plain(String(remaining)))
                    break
                }
                let kanji = String(remaining[remaining.startIndex..<pipe])

                // Move past '|'
                let afterPipe = remaining.index(after: pipe)
                guard afterPipe < remaining.endIndex else { break }
                remaining = remaining[afterPipe...]

                // Find '}'
                guard let closeBrace = remaining.firstIndex(of: "}") else {
                    // Malformed — treat rest as plain
                    segments.append(.plain(kanji + String(remaining)))
                    break
                }
                let reading = String(remaining[remaining.startIndex..<closeBrace])

                if !kanji.isEmpty {
                    segments.append(.annotated(kanji: kanji, reading: reading))
                }

                // Move past '}'
                let afterClose = remaining.index(after: closeBrace)
                remaining = remaining[afterClose...]

            } else {
                // No more braces — rest is plain text
                segments.append(.plain(String(remaining)))
                break
            }
        }

        return segments.isEmpty ? [.plain(text)] : segments
    }

    /// Returns the plain (non-annotated) string for use with TTS.
    static func plainText(from segments: [FuriganaSegment]) -> String {
        segments.map { segment in
            switch segment {
            case .plain(let s): return s
            case .annotated(let k, _): return k
            }
        }.joined()
    }
}
