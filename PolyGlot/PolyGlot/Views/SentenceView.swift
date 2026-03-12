import SwiftUI
import SwiftData

struct SentenceView: View {
    @State private var viewModel = SentenceViewModel()
    @Query private var settingsList: [Settings]

    private var settings: Settings {
        settingsList.first ?? Settings()
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                inputArea
                Divider()
                resultArea
            }
            .navigationTitle("句子分析")
        }
    }

    // MARK: - Input Area

    private var inputArea: some View {
        VStack(spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                TextEditor(text: $viewModel.inputText)
                    .font(.body)
                    .frame(minHeight: 80, maxHeight: 140)
                    .scrollContentBackground(.hidden)
                    .onChange(of: viewModel.inputText) {
                        viewModel.detectLanguage()
                    }
                    .overlay(alignment: .topLeading) {
                        if viewModel.inputText.isEmpty {
                            Text("输入句子或段落...")
                                .font(.body)
                                .foregroundStyle(.tertiary)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                                .allowsHitTesting(false)
                        }
                    }

                VStack(spacing: 8) {
                    // Speak input button
                    if let lang = viewModel.effectiveLanguage {
                        SpeakButton(text: viewModel.inputText, language: lang)
                            .font(.title3)
                    }

                    // Clear button
                    if !viewModel.inputText.isEmpty {
                        Button {
                            viewModel.reset()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)

            // Bottom row: language detection + submit
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

                Button {
                    submitAnalysis()
                } label: {
                    Label("分析", systemImage: "doc.text.magnifyingglass")
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isLoading)
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
        }
        .background(.bar)
    }

    // MARK: - Result Area

    @ViewBuilder
    private var resultArea: some View {
        if viewModel.isLoading {
            loadingView
        } else if let error = viewModel.errorMessage {
            errorView(message: error)
        } else if let result = viewModel.result {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    let inputLang = SupportedLanguage(rawValue: result.inputLanguage)

                    // Input language section first
                    if let lang = inputLang {
                        languageSection(for: lang, analyses: result.analyses, isInput: true)
                    }

                    // Other languages
                    let others = SupportedLanguage.allCases.filter { $0 != inputLang }
                    ForEach(others, id: \.self) { lang in
                        languageSection(for: lang, analyses: result.analyses, isInput: false)
                    }
                }
                .padding()
            }
        } else {
            emptyState
        }
    }

    // MARK: - Language Section Router

    @ViewBuilder
    private func languageSection(
        for language: SupportedLanguage,
        analyses: SentenceLanguageAnalyses,
        isInput: Bool
    ) -> some View {
        switch language {
        case .english:
            if let a = analyses.english {
                EnglishSentenceCard(analysis: a, isInput: isInput)
            }
        case .chinese:
            if let a = analyses.chinese, !(a.translation.isEmpty) {
                ChineseSentenceCard(analysis: a)
            }
        case .japanese:
            if let a = analyses.japanese {
                JapaneseSentenceCard(analysis: a, isInput: isInput)
            }
        case .korean:
            if let a = analyses.korean {
                KoreanSentenceCard(analysis: a, isInput: isInput)
            }
        }
    }

    // MARK: - States

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView().scaleEffect(1.5)
            Text("正在分析...").foregroundStyle(.secondary)
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
            Button("重试") { submitAnalysis() }
                .buttonStyle(.borderedProminent)

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
            Image(systemName: "text.bubble")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("输入句子开始分析")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helper

    private func submitAnalysis() {
        guard !viewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        Task { await viewModel.analyze(settings: settings) }
    }
}

// MARK: - Language Cards

private struct EnglishSentenceCard: View {
    let analysis: EnglishSentenceAnalysis
    let isInput: Bool

    var body: some View {
        SentenceLanguageSection(title: "English", color: .blue) {
            if let translation = analysis.translation, !translation.isEmpty {
                TranslationRow(text: translation, language: .english)
            }

            if let grammar = analysis.grammar, isInput {
                GrammarDisclosure(title: "语法分析") {
                    if let structure = grammar.structure, !structure.isEmpty {
                        GrammarInfoRow(label: "句型", value: structure)
                    }
                    if let tense = grammar.tense, !tense.isEmpty {
                        GrammarInfoRow(label: "时态", value: tense)
                    }
                    if let voice = grammar.voice, !voice.isEmpty {
                        GrammarInfoRow(label: "语态", value: voice)
                    }
                    if let clauses = grammar.clauses, !clauses.isEmpty {
                        ClausesList(clauses: clauses)
                    }
                    if let phrases = grammar.keyPhrases, !phrases.isEmpty {
                        KeyPhrasesSection(phrases: phrases)
                    }
                }
            }
        }
    }
}

private struct ChineseSentenceCard: View {
    let analysis: ChineseSentenceAnalysis

    var body: some View {
        SentenceLanguageSection(title: "中文", color: .red) {
            // Chinese is translation-only, no SpeakButton
            Text(analysis.translation)
                .font(.body)
                .textSelection(.enabled)
        }
    }
}

private struct JapaneseSentenceCard: View {
    let analysis: JapaneseSentenceAnalysis
    let isInput: Bool

    var body: some View {
        SentenceLanguageSection(title: "日本語", color: .purple) {
            // FuriganaText handles inline ruby; translationReading shown as
            // a plain-kana fallback only when the translation contains no markup.
            TranslationRow(text: analysis.translation, language: .japanese)
            if !analysis.translation.contains("{"),
               let reading = analysis.translationReading, !reading.isEmpty {
                Text(reading)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let grammar = analysis.grammar, isInput {
                GrammarDisclosure(title: "语法分析") {
                    if let structure = grammar.structure, !structure.isEmpty {
                        GrammarInfoRow(label: "文型", value: structure)
                    }
                    if let politeness = grammar.politenessLevel, !politeness.isEmpty {
                        GrammarInfoRow(label: "敬语等级", value: politeness)
                    }
                    if let particles = grammar.particles, !particles.isEmpty {
                        ParticlesSection(items: particles.map { ($0.particle, $0.function) })
                    }
                    if let conjugations = grammar.conjugations, !conjugations.isEmpty {
                        ConjugationSection(conjugations: conjugations)
                    }
                    if let patterns = grammar.keyPatterns, !patterns.isEmpty {
                        JapanesePatternSection(patterns: patterns)
                    }
                }
            }
        }
    }
}

private struct KoreanSentenceCard: View {
    let analysis: KoreanSentenceAnalysis
    let isInput: Bool

    var body: some View {
        SentenceLanguageSection(title: "한국어", color: .green) {
            TranslationRow(text: analysis.translation, language: .korean)

            if let grammar = analysis.grammar, isInput {
                GrammarDisclosure(title: "语法分析") {
                    if let structure = grammar.structure, !structure.isEmpty {
                        GrammarInfoRow(label: "文型", value: structure)
                    }
                    if let politeness = grammar.politenessLevel, !politeness.isEmpty {
                        GrammarInfoRow(label: "敬语等级", value: politeness)
                    }
                    if let particles = grammar.particles, !particles.isEmpty {
                        ParticlesSection(items: particles.map { ($0.particle, $0.function) })
                    }
                    if let conjugations = grammar.conjugations, !conjugations.isEmpty {
                        ConjugationSection(conjugations: conjugations)
                    }
                    if let patterns = grammar.keyPatterns, !patterns.isEmpty {
                        KoreanPatternSection(patterns: patterns)
                    }
                }
            }
        }
    }
}

// MARK: - Shared Sub-components

private struct SentenceLanguageSection<Content: View>: View {
    let title: String
    let color: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(color)

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

private struct TranslationRow: View {
    let text: String
    let language: SupportedLanguage

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            if language == .japanese {
                FuriganaText(text, font: .body)
            } else {
                Text(text)
                    .font(.body)
                    .textSelection(.enabled)
            }
            SpeakButton(
                text: language == .japanese
                    ? FuriganaParser.plainText(from: FuriganaParser.parse(text))
                    : text,
                language: language
            )
        }
    }
}

private struct GrammarDisclosure<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content
    @State private var isExpanded = true

    var body: some View {
        DisclosureGroup(title, isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 10) {
                content()
            }
            .padding(.top, 8)
        }
        .font(.subheadline.bold())
        .tint(.primary)
    }
}

private struct GrammarInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .textSelection(.enabled)
        }
    }
}

private struct ClausesList: View {
    let clauses: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("从句拆解")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            ForEach(Array(clauses.enumerated()), id: \.offset) { i, clause in
                HStack(alignment: .top, spacing: 6) {
                    Text("\(i + 1).")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .frame(width: 16, alignment: .trailing)
                    Text(clause)
                        .font(.subheadline)
                        .textSelection(.enabled)
                }
            }
        }
    }
}

private struct KeyPhrasesSection: View {
    let phrases: [EnglishKeyPhrase]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("关键短语")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            ForEach(Array(phrases.enumerated()), id: \.offset) { _, phrase in
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(phrase.phrase)
                            .font(.subheadline.bold())
                        SpeakButton(text: phrase.phrase, language: .english)
                            .font(.caption)
                    }
                    Text(phrase.explanation)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let gp = phrase.grammarPoint, !gp.isEmpty {
                        Text(gp)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.blue.opacity(0.1))
                            .foregroundStyle(.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
                .padding(8)
                .background(.quaternary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

private struct ParticlesSection: View {
    let items: [(particle: String, function: String)]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("助词")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .top, spacing: 8) {
                    Text(item.particle)
                        .font(.subheadline.bold())
                        .frame(minWidth: 32, alignment: .leading)
                    Text(item.function)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }
        }
    }
}

private struct ConjugationSection: View {
    let conjugations: [Conjugation]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("活用 / 变形")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            ForEach(Array(conjugations.enumerated()), id: \.offset) { _, c in
                HStack(spacing: 8) {
                    Text(c.word)
                        .font(.subheadline)
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Text(c.conjugated)
                        .font(.subheadline.bold())
                    if let type = c.type, !type.isEmpty {
                        Text(type)
                            .font(.caption)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(.quaternary)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
            }
        }
    }
}

private struct JapanesePatternSection: View {
    let patterns: [JapaneseKeyPattern]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("句型模式")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            ForEach(Array(patterns.enumerated()), id: \.offset) { _, p in
                VStack(alignment: .leading, spacing: 3) {
                    Text(p.pattern)
                        .font(.subheadline.bold())
                        .foregroundStyle(.purple)
                    Text(p.meaning)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let usage = p.usage, !usage.isEmpty {
                        Text(usage)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(8)
                .background(.purple.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

private struct KoreanPatternSection: View {
    let patterns: [KoreanKeyPattern]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("句型模式")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            ForEach(Array(patterns.enumerated()), id: \.offset) { _, p in
                VStack(alignment: .leading, spacing: 3) {
                    Text(p.pattern)
                        .font(.subheadline.bold())
                        .foregroundStyle(.green)
                    Text(p.meaning)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(8)
                .background(.green.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SentenceView()
        .modelContainer(for: Settings.self, inMemory: true)
}
