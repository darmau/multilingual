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
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(result.inputWord)
                .font(.largeTitle.bold())

            if let lang = SupportedLanguage(rawValue: result.inputLanguage) {
                SpeakButton(text: result.inputWord, language: lang)
                    .font(.title2)
            }

            Spacer()

            if let lang = SupportedLanguage(rawValue: result.inputLanguage) {
                LanguageBadge(language: lang)
            }
        }
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
            // Phonetic
            if let phonetic = analysis.phonetic, !phonetic.isEmpty {
                InfoRow(label: "音标", value: phonetic)
            }

            // Definitions
            if !analysis.definitions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("释义").font(.subheadline.bold()).foregroundStyle(.secondary)
                    ForEach(Array(analysis.definitions.enumerated()), id: \.offset) { _, def in
                        DefinitionRow(
                            pos: def.pos,
                            meaning: def.meaning,
                            example: def.example,
                            exampleLanguage: .english
                        )
                    }
                }
            }

            // Etymology
            if let etymology = analysis.etymology, !etymology.isEmpty {
                InfoRow(label: "词源", value: etymology)
            }

            // Synonyms / Antonyms
            if let synonyms = analysis.synonyms, !synonyms.isEmpty {
                WordListRow(label: "近义词", words: synonyms, language: .english)
            }
            if let antonyms = analysis.antonyms, !antonyms.isEmpty {
                WordListRow(label: "反义词", words: antonyms, language: .english)
            }
        }
    }
}

// MARK: - Chinese Card

private struct ChineseCard: View {
    let analysis: ChineseAnalysis

    var body: some View {
        LanguageSection(title: "中文", color: .language(.chinese)) {
            HStack {
                Text(analysis.word)
                    .font(.title2.bold())
                // No SpeakButton for Chinese
            }

            if !analysis.definitions.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(analysis.definitions.enumerated()), id: \.offset) { _, def in
                        Text(def.meaning)
                            .font(.body)
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
            // Word + reading + speak
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                FuriganaText(analysis.word, font: .title2)
                    .fontWeight(.bold)
                SpeakButton(text: FuriganaParser.plainText(from: FuriganaParser.parse(analysis.word)),
                            language: .japanese)
            }

            // Definitions
            if !analysis.definitions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("释义").font(.subheadline.bold()).foregroundStyle(.secondary)
                    ForEach(Array(analysis.definitions.enumerated()), id: \.offset) { _, def in
                        DefinitionRow(
                            pos: def.pos,
                            meaning: def.meaning,
                            example: def.example,
                            exampleLanguage: .japanese,
                            exampleReading: def.exampleReading
                        )
                    }
                }
            }

            // Etymology
            if let etymology = analysis.etymology, !etymology.isEmpty {
                InfoRow(label: "词源", value: etymology, valueLanguage: .japanese)
            }

            // Conjugation
            if let conjugation = analysis.conjugation, !conjugation.isEmpty {
                InfoRow(label: "变形", value: conjugation, valueLanguage: .japanese)
            }

            // Synonyms / Antonyms
            if let synonyms = analysis.synonyms, !synonyms.isEmpty {
                WordListRow(label: "近义词", words: synonyms, language: .japanese)
            }
            if let antonyms = analysis.antonyms, !antonyms.isEmpty {
                WordListRow(label: "反义词", words: antonyms, language: .japanese)
            }
        }
    }
}

// MARK: - Korean Card

private struct KoreanCard: View {
    let analysis: KoreanAnalysis

    var body: some View {
        LanguageSection(title: "한국어", color: .language(.korean)) {
            // Word + reading + speak
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(analysis.word)
                        .font(.title2.bold())
                    if let reading = analysis.reading, !reading.isEmpty {
                        Text(reading)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                SpeakButton(text: analysis.word, language: .korean)
            }

            // Definitions
            if !analysis.definitions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("释义").font(.subheadline.bold()).foregroundStyle(.secondary)
                    ForEach(Array(analysis.definitions.enumerated()), id: \.offset) { _, def in
                        DefinitionRow(
                            pos: def.pos,
                            meaning: def.meaning,
                            example: def.example,
                            exampleLanguage: .korean
                        )
                    }
                }
            }

            // Etymology
            if let etymology = analysis.etymology, !etymology.isEmpty {
                InfoRow(label: "词源", value: etymology)
            }

            // Conjugation
            if let conjugation = analysis.conjugation, !conjugation.isEmpty {
                InfoRow(label: "变形", value: conjugation)
            }
        }
    }
}

// MARK: - Shared Sub-components

/// A card section per language using the shared cardStyle modifier.
private struct LanguageSection<Content: View>: View {
    let title: String
    let color: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(color)
                .padding(.bottom, 2)
            content()
        }
        .cardStyle(accentColor: color)
    }
}

private struct InfoRow: View {
    let label: String
    let value: String
    /// Language of the value text — used to apply correct CJK glyph variant.
    var valueLanguage: SupportedLanguage = .english

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .chineseLocale()                // UI labels are always Chinese
            Text(value)
                .font(.body)
                .textSelection(.enabled)
                .modifier(LanguageLocaleModifier(language: valueLanguage))
        }
    }
}

private struct DefinitionRow: View {
    let pos: String?
    let meaning: String
    let example: String?
    let exampleLanguage: SupportedLanguage
    var exampleReading: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                if let pos, !pos.isEmpty {
                    Text(pos)
                        .font(.caption.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.quaternary)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .modifier(LanguageLocaleModifier(language: exampleLanguage))
                }
                // Meanings are always written in Chinese (per CLAUDE.md rules)
                Text(meaning)
                    .font(.body)
                    .textSelection(.enabled)
                    .chineseLocale()
            }

            if let example, !example.isEmpty {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    VStack(alignment: .leading, spacing: 2) {
                        if exampleLanguage == .japanese {
                            // FuriganaText internally sets japaneseLocale
                            FuriganaText(example, font: .subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            Text(example)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .italic()
                                .textSelection(.enabled)
                                .modifier(LanguageLocaleModifier(language: exampleLanguage))
                        }
                    }
                    SpeakButton(
                        text: exampleLanguage == .japanese
                            ? FuriganaParser.plainText(from: FuriganaParser.parse(example))
                            : example,
                        language: exampleLanguage
                    )
                    .font(.caption)
                }
            }
        }
        .padding(.leading, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        var parts: [String] = []
        if let pos, !pos.isEmpty { parts.append(pos) }
        parts.append(meaning)
        if let example, !example.isEmpty { parts.append("例句: \(FuriganaParser.plainText(from: FuriganaParser.parse(example)))") }
        return parts.joined(separator: "，")
    }
}

private struct WordListRow: View {
    let label: String
    let words: [String]
    let language: SupportedLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(words, id: \.self) { word in
                        HStack(spacing: 4) {
                            Text(word)
                                .font(.subheadline)
                            SpeakButton(text: word, language: language)
                                .font(.caption)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.quaternary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
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
