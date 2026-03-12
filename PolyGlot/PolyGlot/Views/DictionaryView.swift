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
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "character.book.closed.fill")
                    .foregroundStyle(.blue)
                Text("系统词典")
                    .font(.headline)
                    .foregroundStyle(.blue)
                Spacer()
            }

            #if os(macOS)
            Text(result.definition)
                .font(.body)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
            #else
            if result.found {
                Button {
                    viewModel.showSystemDictionary = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "book.pages")
                        Text("查看系统词典释义")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .padding(12)
                    .background(Color.blue.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            } else {
                Text(result.definition)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            #endif
        }
        .cardStyle(accentColor: .blue)
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
