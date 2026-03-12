import SwiftUI
import SwiftData
#if canImport(UIKit)
import UIKit
#endif

struct DictionaryView: View {
    @State private var viewModel = DictionaryViewModel()
    @Query private var settingsList: [Settings]
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \QueryHistory.createdAt, order: .reverse) private var history: [QueryHistory]

    private var settings: Settings {
        settingsList.first ?? Settings()
    }

    private var dictionaryHistory: [QueryHistory] {
        history.filter { $0.mode == .dictionary }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                Divider()
                resultArea
            }
            .navigationTitle("词典")
            .onChange(of: viewModel.result?.inputWord) { _, newWord in
                guard let newWord, !newWord.isEmpty,
                      let lang = viewModel.effectiveLanguage else { return }
                let entry = QueryHistory(text: newWord, language: lang, mode: .dictionary)
                modelContext.insert(entry)
            }
            #if canImport(UIKit)
            .sheet(isPresented: $viewModel.showSystemDictionary) {
                if let term = viewModel.systemDictionaryResult?.term {
                    SystemDictionaryView(term: term)
                }
            }
            #endif
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                TextField("输入单词...", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                    .font(.title3)
                    .onChange(of: viewModel.searchText) {
                        viewModel.detectLanguage()
                    }
                    .onSubmit {
                        submitSearch()
                    }

                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.reset()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    submitSearch()
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.title3)
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return, modifiers: .command)
                .accessibilityLabel("查词")
                .accessibilityHint("查询单词的释义和语法信息")
                .disabled(viewModel.searchText.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isLoading)
            }
            .padding(.horizontal)
            .padding(.top, 12)

            // Language detection row
            HStack(spacing: 8) {
                if let detected = viewModel.detectedLanguage, viewModel.manualLanguage == nil {
                    Label("检测到: \(detected.displayName)", systemImage: "wand.and.stars")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Manual language picker
                Menu {
                    Button("自动检测") { viewModel.manualLanguage = nil }
                    Divider()
                    ForEach(SupportedLanguage.allCases) { lang in
                        Button(lang.displayName) { viewModel.manualLanguage = lang }
                    }
                } label: {
                    Label(
                        viewModel.manualLanguage.map { "输入: \($0.displayName)" } ?? "自动检测",
                        systemImage: "globe"
                    )
                    .font(.caption)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(.bar)
    }

    // MARK: - Result Area

    @ViewBuilder
    private var resultArea: some View {
        if viewModel.isLoading {
            LoadingView(message: "分析中...")
        } else if let result = viewModel.result {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    // System dictionary card (if available alongside LLM result)
                    if let dictResult = viewModel.systemDictionaryResult, dictResult.found {
                        systemDictionaryCard(dictResult)
                    }

                    // Header
                    inputWordHeader(result: result)

                    // Language sections in order
                    let inputLang = SupportedLanguage(rawValue: result.inputLanguage)

                    // Input language card first (most detailed)
                    if let lang = inputLang {
                        languageCard(for: lang, analyses: result.analyses)
                    }

                    // Other languages
                    let outputOrder = outputLanguages(for: inputLang)
                    ForEach(outputOrder, id: \.self) { lang in
                        languageCard(for: lang, analyses: result.analyses)
                    }
                }
                .padding()
            }
        } else if let dictResult = viewModel.systemDictionaryResult, dictResult.found {
            // No LLM result but system dictionary found the term
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    systemDictionaryCard(dictResult)

                    if let errorMessage = viewModel.errorMessage {
                        ErrorBanner(
                            message: errorMessage,
                            rawResponse: viewModel.rawResponse,
                            retryAction: { submitSearch() },
                            isAPIKeyError: viewModel.isAPIKeyError
                        )
                    }

                    // Hint to configure API key for richer analysis
                    if !settings.hasAnyAPIKey && !AppleIntelligenceAvailability.isAvailable {
                        apiKeyHintBanner
                    }
                }
                .padding()
            }
        } else if let errorMessage = viewModel.errorMessage {
            ScrollView {
                ErrorBanner(
                    message: errorMessage,
                    rawResponse: viewModel.rawResponse,
                    retryAction: { submitSearch() },
                    isAPIKeyError: viewModel.isAPIKeyError
                )
                .padding()
            }
        } else {
            emptyStateWithHistory
        }
    }

    // MARK: - System Dictionary Card

    private func systemDictionaryCard(_ result: AppleDictionaryService.DictionaryResult) -> some View {
        SystemDictionaryCard(result: result, onOpenSheet: {
            viewModel.showSystemDictionary = true
        })
    }

    /// Gentle hint shown when no API key is configured.
    private var apiKeyHintBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .foregroundStyle(.purple)
            VStack(alignment: .leading, spacing: 2) {
                Text("配置 API Key 可获取 AI 深度分析")
                    .font(.subheadline.bold())
                Text("包括多语言释义、词源、语法分析等")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background(.purple.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(.purple.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Input Word Header

    private func inputWordHeader(result: WordAnalysisResult) -> some View {
        let lang = SupportedLanguage(rawValue: result.inputLanguage)
        let phonetic: String? = {
            if let lang, lang == .english {
                return result.analyses.english?.phonetic
            }
            return nil
        }()

        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 10) {
                Text(result.inputWord)
                    .font(.system(size: 36, weight: .bold, design: .default))
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)

                if let lang {
                    SpeakButton(text: result.inputWord, language: lang)
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if let lang {
                    LanguageBadge(language: lang)
                }
            }

            if let phonetic, !phonetic.isEmpty {
                Text(phonetic)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .italic()
            }
        }
        .padding(.bottom, 4)
    }

    // MARK: - Language Card Builder

    @ViewBuilder
    private func languageCard(for language: SupportedLanguage, analyses: LanguageAnalyses) -> some View {
        switch language {
        case .english:
            if let analysis = analyses.english {
                EnglishCard(analysis: analysis)
            }
        case .chinese:
            if let analysis = analyses.chinese {
                ChineseCard(analysis: analysis)
            }
        case .japanese:
            if let analysis = analyses.japanese {
                JapaneseCard(analysis: analysis)
            }
        case .korean:
            if let analysis = analyses.korean {
                KoreanCard(analysis: analysis)
            }
        }
    }

    // MARK: - Empty State + History

    private var emptyStateWithHistory: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if dictionaryHistory.isEmpty {
                    EmptyStateView(
                        systemImage: "text.magnifyingglass",
                        title: "输入单词开始查词",
                        subtitle: "支持中文、英文、日语、韩语"
                    )
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("最近查询")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(dictionaryHistory.prefix(10)) { item in
                            Button {
                                viewModel.searchText = item.text
                                viewModel.manualLanguage = item.language
                                submitSearch()
                            } label: {
                                HStack {
                                    Image(systemName: "clock")
                                        .foregroundStyle(.secondary)
                                        .font(.caption)
                                    Text(item.text)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    LanguageBadge(language: item.language, style: .outline)
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(.plain)
                            Divider().padding(.leading)
                        }
                    }
                    .padding(.top)
                }
            }
        }
    }

    // MARK: - Helpers

    private func submitSearch() {
        let word = viewModel.searchText.trimmingCharacters(in: .whitespaces)
        guard !word.isEmpty else { return }
        viewModel.analyze(settings: settings)
    }

    private func outputLanguages(for input: SupportedLanguage?) -> [SupportedLanguage] {
        guard let input else { return SupportedLanguage.allCases }
        return SupportedLanguage.allCases.filter { $0 != input }
    }
}

// MARK: - English Card

private struct EnglishCard: View {
    let analysis: EnglishAnalysis

    var body: some View {
        LanguageSection(title: "English", color: .language(.english)) {
            // Definitions (phonetic is now in the top header)
            if !analysis.definitions.isEmpty {
                DefinitionList(definitions: analysis.definitions.map {
                    AnyDefinition(pos: $0.pos, meaning: $0.meaning, example: $0.example)
                }, language: .english)
            }

            // Etymology
            if let etymology = analysis.etymology, !etymology.isEmpty {
                MetaRow(label: "词源", value: etymology)
            }

            // Synonyms / Antonyms
            if let synonyms = analysis.synonyms, !synonyms.isEmpty {
                WordChipRow(label: "近义词", words: synonyms, language: .english)
            }
            if let antonyms = analysis.antonyms, !antonyms.isEmpty {
                WordChipRow(label: "反义词", words: antonyms, language: .english)
            }
        }
    }
}

// MARK: - Chinese Card

private struct ChineseCard: View {
    let analysis: ChineseAnalysis

    var body: some View {
        LanguageSection(title: "中文", color: .language(.chinese)) {
            if !analysis.definitions.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(analysis.definitions.enumerated()), id: \.offset) { i, def in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(i + 1)")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                                .frame(width: 18, height: 18)
                                .background(Color.language(.chinese))
                                .clipShape(Circle())
                            Text(def.meaning)
                                .font(.body)
                                .textSelection(.enabled)
                        }
                    }
                }
            }
        }
        .chineseLocale()
    }
}

// MARK: - Japanese Card

private struct JapaneseCard: View {
    let analysis: JapaneseAnalysis

    var body: some View {
        LanguageSection(title: "日本語", color: .language(.japanese)) {
            // Word + reading header
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    FuriganaText(analysis.word, font: .title2)
                        .fontWeight(.bold)
                    if let reading = analysis.reading, !reading.isEmpty {
                        Text(reading)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .japaneseLocale()
                    }
                }
                SpeakButton(
                    text: FuriganaParser.plainText(from: FuriganaParser.parse(analysis.word)),
                    language: .japanese
                )
                .font(.title3)
                .foregroundStyle(.secondary)
            }

            // Definitions
            if !analysis.definitions.isEmpty {
                DefinitionList(definitions: analysis.definitions.map {
                    AnyDefinition(pos: $0.pos, meaning: $0.meaning, example: $0.example,
                                  exampleReading: $0.exampleReading)
                }, language: .japanese)
            }

            // Etymology / Conjugation
            if let etymology = analysis.etymology, !etymology.isEmpty {
                MetaRow(label: "词源", value: etymology, valueLanguage: .japanese)
            }
            if let conjugation = analysis.conjugation, !conjugation.isEmpty {
                MetaRow(label: "变形", value: conjugation, valueLanguage: .japanese)
            }

            // Synonyms / Antonyms
            if let synonyms = analysis.synonyms, !synonyms.isEmpty {
                WordChipRow(label: "近义词", words: synonyms, language: .japanese)
            }
            if let antonyms = analysis.antonyms, !antonyms.isEmpty {
                WordChipRow(label: "反义词", words: antonyms, language: .japanese)
            }
        }
    }
}

// MARK: - Korean Card

private struct KoreanCard: View {
    let analysis: KoreanAnalysis

    var body: some View {
        LanguageSection(title: "한국어", color: .language(.korean)) {
            // Word + reading header
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(analysis.word)
                        .font(.title2.bold())
                    if let reading = analysis.reading, !reading.isEmpty {
                        Text(reading)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                SpeakButton(text: analysis.word, language: .korean)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            // Definitions
            if !analysis.definitions.isEmpty {
                DefinitionList(definitions: analysis.definitions.map {
                    AnyDefinition(pos: $0.pos, meaning: $0.meaning, example: $0.example)
                }, language: .korean)
            }

            // Etymology / Conjugation
            if let etymology = analysis.etymology, !etymology.isEmpty {
                MetaRow(label: "词源", value: etymology)
            }
            if let conjugation = analysis.conjugation, !conjugation.isEmpty {
                MetaRow(label: "变形", value: conjugation)
            }
        }
    }
}

// MARK: - Shared Sub-components

/// A type-erased definition entry used by DefinitionList.
private struct AnyDefinition {
    var pos: String?
    var meaning: String
    var example: String?
    var exampleReading: String? = nil
}

/// A card section per language with a colored left-border accent.
private struct LanguageSection<Content: View>: View {
    let title: String
    let color: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Language header bar
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: 3, height: 16)
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(color)
            }
            .padding(.bottom, 12)

            VStack(alignment: .leading, spacing: 14) {
                content()
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(color.opacity(0.18), lineWidth: 1)
        )
    }
}

/// Numbered definition list with pos pill, meaning, and example.
private struct DefinitionList: View {
    let definitions: [AnyDefinition]
    let language: SupportedLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(definitions.enumerated()), id: \.offset) { index, def in
                HStack(alignment: .top, spacing: 10) {
                    // Index number
                    Text("\(index + 1)")
                        .font(.caption2.bold())
                        .foregroundStyle(Color.language(language))
                        .frame(width: 18, height: 18)
                        .background(Color.language(language).opacity(0.12))
                        .clipShape(Circle())
                        .padding(.top, 2)

                    VStack(alignment: .leading, spacing: 6) {
                        // POS pill + meaning
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            if let pos = def.pos, !pos.isEmpty {
                                Text(pos)
                                    .font(.caption.bold())
                                    .foregroundStyle(Color.language(language))
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 2)
                                    .background(Color.language(language).opacity(0.10))
                                    .clipShape(Capsule())
                                    .modifier(LanguageLocaleModifier(language: language))
                            }
                            Text(def.meaning)
                                .font(.body)
                                .textSelection(.enabled)
                                .chineseLocale()
                        }

                        // Example sentence with accent bar
                        if let example = def.example, !example.isEmpty {
                            HStack(alignment: .top, spacing: 8) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.language(language).opacity(0.4))
                                    .frame(width: 2)
                                    .padding(.vertical, 1)

                                VStack(alignment: .leading, spacing: 2) {
                                    if language == .japanese {
                                        FuriganaText(example, font: .subheadline)
                                            .foregroundStyle(.secondary)
                                    } else {
                                        Text(example)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                            .textSelection(.enabled)
                                            .modifier(LanguageLocaleModifier(language: language))
                                    }
                                }

                                SpeakButton(
                                    text: language == .japanese
                                        ? FuriganaParser.plainText(from: FuriganaParser.parse(example))
                                        : example,
                                    language: language
                                )
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                            }
                            .padding(.leading, 2)
                        }
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(accessibilityLabel(for: def))
            }
        }
    }

    private func accessibilityLabel(for def: AnyDefinition) -> String {
        var parts: [String] = []
        if let pos = def.pos, !pos.isEmpty { parts.append(pos) }
        parts.append(def.meaning)
        if let ex = def.example, !ex.isEmpty {
            parts.append("例句: \(FuriganaParser.plainText(from: FuriganaParser.parse(ex)))")
        }
        return parts.joined(separator: "，")
    }
}

/// A label/value metadata row (etymology, conjugation, etc.).
private struct MetaRow: View {
    let label: String
    let value: String
    var valueLanguage: SupportedLanguage = .english

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .chineseLocale()
            Text(value)
                .font(.subheadline)
                .textSelection(.enabled)
                .modifier(LanguageLocaleModifier(language: valueLanguage))
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

/// Horizontally-scrolling chip row for synonyms / antonyms.
private struct WordChipRow: View {
    let label: String
    let words: [String]
    let language: SupportedLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .chineseLocale()
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(words, id: \.self) { word in
                        HStack(spacing: 4) {
                            Text(word)
                                .font(.subheadline)
                                .modifier(LanguageLocaleModifier(language: language))
                            SpeakButton(text: word, language: language)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.language(language).opacity(0.08))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.language(language).opacity(0.2), lineWidth: 1)
                        )
                    }
                }
            }
        }
    }
}

// MARK: - System Dictionary Card View

private struct SystemDictionaryCard: View {
    let result: AppleDictionaryService.DictionaryResult
    let onOpenSheet: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header bar
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.blue)
                    .frame(width: 3, height: 16)
                Image(systemName: "character.book.closed.fill")
                    .font(.subheadline)
                    .foregroundStyle(.blue)
                Text("系统词典")
                    .font(.subheadline.bold())
                    .foregroundStyle(.blue)
            }
            .padding(.bottom, 12)

            #if os(macOS)
            SystemDictionaryParsedView(raw: result.definition)
            #else
            if result.found {
                Button(action: onOpenSheet) {
                    HStack(spacing: 10) {
                        Image(systemName: "book.pages")
                            .font(.title3)
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("查看完整释义")
                                .font(.subheadline.bold())
                                .foregroundStyle(.primary)
                            Text("在系统词典中打开")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.bold())
                            .foregroundStyle(.tertiary)
                    }
                    .padding(12)
                    .background(Color.blue.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Color.blue.opacity(0.15), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            #endif
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.blue.opacity(0.18), lineWidth: 1)
        )
    }
}

// MARK: - macOS: Parsed System Dictionary View

#if os(macOS)
/// Detects the script of the raw text and dispatches to the correct language parser.
/// Dispatch rules based on observed DCSCopyTextDefinition output formats:
///   - Hiragana/Katakana present → Japanese  ("よみ【漢字】（品詞）①…")
///   - CJK + pinyin pattern (no kana) → Chinese  ("词 pīnyīn 词性 ①…")
///   - Otherwise → English  ("word | IPA | pos 1 def…")
///   - Korean: macOS system dictionary returns nil for Korean, never reaches here.
private struct SystemDictionaryParsedView: View {
    let raw: String

    private var isJapanese: Bool {
        raw.unicodeScalars.contains { $0.value >= 0x3040 && $0.value <= 0x30FF }
    }

    /// Chinese: contains CJK but no Hiragana/Katakana, and has a pinyin-like
    /// second token (ASCII letters with tone diacritics).
    private var isChinese: Bool {
        guard !isJapanese else { return false }
        let hasCJK = raw.unicodeScalars.contains { $0.value >= 0x4E00 && $0.value <= 0x9FFF }
        guard hasCJK else { return false }
        // Chinese entries start with "词 pīnyīn" — second whitespace-delimited token
        // contains Latin letters with or without tone marks (ā á ǎ à ē é etc.)
        let tokens = raw.trimmingCharacters(in: .whitespacesAndNewlines)
                        .components(separatedBy: .whitespaces)
                        .filter { !$0.isEmpty }
        guard tokens.count >= 2 else { return false }
        let second = tokens[1]
        return second.unicodeScalars.contains {
            // Basic Latin a-z
            ($0.value >= 0x61 && $0.value <= 0x7A) ||
            // Latin Extended-A (tone-marked vowels like ā á ǎ à ē é ě è etc.)
            ($0.value >= 0x0100 && $0.value <= 0x024F)
        }
    }

    /// Korean: contains Hangul syllables (U+AC00–U+D7A3) or Hangul Jamo (U+1100–U+11FF)
    private var isKorean: Bool {
        guard !isJapanese && !isChinese else { return false }
        return raw.unicodeScalars.contains {
            ($0.value >= 0xAC00 && $0.value <= 0xD7A3) ||
            ($0.value >= 0x1100 && $0.value <= 0x11FF)
        }
    }

    var body: some View {
        if isJapanese {
            SysDictJapaneseView(raw: raw)
        } else if isChinese {
            SysDictChineseView(raw: raw)
        } else if isKorean {
            SysDictKoreanView(raw: raw)
        } else {
            SysDictEnglishView(raw: raw)
        }
    }
}

// MARK: Shared entry model & rendering

private struct SysDictEntry: Identifiable {
    let id = UUID()
    var pos: String?
    var text: String
}

/// Renders a numbered list of entries with optional POS pills.
private struct SysDictEntryList: View {
    let entries: [SysDictEntry]
    var textLocale: SupportedLanguage = .english

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(entries.prefix(8).enumerated()), id: \.offset) { idx, entry in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(idx + 1)")
                        .font(.caption2.bold())
                        .foregroundStyle(.blue)
                        .frame(width: 18, height: 18)
                        .background(Color.blue.opacity(0.10))
                        .clipShape(Circle())
                        .padding(.top, 2)
                    VStack(alignment: .leading, spacing: 4) {
                        if let pos = entry.pos, !pos.isEmpty {
                            Text(pos)
                                .font(.caption.bold())
                                .foregroundStyle(.blue)
                                .padding(.horizontal, 7).padding(.vertical, 2)
                                .background(Color.blue.opacity(0.08))
                                .clipShape(Capsule())
                        }
                        Text(entry.text)
                            .font(.subheadline)
                            .textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)
                            .modifier(LanguageLocaleModifier(language: textLocale))
                    }
                }
            }
        }
    }
}

/// Small inset box for etymology / notes.
private struct SysDictMetaBox: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.caption.bold()).foregroundStyle(.secondary).chineseLocale()
            Text(value)
                .font(.caption).foregroundStyle(.secondary)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - English Parser
// Raw format: "word | ˈphonetic | pos (forms) 1 def. • example. 2 def. ORIGIN ..."

private struct SysDictEnglishView: View {
    let raw: String

    private let posKeywords = ["adjective", "adverb", "verb", "noun", "pronoun",
                               "preposition", "conjunction", "interjection", "determiner",
                               "exclamation", "predeterminer", "prefix", "suffix"]

    // "word | phonetic | ..." — extract part[1]
    var phonetic: String? {
        let parts = raw.components(separatedBy: " | ")
        guard parts.count >= 2 else { return nil }
        let candidate = parts[1].trimmingCharacters(in: .whitespaces)
        let hasIPA = candidate.unicodeScalars.contains {
            ($0.value > 0x0250 && $0.value < 0x02B0) ||
            ($0.value > 0x1D00 && $0.value < 0x1DBF) ||
            "ˈˌˑ·".unicodeScalars.contains($0)
        }
        return hasIPA ? candidate : nil
    }

    var origin: String? {
        guard let r = raw.range(of: "ORIGIN ") else { return nil }
        var s = String(raw[r.upperBound...])
        for m in ["\nDERIVATIVES", "\nPHRASES", "\nPHRASAL", "\nUSAGE"] {
            if let mr = s.range(of: m) { s = String(s[..<mr.lowerBound]) }
        }
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var entries: [SysDictEntry] {
        // Strip up to third " | " to get the definitions body
        var body = raw
        var pipeCount = 0
        var idx = body.startIndex
        while pipeCount < 2, let r = body.range(of: " | ", range: idx..<body.endIndex) {
            pipeCount += 1
            idx = r.upperBound
        }
        if pipeCount == 2 { body = String(body[idx...]) }

        // Remove appendix sections
        for m in ["DERIVATIVES", "ORIGIN", "PHRASES", "PHRASAL VERBS", "USAGE"] {
            if let r = body.range(of: m) { body = String(body[..<r.lowerBound]) }
        }
        body = body.trimmingCharacters(in: .whitespacesAndNewlines)

        // Split on " N " numbered markers
        var chunks: [String] = []
        if let regex = try? NSRegularExpression(pattern: "\\s+\\d+\\s+") {
            var last = body.startIndex
            for m in regex.matches(in: body, range: NSRange(body.startIndex..., in: body)) {
                let r = Range(m.range, in: body)!
                chunks.append(String(body[last..<r.lowerBound]))
                last = r.upperBound
            }
            chunks.append(String(body[last...]))
        } else {
            chunks = [body]
        }

        return chunks.compactMap { chunk -> SysDictEntry? in
            var s = chunk.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !s.isEmpty else { return nil }
            // Drop example after " | "
            if let pr = s.range(of: " | ") { s = String(s[..<pr.lowerBound]) }
            // Detect POS prefix
            var pos: String? = nil
            for kw in posKeywords {
                if s.lowercased().hasPrefix(kw) {
                    pos = kw
                    var rest = String(s.dropFirst(kw.count)).trimmingCharacters(in: .whitespaces)
                    // skip "(forms)" paren
                    if rest.hasPrefix("("), let cl = rest.firstIndex(of: ")") {
                        rest = String(rest[rest.index(after: cl)...]).trimmingCharacters(in: .whitespaces)
                    }
                    s = rest
                    break
                }
            }
            // Collapse bullet sub-senses into "; " and trim to first sentence
            s = s.replacingOccurrences(of: " • ", with: "; ")
            if let dr = s.range(of: "\\.\\s+[A-Z]", options: .regularExpression) {
                s = String(s[..<dr.lowerBound]) + "."
            }
            s = s.trimmingCharacters(in: .whitespacesAndNewlines)
            return s.isEmpty ? nil : SysDictEntry(pos: pos, text: s)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let phonetic {
                Text(phonetic).font(.title3).italic().foregroundStyle(.secondary)
            }
            if !entries.isEmpty {
                SysDictEntryList(entries: entries)
            }
            if let origin {
                SysDictMetaBox(label: "词源", value: origin)
            }
        }
    }
}

// MARK: - Japanese Parser
// Raw format: "よみ 番号【漢字・漢字】（品詞）① 定義。 ② 定義。"

private struct SysDictJapaneseView: View {
    let raw: String

    // Circle-number characters ①–⑳
    private static let circles: [Character] = Array("①②③④⑤⑥⑦⑧⑨⑩⑪⑫⑬⑭⑮⑯⑰⑱⑲⑳")

    var reading: String? {
        // Text before first 【 or （, stripping leading digit
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let end = s.range(of: "【")?.lowerBound ?? s.range(of: "（")?.lowerBound
        guard let e = end else { return nil }
        s = String(s[..<e])
        // Remove accent number like "2" or " 2 "
        s = s.replacingOccurrences(of: "\\s*\\d+\\s*", with: "", options: .regularExpression)
        s = s.trimmingCharacters(in: .whitespaces)
        return s.isEmpty ? nil : s
    }

    var headword: String? {
        guard let s = raw.range(of: "【"), let e = raw.range(of: "】") else { return nil }
        return String(raw[s.upperBound..<e.lowerBound])
    }

    var partOfSpeech: String? {
        // Find （）after 】 or after beginning
        let search = raw.range(of: "】").map { raw[$0.upperBound...] } ?? raw[...]
        guard let s = search.range(of: "（"), let e = search.range(of: "）"),
              s.lowerBound < e.lowerBound else { return nil }
        return String(search[s.upperBound..<e.lowerBound])
    }

    var entries: [SysDictEntry] {
        // Body after the first （）closing paren
        var body = raw
        if let close = body.range(of: "）") {
            body = String(body[close.upperBound...])
        }
        // Strip trailing metadata: 日葡, 可能xxx, etc.
        for m in ["日葡", "可能", "ORIGIN", "参照", "→"] {
            if let r = body.range(of: m) { body = String(body[..<r.lowerBound]) }
        }
        body = body.trimmingCharacters(in: .whitespacesAndNewlines)

        // Split on ①②③... circle numbers
        var parts: [String] = []
        var current = ""
        for ch in body {
            if Self.circles.contains(ch) {
                let t = current.trimmingCharacters(in: .whitespacesAndNewlines)
                if !t.isEmpty { parts.append(t) }
                current = ""
            } else {
                current.append(ch)
            }
        }
        let last = current.trimmingCharacters(in: .whitespacesAndNewlines)
        if !last.isEmpty { parts.append(last) }

        // If no circle numbers found, try splitting on 。
        if parts.isEmpty {
            parts = body.components(separatedBy: "。").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        }

        return parts.compactMap { part -> SysDictEntry? in
            var s = part
            // Strip quoted examples 「…」
            if let regex = try? NSRegularExpression(pattern: "「[^」]*」") {
                s = regex.stringByReplacingMatches(in: s, range: NSRange(s.startIndex..., in: s), withTemplate: "")
            }
            // Strip antonym reference ↔…
            if let r = s.range(of: "↔") { s = String(s[..<r.lowerBound]) }
            s = s.trimmingCharacters(in: .whitespacesAndNewlines)
                 .trimmingCharacters(in: CharacterSet(charactersIn: "。"))
                 .trimmingCharacters(in: .whitespaces)
            return s.isEmpty ? nil : SysDictEntry(pos: nil, text: s)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Headword + reading
            VStack(alignment: .leading, spacing: 2) {
                if let hw = headword {
                    Text(hw).font(.title2.bold()).japaneseLocale()
                }
                if let rd = reading {
                    Text(rd).font(.subheadline).foregroundStyle(.secondary).japaneseLocale()
                }
            }
            // POS pill
            if let pos = partOfSpeech {
                Text(pos)
                    .font(.caption.bold()).foregroundStyle(.blue)
                    .padding(.horizontal, 7).padding(.vertical, 2)
                    .background(Color.blue.opacity(0.08)).clipShape(Capsule())
                    .japaneseLocale()
            }
            if !entries.isEmpty {
                SysDictEntryList(entries: entries, textLocale: .japanese)
            }
        }
    }
}

// MARK: - Chinese Parser
// Raw format: "词 pīnyīn 词性 ①动 释义。例句 | 例句 ②动 释义"
// Or single-sense: "词 pīnyīn 词性 释义。用法说明 ㊀见"..."

private struct SysDictChineseView: View {
    let raw: String

    // Circle numbers ①–⑳ (U+2460–U+2473)
    private static let circles: [Character] = Array("①②③④⑤⑥⑦⑧⑨⑩⑪⑫⑬⑭⑮⑯⑰⑱⑲⑳")
    // Enclosed numbers ㊀–㊉ (U+3280–U+3289), used for usage notes
    private static let enclosed: [Character] = Array("㊀㊁㊂㊃㊄㊅㊆㊇㊈㊉")
    // Part of speech single-char keywords that may appear as the third token
    private static let posKeywords = ["形", "动", "名", "副", "代", "量", "连", "介", "助", "叹", "拟", "数"]

    /// Pinyin: second whitespace-delimited token (e.g. "měilì")
    var pinyin: String? {
        let tokens = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard tokens.count >= 2 else { return nil }
        return tokens[1]
    }

    /// POS: third token if it matches a known part-of-speech keyword
    var partOfSpeech: String? {
        let tokens = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard tokens.count >= 3 else { return nil }
        let candidate = tokens[2]
        return Self.posKeywords.contains(candidate) ? candidate : nil
    }

    var entries: [SysDictEntry] {
        // Drop the "word pinyin [pos]" prefix tokens
        let tokens = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard tokens.count >= 2 else { return [SysDictEntry(pos: nil, text: raw)] }
        var skip = 2 // word + pinyin
        if tokens.count >= 3 && Self.posKeywords.contains(tokens[2]) { skip = 3 }
        var body = tokens.dropFirst(skip).joined(separator: " ")

        // Strip usage-note sections that start with enclosed numbers ㊀㊁...
        for ch in Self.enclosed {
            if let r = body.firstIndex(of: ch) {
                body = String(body[..<r]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        // Strip trailing reference sections
        for m in ["用法说明", "参见", "ORIGIN"] {
            if let r = body.range(of: m) {
                body = String(body[..<r.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        // Split on ①②③ circle numbers into separate senses
        var parts: [String] = []
        var current = ""
        for ch in body {
            if Self.circles.contains(ch) {
                let t = current.trimmingCharacters(in: .whitespacesAndNewlines)
                if !t.isEmpty { parts.append(t) }
                current = ""
            } else {
                current.append(ch)
            }
        }
        let last = current.trimmingCharacters(in: .whitespacesAndNewlines)
        if !last.isEmpty { parts.append(last) }

        // No circle numbers → treat the whole body as a single entry
        if parts.isEmpty { parts = [body] }

        return parts.compactMap { part -> SysDictEntry? in
            var s = part
            // Extract inline POS at the start of each sense, e.g. "动 释义"
            var entryPos: String? = nil
            for kw in Self.posKeywords {
                if s.hasPrefix(kw + " ") || s == kw {
                    entryPos = kw
                    s = String(s.dropFirst(kw.count)).trimmingCharacters(in: .whitespaces)
                    break
                }
            }
            // Strip pipe-separated example sentences after the definition
            if let pr = s.range(of: " | ") { s = String(s[..<pr.lowerBound]) }
            if let pr = s.range(of: "| ") { s = String(s[..<pr.lowerBound]) }
            s = s.trimmingCharacters(in: .whitespacesAndNewlines)
            return s.isEmpty ? nil : SysDictEntry(pos: entryPos, text: s)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Pinyin and POS shown as header row
            HStack(spacing: 8) {
                if let py = pinyin {
                    Text(py).font(.title3).italic().foregroundStyle(.secondary)
                }
                if let pos = partOfSpeech {
                    Text(pos)
                        .font(.caption.bold()).foregroundStyle(.orange)
                        .padding(.horizontal, 7).padding(.vertical, 2)
                        .background(Color.orange.opacity(0.08)).clipShape(Capsule())
                }
            }
            if !entries.isEmpty {
                SysDictEntryList(entries: entries, textLocale: .chinese)
            }
        }
    }
}

// MARK: - Korean Parser
// macOS 系统韩语词典格式: "단어 | 발음 | 품사 ① 定义 ② 定义"
// 或者更简单的纯文本，按句号或换行分割

private struct SysDictKoreanView: View {
    let raw: String

    private static let circles: [Character] = Array("①②③④⑤⑥⑦⑧⑨⑩⑪⑫⑬⑭⑮⑯⑰⑱⑲⑳")

    // Romanization / pronunciation hint after " | "
    var pronunciation: String? {
        let parts = raw.components(separatedBy: " | ")
        guard parts.count >= 2 else { return nil }
        let candidate = parts[1].trimmingCharacters(in: .whitespaces)
        // Must be latin-ish (romanization) or contain ː
        let isLatin = candidate.unicodeScalars.contains { $0.value < 0x0250 && $0.value > 0x0040 }
        return (isLatin && !candidate.isEmpty) ? candidate : nil
    }

    var entries: [SysDictEntry] {
        var body = raw
        // Strip "word | pronunciation | " prefix when present
        var pipeCount = 0
        var idx = body.startIndex
        while pipeCount < 2, let r = body.range(of: " | ", range: idx..<body.endIndex) {
            pipeCount += 1
            idx = r.upperBound
        }
        if pipeCount == 2 { body = String(body[idx...]) }
        body = body.trimmingCharacters(in: .whitespacesAndNewlines)

        // Try splitting on circle numbers first
        var parts: [String] = []
        var current = ""
        for ch in body {
            if Self.circles.contains(ch) {
                let t = current.trimmingCharacters(in: .whitespacesAndNewlines)
                if !t.isEmpty { parts.append(t) }
                current = ""
            } else {
                current.append(ch)
            }
        }
        let last = current.trimmingCharacters(in: .whitespacesAndNewlines)
        if !last.isEmpty { parts.append(last) }

        // Fallback: split on newline or ". "
        if parts.count <= 1 {
            parts = body.components(separatedBy: "\n").flatMap {
                $0.components(separatedBy: ". ")
            }.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        }

        return parts.compactMap { part -> SysDictEntry? in
            let s = part.trimmingCharacters(in: .whitespacesAndNewlines)
            return s.isEmpty ? nil : SysDictEntry(pos: nil, text: s)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let pron = pronunciation {
                Text(pron).font(.title3).italic().foregroundStyle(.secondary)
            }
            if !entries.isEmpty {
                SysDictEntryList(entries: entries, textLocale: .korean)
            }
        }
    }
}
#endif

// MARK: - System Dictionary VC Wrapper (iOS)

#if canImport(UIKit)
/// Wraps UIReferenceLibraryViewController for presentation inside SwiftUI.
private struct SystemDictionaryView: UIViewControllerRepresentable {
    let term: String

    func makeUIViewController(context: Context) -> UIReferenceLibraryViewController {
        UIReferenceLibraryViewController(term: term)
    }

    func updateUIViewController(_ uiViewController: UIReferenceLibraryViewController, context: Context) {}
}
#endif

// MARK: - Preview

#Preview {
    DictionaryView()
        .modelContainer(for: [Settings.self, QueryHistory.self], inMemory: true)
}
