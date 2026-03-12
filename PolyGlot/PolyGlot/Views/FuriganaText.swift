import SwiftUI
import SwiftData

// MARK: - FuriganaText

/// Renders Japanese text with furigana (ruby) annotations above kanji.
///
/// Text must be in the `{漢字|かな}` format. Segments without annotation are
/// rendered as plain text. The `@Query`-based settings lookup is used to read
/// the user's Japanese proficiency level and suppress furigana for kanji
/// the user is expected to know.
///
/// Example:
///   FuriganaText("{食|た}べ{物|もの}が{好|す}き", font: .body)
struct FuriganaText: View {
    let rawText: String
    var font: Font = .body
    var rubyFont: Font = .system(size: 9)
    var color: Color = .primary

    init(_ rawText: String, font: Font = .body, rubyFont: Font = .system(size: 9), color: Color = .primary) {
        self.rawText = rawText
        self.font = font
        self.rubyFont = rubyFont
        self.color = color
    }

    @Query private var settingsList: [Settings]
    private var proficiency: JapaneseProficiency {
        settingsList.first?.japaneseFuriganaLevel ?? .beginner
    }

    var body: some View {
        let segments = FuriganaParser.parse(rawText)
        let filtered = applyProficiencyFilter(to: segments)
        FuriganaLayout(font: font, rubyFont: rubyFont, color: color, segments: filtered)
    }

    // MARK: - Proficiency Filter

    /// Strips readings from annotated segments whose kanji are already known
    /// at the user's proficiency level, converting them back to plain segments.
    private func applyProficiencyFilter(to segments: [FuriganaSegment]) -> [FuriganaSegment] {
        segments.map { segment in
            guard case .annotated(let kanji, let reading) = segment else { return segment }

            // Only suppress if every character in kanji is "known"
            let allKnown = kanji.unicodeScalars.allSatisfy { scalar in
                let ch = Character(scalar)
                // Only filter CJK kanji, not kana or other chars
                guard isKanji(ch) else { return true }
                return !JLPTKanjiSet.shared.needsFurigana(kanji: String(ch), proficiency: proficiency)
            }
            return allKnown ? .plain(kanji) : .annotated(kanji: kanji, reading: reading)
        }
    }

    private func isKanji(_ char: Character) -> Bool {
        guard let scalar = char.unicodeScalars.first else { return false }
        return (scalar.value >= 0x4E00 && scalar.value <= 0x9FFF)   // CJK Unified
            || (scalar.value >= 0x3400 && scalar.value <= 0x4DBF)   // CJK Extension A
    }
}

// MARK: - FuriganaLayout

/// A SwiftUI view that lays out furigana segments in a left-to-right,
/// wrapping flow. Each annotated segment stacks the reading above the kanji.
private struct FuriganaLayout: View {
    let font: Font
    let rubyFont: Font
    let color: Color
    let segments: [FuriganaSegment]

    var body: some View {
        // Use a wrapping flow layout to handle line breaks naturally.
        FuriganaFlowLayout(spacing: 0) {
            ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                switch segment {
                case .plain(let text):
                    Text(text)
                        .font(font)
                        .foregroundStyle(color)
                        .fixedSize()

                case .annotated(let kanji, let reading):
                    AnnotatedSegmentView(kanji: kanji, reading: reading,
                                        kanjiFont: font, rubyFont: rubyFont,
                                        color: color)
                }
            }
        }
    }
}

// MARK: - AnnotatedSegmentView

private struct AnnotatedSegmentView: View {
    let kanji: String
    let reading: String
    let kanjiFont: Font
    let rubyFont: Font
    let color: Color

    var body: some View {
        VStack(spacing: 0) {
            Text(reading)
                .font(rubyFont)
                .foregroundStyle(color.opacity(0.7))
                .lineLimit(1)
                .fixedSize()
            Text(kanji)
                .font(kanjiFont)
                .foregroundStyle(color)
                .fixedSize()
        }
        // Bottom-align with adjacent plain text
        .alignmentGuide(.firstTextBaseline) { d in d[.lastTextBaseline] }
    }
}

// MARK: - FuriganaFlowLayout (Custom Layout)

/// A flow layout that places views left-to-right, wrapping to a new line
/// when the available width is exhausted. Rows are bottom-baseline-aligned
/// so that annotated and plain text segments share the same text baseline.
private struct FuriganaFlowLayout: Layout {
    var spacing: CGFloat = 0

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let height = rows.map { $0.height }.reduce(0, +)
        let width = rows.map { $0.width }.max() ?? 0
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY

        for row in rows {
            var x = bounds.minX
            for item in row.items {
                // Align to bottom of row so ruby fits above without shifting baseline
                let subview = subviews[item.index]
                let size = subview.sizeThatFits(.unspecified)
                let yOffset = row.height - size.height
                subview.place(
                    at: CGPoint(x: x, y: y + yOffset),
                    anchor: .topLeading,
                    proposal: .unspecified
                )
                x += size.width + spacing
            }
            y += row.height
        }
    }

    // MARK: - Row Computation

    private struct RowItem {
        let index: Int
        let size: CGSize
    }

    private struct Row {
        var items: [RowItem]
        var width: CGFloat { items.map { $0.size.width }.reduce(0, +) }
        var height: CGFloat { items.map { $0.size.height }.max() ?? 0 }
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        let maxWidth = proposal.width ?? .infinity
        var rows: [Row] = []
        var currentRow = Row(items: [])
        var currentWidth: CGFloat = 0

        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            if currentWidth + size.width > maxWidth && !currentRow.items.isEmpty {
                rows.append(currentRow)
                currentRow = Row(items: [])
                currentWidth = 0
            }
            currentRow.items.append(RowItem(index: index, size: size))
            currentWidth += size.width + spacing
        }

        if !currentRow.items.isEmpty {
            rows.append(currentRow)
        }

        return rows
    }
}

// MARK: - Preview

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        FuriganaText("{食|た}べ{物|もの}が{大|だい}{好|す}きです。", font: .title3)
        FuriganaText("{日|に}{本|ほん}{語|ご}を{勉|べん}{強|きょう}しています。", font: .body)
        FuriganaText("ひらがなだけのテキスト", font: .body)
    }
    .padding()
    .modelContainer(for: Settings.self, inMemory: true)
}
