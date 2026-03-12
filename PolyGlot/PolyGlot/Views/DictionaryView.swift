import SwiftUI
import SwiftData

struct DictionaryView: View {
    @State private var viewModel = DictionaryViewModel()
    @Query private var settingsList: [Settings]

    private var settings: Settings {
        settingsList.first ?? Settings()
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                Divider()
                resultArea
            }
            .navigationTitle("词典")
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
            loadingView
        } else if let errorMessage = viewModel.errorMessage {
            errorView(message: errorMessage)
        } else if let result = viewModel.result {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
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
        } else {
            emptyState
        }
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
                languageBadge(lang)
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

    // MARK: - Loading / Error / Empty States

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("正在分析...")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("重试") {
                submitSearch()
            }
            .buttonStyle(.borderedProminent)

            // Show raw response if available
            if let raw = viewModel.rawResponse {
                Divider()
                ScrollView {
                    Text(raw)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .padding()
                }
                .frame(maxHeight: 200)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("输入单词开始查词")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private func submitSearch() {
        guard !viewModel.searchText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        Task {
            await viewModel.analyze(settings: settings)
        }
    }

    private func outputLanguages(for input: SupportedLanguage?) -> [SupportedLanguage] {
        guard let input else { return SupportedLanguage.allCases }
        return SupportedLanguage.allCases.filter { $0 != input }
    }

    private func languageBadge(_ language: SupportedLanguage) -> some View {
        Text(language.displayName)
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(languageColor(language).opacity(0.15))
            .foregroundStyle(languageColor(language))
            .clipShape(Capsule())
    }

    private func languageColor(_ language: SupportedLanguage) -> Color {
        switch language {
        case .english:  return .blue
        case .chinese:  return .red
        case .japanese: return .purple
        case .korean:   return .green
        }
    }
}

// MARK: - English Card

private struct EnglishCard: View {
    let analysis: EnglishAnalysis

    var body: some View {
        LanguageSection(title: "English", color: .blue) {
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
        LanguageSection(title: "中文", color: .red) {
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
    }
}

// MARK: - Japanese Card

private struct JapaneseCard: View {
    let analysis: JapaneseAnalysis

    var body: some View {
        LanguageSection(title: "日本語", color: .purple) {
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
                InfoRow(label: "词源", value: etymology)
            }

            // Conjugation
            if let conjugation = analysis.conjugation, !conjugation.isEmpty {
                InfoRow(label: "变形", value: conjugation)
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
        LanguageSection(title: "한국어", color: .green) {
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

/// A collapsible/non-collapsible section card per language.
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
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(color.opacity(0.25), lineWidth: 1)
        )
    }
}

private struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body)
                .textSelection(.enabled)
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
                }
                Text(meaning)
                    .font(.body)
                    .textSelection(.enabled)
            }

            if let example, !example.isEmpty {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    VStack(alignment: .leading, spacing: 2) {
                        if exampleLanguage == .japanese {
                            FuriganaText(example, font: .subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            Text(example)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .italic()
                                .textSelection(.enabled)
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

// MARK: - Preview

#Preview {
    DictionaryView()
        .modelContainer(for: Settings.self, inMemory: true)
}
