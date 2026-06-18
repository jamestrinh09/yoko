import SwiftUI

struct QuestionRenderer: View {
    let question: Question
    @Binding var selectedAnswer: String?
    let feedback: LessonPlayerView.Feedback
    var unscramble: UnscrambleState = UnscrambleState()
    var hint: QuestionHintState = QuestionHintState()

    @State private var builtTokens: [String] = []

    private var normalized: NormalizedQuestion? { question.normalized }
    private var content: [String: String] { normalized?.questionContent ?? [:] }
    private var choices: [String] { normalized?.answerChoices ?? fallbackChoices }
    private var template: String { normalized?.templateType.snakeKey ?? "generic" }
    private var interaction: String { normalized?.interactionType.snakeKey ?? "tap_choice" }
    private var isLocked: Bool { feedback != .none }

    var body: some View {
        VStack(spacing: 0) {
            // Question title + instruction
            VStack(spacing: 10) {
                if isUnscramble, let parts = unscramblePromptParts {
                    Text(parts.head)
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(DS.Color.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity)
                    Text(parts.letters)
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundStyle(DS.Color.accent)
                        .tracking(8)
                        .multilineTextAlignment(.center)
                } else {
                    Text(questionTitle)
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(DS.Color.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity)

                    Text(questionHelper)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(DS.Color.accent)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 16)

            // Interactive content
            interactiveContent
                .padding(.horizontal, 20)
                .padding(.bottom, 20)

            // Answer options area (when separate from interactive content)
            if showsSeparateChoiceArea {
                answerOptionsArea
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
            }
        }
        .scaleEffect(feedback == .correct ? 1.01 : 1)
        .offset(x: feedback == .incorrect ? -3 : 0)
        .animation(.spring(duration: 0.35), value: feedback)
        .onChange(of: builtTokens) { _, newValue in
            selectedAnswer = assembledAnswer(from: newValue)
        }
        .onChange(of: questionKey) { _, _ in
            builtTokens = []
            selectedAnswer = nil
            configureHint()
        }
        .onChange(of: feedback) { _, _ in
            hint.isLocked = isLocked
        }
        .onAppear { configureHint() }
    }

    // MARK: - Question Meta

    private var questionTitle: String {
        let raw = normalized?.prompt ?? question.prompt
        // Vocabulary prompts read better without a trailing period.
        return template == "vocabulary_matching" ? raw.strippedTrailingPeriod : raw
    }

    /// True when the answer choices are single emoji glyphs (picture vocab).
    private var isEmojiChoices: Bool {
        !choices.isEmpty && choices.allSatisfy { choice in
            let trimmed = choice.trimmingCharacters(in: .whitespaces)
            return trimmed.unicodeScalars.contains { $0.properties.isEmojiPresentation || $0.properties.isEmoji }
                && trimmed.count <= 2
        }
    }

    private var isUnscramble: Bool { template == "unscramble_word" }

    /// Splits an unscramble prompt like "Unscramble these letters: y  n  k  o  e  m"
    /// into the head sentence and the scrambled letter row that should render
    /// in orange on its own line.
    private var unscramblePromptParts: (head: String, letters: String)? {
        let prompt = normalized?.prompt ?? question.prompt
        guard let colon = prompt.firstIndex(of: ":") else { return nil }
        let head = String(prompt[..<colon]) + ":"
        let tail = prompt[prompt.index(after: colon)...].trimmingCharacters(in: .whitespacesAndNewlines)
        return (head, tail)
    }

    /// Stable identity for the question content (avoids resetting state when
    /// `question.id` (a fresh UUID) changes on each render).
    private var questionKey: String { normalized?.id ?? question.prompt }

    private var questionHelper: String {
        let raw = normalized?.directions ?? "Tap your answer"
        return template == "vocabulary_matching" ? raw.strippedTrailingPeriod : raw
    }

    // MARK: - Universal Hint

    /// True for choice-based templates where the hint can fade one wrong option.
    /// Unscramble owns its own hint (locking placed letters) so it opts out here.
    private var supportsGenericHint: Bool {
        guard template != "unscramble_word" else { return false }
        return choices.count >= 2 && correctValue != nil
    }

    private var correctValue: String? { normalized?.correctAnswer }

    /// A single wrong choice to fade out when the hint is revealed — teaches by
    /// elimination without giving away the answer.
    private var hintWrongChoice: String? {
        guard let correct = correctValue else { return nil }
        return choices.first { $0 != correct }
    }

    /// The choice currently faded by an active, revealed hint (nil otherwise).
    private var hintFadedChoice: String? {
        (hint.active && hint.revealed) ? hint.fadedChoice : nil
    }

    private func configureHint() {
        hint.revealed = false
        hint.available = false
        hint.glow = false
        hint.isLocked = isLocked
        guard supportsGenericHint else {
            hint.active = false
            hint.fadedChoice = nil
            return
        }
        hint.active = true
        hint.fadedChoice = hintWrongChoice
        let key = questionKey
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            guard hint.active, hint.questionKey == key, !hint.revealed else { return }
            hint.available = true
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                hint.glow = true
            }
        }
        hint.questionKey = key
    }

    // MARK: - Interactive Content

    @ViewBuilder
    private var interactiveContent: some View {
        switch template {
        case "counting_objects":
            EmojiCounterRow(items: split(content["items"]), hint: feedback == .incorrect, fixedColumns: int(content["columns"]) > 0 ? int(content["columns"]) : nil)

        case "which_has_more_or_less":
            tappableComparison

        case "compare_numbers":
            // Compare a numeral against a counted group of objects (or two
            // numerals for legacy questions). After a choice is made the greater
            // quantity grows and the smaller shrinks, reinforcing "greater".
            NumberComparisonCard(
                left: comparisonSide(forLeft: true),
                right: comparisonSide(forLeft: false),
                selected: selectedAnswer,
                locked: isLocked,
                fadedChoice: hintFadedChoice
            ) { selectedAnswer = $0 }

        case "addition_by_counting":
            AdditionGroupsCard(left: split(content["left"]), right: split(content["right"]), equation: content["equation"])

        case "subtraction_by_taking_away":
            // Pre-reader visual only: filled emoji = remaining, faded = removed.
            // The written equation is intentionally omitted so the picture carries
            // the meaning; numeric answer choices render below this visual.
            EmojiCounterRow(items: split(content["items"]), hint: feedback == .incorrect)

        case "missing_number_equation":
            buildBlankCard(pattern: content["equation"] ?? question.prompt, chips: chipValues, directSelect: true)

        case "number_line_jump":
            NumberLineCard(start: int(content["start"]), jump: signedInt(content["jump"]), selected: selectedAnswer, locked: isLocked) { selectedAnswer = $0 }

        case "make_ten":
            // Tappable ten-frame: the pre-filled dots are fixed; tapping the empty
            // slots fills them. Filling exactly the right number answers it.
            TenFrameCard(filled: int(content["filled"]), need: int(content["empty"]), locked: isLocked) { selectedAnswer = $0 }

        case "multiplication_arrays":
            // Build-the-array: tap + to add rows/columns up to the target, then
            // confirm the count with the choices below.
            ArrayBuilderCard(rows: int(content["rows"]), columns: int(content["columns"]), item: content["item"] ?? "●")

        case "division_as_sharing":
            // Tap-to-distribute: each tap sends one item round-robin into a bucket
            // until all are shared evenly, which answers the question.
            DivisionShareCard(total: totalObjects(content["objects"]), buckets: int(content["buckets"]), item: objectEmoji(content["objects"]), locked: isLocked) { selectedAnswer = $0 }

        case "pattern_recognition":
            PatternRowCard(sequence: visualSequence)

        case "fractions":
            FractionBarCard(parts: int(content["parts"]), filled: int(content["filled"]))

        case "telling_time":
            ClockCard(hour: int(content["hour"]), minute: int(content["minute"]))

        case "letter_recognition":
            // Show a picture and tap the letter its word starts with (no letter is
            // named in the prompt). The emoji carries the clue.
            VStack(spacing: 18) {
                if let emoji = content["emoji"], !emoji.isEmpty {
                    Text(emoji).font(.system(size: 80))
                }
                visualTapGrid(items: choices, style: .letter)
            }

        case "uppercase_lowercase_matching":
            MatchingCardSet(left: content["uppercase"] ?? "B", right: choices, selected: selectedAnswer, locked: isLocked, fadedChoice: hintFadedChoice) { selectedAnswer = $0 }

        case "beginning_sounds":
            // Letter-to-sound matching (no audio): the target letter shows big and
            // bold and the child taps the emoji whose word starts with that sound.
            // Choices are emoji-only, so it can't be solved by reading.
            LetterSoundMatchCard(
                letter: content["sound"] ?? "",
                choices: choices,
                selected: selectedAnswer,
                locked: isLocked,
                fadedChoice: hintFadedChoice
            ) { selectedAnswer = $0 }

        case "vocabulary_matching":
            // Emoji-picture vocab renders the choices twice as large; synonym
            // vocab (word choices) keeps the standard word style.
            visualTapGrid(items: choices, style: isEmojiChoices ? .emoji : .word)

        case "choose_correct_spelling", "sight_word_recognition":
            visualTapGrid(items: choices, style: englishChoiceStyle)

        case "rhyming_words", "word_families":
            // Once the hint is revealed, the shared ending letters are highlighted
            // across the choices to reinforce the sound pattern.
            RhymeFamilyGrid(
                choices: choices,
                rime: sharedRime,
                selected: selectedAnswer,
                locked: isLocked,
                fadedChoice: hintFadedChoice,
                revealed: hintRevealed
            ) { selectedAnswer = $0 }

        case "punctuation_choice":
            // A mascot face reacts to the punctuation being considered (curious for
            // ?, excited for !, neutral for .) to reinforce sentence tone.
            PunctuationCard(
                sentence: content["sentence"] ?? question.prompt,
                choices: choices,
                selected: selectedAnswer,
                locked: isLocked,
                fadedChoice: hintFadedChoice
            ) { selectedAnswer = $0 }

        case "true_or_false_math_statement":
            // Concrete emoji groups visualize the equation so the child can verify
            // it visually instead of only reading an abstract statement.
            TrueFalseMathCard(
                statement: content["statement"] ?? question.prompt,
                choices: choices,
                selected: selectedAnswer,
                locked: isLocked,
                fadedChoice: hintFadedChoice
            ) { selectedAnswer = $0 }

        case "missing_letter", "fill_missing_letters":
            // Tapping a choice fills the blank box and highlights the selection.
            MissingLetterCard(
                pattern: content["wordWithBlank"] ?? content["wordWithBlanks"] ?? question.prompt,
                choices: choices,
                emoji: content["emoji"],
                selected: selectedAnswer,
                locked: isLocked,
                fadedChoice: hintFadedChoice
            ) { selectedAnswer = $0 }

        case "unscramble_word":
            UnscrambleCard(
                letters: letterChips,
                correctAnswer: normalized?.correctAnswer ?? "",
                emoji: content["hint"],
                selectedAnswer: $selectedAnswer,
                isLocked: isLocked,
                state: unscramble
            )

        case "sentence_building":
            sentenceBuildCard(tokens: tokenValues)

        case "grammar_sorting", "category_match":
            // Consolidated into the multi-item drag-to-bucket interaction so even a
            // single word/picture is sorted the same way as category_sort.
            SortBucketsCard(
                buckets: choices,
                items: [(label: content["word"] ?? content["item"] ?? question.prompt, bucket: correctValue ?? "")],
                correct: correctValue ?? "sorted",
                locked: isLocked
            ) { selectedAnswer = $0 }

        case "reading_comprehension":
            StoryEmojiStrip(emojis: (content["emojis"] ?? "").replacingOccurrences(of: ",", with: " "), text: content["text"] ?? question.prompt)

        case "sequencing":
            sequenceBuildCard(cards: sequenceCards)

        case "memory_match":
            // Flip-card memory game: find every matching pair (e.g. uppercase ↔
            // lowercase, or word ↔ picture). Completing all pairs answers it.
            MemoryMatchCard(pairs: memoryPairs, locked: isLocked) {
                selectedAnswer = normalized?.correctAnswer ?? "matched"
            }

        case "category_sort":
            // Multi-item drag-to-sort: place several items into the right bucket.
            SortBucketsCard(
                buckets: splitComma(content["buckets"]),
                items: sortItems,
                correct: normalized?.correctAnswer ?? "sorted",
                locked: isLocked
            ) { selectedAnswer = $0 }

        case "timed_bonus":
            // Countdown-ring bonus round: answer before the ring empties for a
            // bonus star. No penalty if time runs out — just no bonus.
            TimedBonusCard(
                choices: choices,
                selected: selectedAnswer,
                locked: isLocked,
                seconds: 10,
                questionKey: questionKey,
                fadedChoice: hintFadedChoice
            ) { selectedAnswer = $0 }

        default:
            visualTapGrid(items: choices, style: .word)
        }
    }

    // MARK: - Answer Options Area

    private var answerOptionsArea: some View {
        visualTapGrid(items: choices, style: .number)
    }

    // MARK: - Visual Components

    private var tappableComparison: some View {
        HStack(spacing: 14) {
            comparisonButton(label: content["leftLabel"] ?? "left", title: "Group A", items: split(content["left"]))
            Text("or")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(DS.Color.accent)
            comparisonButton(label: content["rightLabel"] ?? "right", title: "Group B", items: split(content["right"]))
        }
    }

    private func comparisonButton(label: String, title: String, items: [String]) -> some View {
        Button {
            guard !isLocked else { return }
            selectedAnswer = label
        } label: {
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(DS.Color.textSecondary)
                EmojiCounterRow(items: items, hint: feedback == .incorrect)
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(selectedAnswer == label ? Color(red: 0.996, green: 0.994, blue: 0.992) : Color(red: 0.996, green: 0.994, blue: 0.992))
            .clipShape(.rect(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(selectedAnswer == label ? DS.Color.accent : Color.clear, lineWidth: 2)
            )
            .shadow(
                color: selectedAnswer == label ? DS.Color.accent.opacity(0.22) : Color.black.opacity(0.03),
                radius: selectedAnswer == label ? 10 : 4,
                x: 0,
                y: selectedAnswer == label ? 3 : 1
            )
        }
        .buttonStyle(.plain)
    }

    private func buildBlankCard(pattern: String, chips: [String], emoji: String? = nil, directSelect: Bool = false) -> some View {
        VStack(spacing: 16) {
            if let emoji {
                Text(emoji)
                    .font(.system(size: 40))
            }
            Text(displayPattern(pattern))
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .foregroundStyle(DS.Color.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(red: 0.996, green: 0.994, blue: 0.992))
                .clipShape(.rect(cornerRadius: 18))
                .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
            // For single-blank number equations the chip should fill the blank
            // directly (tap selects). Word builders keep the sequence builder.
            if directSelect {
                visualTapGrid(items: chips, style: .number)
            } else {
                chipTray(chips: chips)
            }
        }
    }

    private func wordBuildCard(chips: [String], emoji: String?) -> some View {
        VStack(spacing: 16) {
            if let emoji {
                Text(emoji)
                    .font(.system(size: 40))
            }
            answerAssemblyPlaceholder(count: normalized?.correctAnswer.count ?? chips.count)
            chipTray(chips: chips)
        }
    }

    private func sentenceBuildCard(tokens: [String]) -> some View {
        VStack(spacing: 16) {
            FlowRow(items: builtTokens, selected: nil, locked: false, action: { token in removeToken(token) })
                .frame(maxWidth: .infinity, minHeight: 54)
                .padding(10)
                .background(Color(red: 0.996, green: 0.994, blue: 0.992))
                .clipShape(.rect(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
                        .foregroundStyle(DS.Color.accent.opacity(0.3))
                )
                .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)

            chipTray(chips: tokens.filter { !builtTokens.contains($0) })
        }
    }

    private func sequenceBuildCard(cards: [String]) -> some View {
        VStack(spacing: 16) {
            FlowRow(items: builtTokens, selected: nil, locked: false, action: { token in removeToken(token) })
                .frame(maxWidth: .infinity, minHeight: 60)
                .padding(10)
                .background(Color(red: 0.996, green: 0.994, blue: 0.992))
                .clipShape(.rect(cornerRadius: 18))
                .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)

            chipTray(chips: cards.filter { !builtTokens.contains($0) })
        }
    }

    private func chipTray(chips: [String]) -> some View {
        FlowRow(items: chips, selected: nil, locked: isLocked) { chip in
            guard !isLocked else { return }
            if !builtTokens.contains(chip) { builtTokens.append(chip) }
        }
    }

    /// Builds one side of the number-comparison card. Mixed questions place a
    /// numeral on `numberSide` and a counted object group on the other side;
    /// legacy questions fall back to two numerals via `left`/`right`.
    private func comparisonSide(forLeft: Bool) -> NumberComparisonCard.Side {
        let sideKey = forLeft ? "left" : "right"
        if let emoji = content["objectEmoji"], !emoji.isEmpty,
           let number = Int(content["number"] ?? ""),
           let objectCount = Int(content["objectCount"] ?? "") {
            let numberSide = content["numberSide"] ?? "left"
            if sideKey == numberSide {
                return .init(value: number, emoji: nil)
            } else {
                return .init(value: objectCount, emoji: emoji)
            }
        }
        // Legacy: two numerals stored under left/right.
        let raw = content[sideKey] ?? (forLeft ? choices.first : choices.last) ?? ""
        return .init(value: Int(raw) ?? 0, emoji: nil)
    }

    private func visualTapGrid(items: [String], style: ChoiceStyle) -> some View {
        FlowRow(items: items, selected: selectedAnswer, locked: isLocked, fadedChoice: hintFadedChoice) { item in
            guard !isLocked else { return }
            selectedAnswer = item
        }
        .environment(\.choiceStyle, style)
    }

    private func answerAssemblyPlaceholder(count: Int) -> some View {
        HStack(spacing: 8) {
            ForEach(0..<max(count, 1), id: \.self) { i in
                Text(i < builtTokens.joined().count ? String(Array(builtTokens.joined())[i]) : "_")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .frame(width: 36, height: 46)
                    .background(Color(red: 0.996, green: 0.994, blue: 0.992))
                    .clipShape(.rect(cornerRadius: 12))
                    .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 1)
            }
        }
    }

    private func removeToken(_ token: String) {
        guard !isLocked, let i = builtTokens.firstIndex(of: token) else { return }
        builtTokens.remove(at: i)
    }

    // MARK: - Helpers

    private var showsSeparateChoiceArea: Bool {
        // Only these templates render a non-choice visual (emoji counts, arrays,
        // clocks, fraction bars, etc.) and therefore need a separate row of answer
        // choices below. Every other template either renders its own choices inline
        // (self-contained templates like letter recognition or comparisons) or is a
        // generic multiple-choice question handled by the `default` interactive
        // case — for those, rendering the choices here too would duplicate them and
        // produce the 2x2 grid of repeated options.
        // make_ten keeps its tappable ten-frame AND shows multiple-choice answers
        // below, so the child can either count by filling circles or pick a number.
        // division_as_sharing remains self-answering (distributing reports it).
        let visualWithSeparateChoices: Set<String> = [
            "counting_objects", "addition_by_counting", "subtraction_by_taking_away",
            "multiplication_arrays", "make_ten",
            "pattern_recognition", "fractions", "telling_time", "reading_comprehension"
        ]
        return visualWithSeparateChoices.contains(template) && choices.count > 1
    }

    /// True when the universal hint has been revealed for this question.
    private var hintRevealed: Bool { hint.active && hint.revealed }

    /// The shared ending sound (rime) highlighted on hint for rhyming / word
    /// families. Derived from the family tag ("-at" → "at") or the target word's
    /// last two letters.
    private var sharedRime: String {
        if let family = content["family"]?.replacingOccurrences(of: "-", with: ""), !family.isEmpty {
            return family.lowercased()
        }
        let target = (content["target"] ?? "").lowercased()
        return target.count >= 2 ? String(target.suffix(2)) : target
    }

    private var englishChoiceStyle: ChoiceStyle { template == "letter_recognition" ? .letter : .word }
    private var fallbackChoices: [String] { if case let .multipleChoice(options, _) = question.kind { options } else { [] } }
    private var chipValues: [String] { splitComma(content["chips"]).isEmpty ? choices : splitComma(content["chips"]) }
    private var tokenValues: [String] { splitComma(content["tokens"]).isEmpty ? choices : splitComma(content["tokens"]) }
    private var sequenceCards: [String] { splitComma(content["cards"]).isEmpty ? choices : splitComma(content["cards"]) }
    private var letterChips: [String] { splitComma(content["letters"]).isEmpty ? choices : splitComma(content["letters"]) }
    /// Pairs for the memory-match game, encoded as "front|back,front|back".
    private var memoryPairs: [(String, String)] {
        splitComma(content["pairs"]).compactMap { entry in
            let parts = entry.split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces) }
            guard parts.count == 2 else { return nil }
            return (parts[0], parts[1])
        }
    }
    /// Items for the category-sort game, encoded as "label|bucket,label|bucket".
    private var sortItems: [(label: String, bucket: String)] {
        splitComma(content["items"]).compactMap { entry in
            let parts = entry.split(separator: "|").map { $0.trimmingCharacters(in: .whitespaces) }
            guard parts.count == 2 else { return nil }
            return (parts[0], parts[1])
        }
    }
    private var visualSequence: String { (content["sequence"] ?? question.prompt).replacingOccurrences(of: ",", with: "  ").replacingOccurrences(of: "blank", with: "__") }

    private func equationLabel(_ value: String?) -> some View {
        Text(value ?? "")
            .font(.system(size: 22, weight: .heavy, design: .rounded))
            .foregroundStyle(DS.Color.textPrimary)
    }

    private func split(_ value: String?) -> [String] { (value ?? "").split(separator: " ").map(String.init) }
    private func splitComma(_ value: String?) -> [String] { (value ?? "").split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty } }
    private func int(_ value: String?) -> Int { Int((value ?? "0").filter { $0.isNumber }) ?? 0 }
    private func signedInt(_ value: String?) -> Int { Int(value ?? "0") ?? int(value) }
    private func totalObjects(_ value: String?) -> Int { Int((value ?? "0").filter { $0.isNumber }) ?? 0 }
    /// Extracts the leading emoji from a content value like "🐸x12" so the
    /// grouping buckets show the same object the prompt mentions.
    private func objectEmoji(_ value: String?) -> String {
        guard let value, let x = value.firstIndex(of: "x") else { return "🐟" }
        let emoji = String(value[..<x]).trimmingCharacters(in: .whitespaces)
        return emoji.isEmpty ? "🐟" : emoji
    }
    private func displayPattern(_ pattern: String) -> String { pattern.replacingOccurrences(of: "__", with: "▢").replacingOccurrences(of: "_", with: "▢") }

    private func assembledAnswer(from tokens: [String]) -> String? {
        guard !tokens.isEmpty else { return nil }
        if template == "unscramble_word" || template == "missing_letter" || template == "fill_missing_letters" || template == "missing_number_equation" {
            return tokens.joined()
        }
        if template == "sequencing" { return tokens.joined(separator: " > ") }
        return tokens.joined(separator: " ")
    }
}

extension String {
    var snakeKey: String {
        lowercased().replacingOccurrences(of: " ", with: "_").replacingOccurrences(of: "-", with: "_")
    }
}

// MARK: - Choice Style

private enum ChoiceStyle { case word, letter, number, emoji }

private extension String {
    /// Drops a single trailing period (used for vocab title/subtext copy).
    var strippedTrailingPeriod: String {
        hasSuffix(".") ? String(dropLast()) : self
    }
}
private struct ChoiceStyleKey: EnvironmentKey { static let defaultValue: ChoiceStyle = .word }
private extension EnvironmentValues {
    var choiceStyle: ChoiceStyle {
        get { self[ChoiceStyleKey.self] }
        set { self[ChoiceStyleKey.self] = newValue }
    }
}

// MARK: - Universal Hint State

/// Shared hint state for any choice-based question. Lifted out of the renderer
/// so the hint button can live in the lesson's bottom key row, mirroring the
/// unscramble hint. When `revealed`, the renderer fades one wrong choice.
@Observable
final class QuestionHintState {
    var active: Bool = false
    var available: Bool = false
    var revealed: Bool = false
    var glow: Bool = false
    var fadedChoice: String? = nil
    var isLocked: Bool = false
    var questionKey: String = ""
}

struct QuestionHintButton: View {
    @Bindable var state: QuestionHintState

    var body: some View {
        let glowActive = state.available && !state.revealed
        return Button {
            guard !state.isLocked else { return }
            withAnimation(.spring(duration: 0.3)) {
                state.revealed = true
                state.glow = false
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 11, weight: .heavy))
                Text("Hint!")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background(
                state.revealed
                    ? DS.Color.accent
                    : Color(red: 1.0, green: 0.78, blue: 0.10)
            )
            .clipShape(.capsule)
            .shadow(
                color: glowActive
                    ? Color.yellow.opacity(state.glow ? 0.35 : 0.15)
                    : Color.black.opacity(0.08),
                radius: glowActive ? (state.glow ? 8 : 5) : 4,
                y: 2
            )
            .scaleEffect(glowActive && state.glow ? 1.03 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(state.isLocked || state.revealed)
    }
}

// MARK: - Flow Row (Answer Chips)

struct FlowRow: View {
    let items: [String]
    let selected: String?
    let locked: Bool
    var fadedChoice: String? = nil
    let action: (String) -> Void
    @Environment(\.choiceStyle) private var style

    var body: some View {
        // With exactly two choices, use a fixed 2-column grid so they sit
        // side-by-side in a single clean row rather than an uneven adaptive layout.
        let columns: [GridItem] = items.count == 2
            ? [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
            : [GridItem(.adaptive(minimum: minWidth), spacing: 12)]
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                Button {
                    withAnimation(.spring(duration: 0.2)) {
                        action(item)
                    }
                } label: {
                    Text(item)
                        .font(font)
                        .foregroundStyle(DS.Color.textPrimary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, minHeight: height)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            selected == item
                                ? Color(red: 0.996, green: 0.994, blue: 0.992)
                                : Color(red: 0.996, green: 0.994, blue: 0.992)
                        )
                        .clipShape(.rect(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    selected == item ? DS.Color.accent : Color.clear,
                                    lineWidth: selected == item ? 2.5 : 0
                                )
                        )
                        .shadow(
                            color: selected == item ? DS.Color.accent.opacity(0.55) : DS.Color.accent.opacity(0.28),
                            radius: selected == item ? 16 : 11,
                            x: 0,
                            y: selected == item ? 5 : 3
                        )
                }
                .buttonStyle(.plain)
                .opacity(fadedChoice == item ? 0.28 : 1)
                .scaleEffect(selected == item ? 1.08 : 1.0)
                .animation(.spring(response: 0.22, dampingFraction: 0.45), value: selected)
                .animation(.easeInOut(duration: 0.3), value: fadedChoice)
            }
        }
    }

    private var minWidth: CGFloat {
        switch style {
        case .letter: 72
        case .emoji: 110
        default: 96
        }
    }
    private var height: CGFloat {
        switch style {
        case .letter: 78
        case .emoji: 110
        default: 66
        }
    }
    private var font: Font {
        switch style {
        case .letter: .system(size: 36, weight: .heavy, design: .rounded)
        case .number: .system(size: 26, weight: .heavy, design: .rounded)
        case .word: .system(size: 22, weight: .heavy, design: .rounded)
        case .emoji: .system(size: 44)
        }
    }
}

// MARK: - Math Visual Components

struct EmojiCounterRow: View {
    let items: [String]
    let hint: Bool
    var fixedColumns: Int? = nil

    var body: some View {
        if let cols = fixedColumns, cols > 0 {
            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(52), spacing: 10), count: cols),
                spacing: 10
            ) {
                ForEach(Array(items.enumerated()), id: \.offset) { i, item in
                    cell(item: item, index: i)
                }
            }
            .frame(maxWidth: .infinity)
        } else {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 48))], spacing: 10) {
                ForEach(Array(items.enumerated()), id: \.offset) { i, item in
                    cell(item: item, index: i)
                }
            }
        }
    }

    private func cell(item: String, index i: Int) -> some View {
        Text(item == "◌" ? "○" : item)
            .font(.system(size: 36))
            .opacity(item == "◌" ? 0.24 : 1)
            .frame(width: 52, height: 52)
            .background(
                hint
                    ? DS.Color.accentSoft.opacity(i == 0 ? 1 : 0.38)
                    : Color(red: 0.996, green: 0.994, blue: 0.992)
            )
            .clipShape(.circle)
            .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 1)
    }
}

struct AdditionGroupsCard: View {
    let left: [String]
    let right: [String]
    let equation: String?

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                EmojiCounterRow(items: left, hint: false)
                Text("+")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(DS.Color.accent)
                EmojiCounterRow(items: right, hint: false)
            }
            if let equation {
                Text(equation)
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(DS.Color.textPrimary)
            }
        }
    }
}

struct NumberLineCard: View {
    let start: Int
    let jump: Int
    let selected: String?
    let locked: Bool
    let action: (String) -> Void

    private let count = 13   // ticks 0...12

    /// The marker sits at `start` until the child picks a landing tick, then hops
    /// there. Defaults to start when nothing is selected.
    private var markerValue: Int { Int(selected ?? "") ?? start }

    var body: some View {
        VStack(spacing: 14) {
            GeometryReader { geo in
                let cellW = geo.size.width / CGFloat(count)
                ZStack(alignment: .topLeading) {
                    // Hopping marker above the line.
                    Text("🐸")
                        .font(.system(size: 24))
                        .frame(width: cellW)
                        .offset(x: CGFloat(markerValue) * cellW, y: 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.45), value: markerValue)

                    HStack(spacing: 0) {
                        ForEach(0...12, id: \.self) { n in tick(n, cellW: cellW) }
                    }
                    .offset(y: 30)
                }
            }
            .frame(height: 78)

            Text("Start at \(start)  →  jump \(jump >= 0 ? "+" : "")\(jump)")
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(DS.Color.accent)
        }
    }

    private func tick(_ n: Int, cellW: CGFloat) -> some View {
        Button {
            action("\(n)")
        } label: {
            VStack(spacing: 6) {
                Circle()
                    .fill(selected == "\(n)" ? DS.Color.accent : (n == start ? DS.Color.accentSoft : DS.Color.border))
                    .frame(width: selected == "\(n)" ? 20 : 10, height: selected == "\(n)" ? 20 : 10)
                Text("\(n)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(DS.Color.textPrimary)
            }
            .frame(width: cellW)
        }
        .buttonStyle(.plain)
        .disabled(locked)
        .scaleEffect(selected == "\(n)" ? 1.15 : 1)
        .animation(.spring(duration: 0.2), value: selected)
    }
}

/// Interactive ten-frame: the first `filled` dots are fixed; the child taps the
/// empty slots to add dots. Filling the right number to reach ten answers it.
struct TenFrameCard: View {
    let filled: Int
    let need: Int
    let locked: Bool
    let report: (String?) -> Void

    @State private var added: Set<Int> = []

    var body: some View {
        VStack(spacing: 14) {
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(44), spacing: 8), count: 5), spacing: 8) {
                ForEach(0..<10, id: \.self) { i in slot(i) }
            }
            Text("Tap the empty dots to make 10")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(DS.Color.textSecondary)
        }
    }

    private func slot(_ i: Int) -> some View {
        let isPrefilled = i < filled
        let isAdded = added.contains(i)
        let isFilled = isPrefilled || isAdded
        return Button {
            guard !locked, !isPrefilled else { return }
            withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                if isAdded { added.remove(i) } else { added.insert(i) }
            }
            report(added.isEmpty ? nil : String(added.count))
        } label: {
            Circle()
                .fill(isFilled ? DS.Color.accent : DS.Color.accentMid)
                .frame(width: 42, height: 42)
                .overlay(
                    Circle().stroke(
                        DS.Color.accent.opacity(isFilled ? 0 : 0.8),
                        lineWidth: 2.5
                    )
                )
                .scaleEffect(isAdded ? 1.08 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(locked || isPrefilled)
    }
}

/// Build-the-array: the child taps + / − to add rows and columns up to the
/// target dimensions, watching the product grow, before confirming the count.
struct ArrayBuilderCard: View {
    let rows: Int
    let columns: Int
    let item: String

    @State private var builtRows: Int = 1
    @State private var builtCols: Int = 1

    private var targetRows: Int { max(rows, 1) }
    private var targetCols: Int { max(columns, 1) }
    private var isComplete: Bool { builtRows == targetRows && builtCols == targetCols }

    /// Dot size is fixed to the TARGET dimensions so the grid doesn't jump while
    /// the child builds it up.
    private var itemSize: CGFloat {
        switch max(targetRows, targetCols) {
        case 0...4: return 30
        case 5...6: return 24
        case 7...8: return 19
        default: return 15
        }
    }
    private var gridSpacing: CGFloat { max(targetRows, targetCols) >= 7 ? 5 : 8 }

    var body: some View {
        VStack(spacing: 14) {
            VStack(spacing: gridSpacing) {
                ForEach(0..<builtRows, id: \.self) { _ in
                    HStack(spacing: gridSpacing) {
                        ForEach(0..<builtCols, id: \.self) { _ in
                            Text(item).font(.system(size: itemSize))
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
            }
            .frame(minHeight: itemSize + 8)

            HStack(spacing: 14) {
                stepper(label: "Rows", value: builtRows, target: targetRows) { builtRows = $0 }
                stepper(label: "Columns", value: builtCols, target: targetCols) { builtCols = $0 }
            }

            Text("\(builtRows) × \(builtCols) = \(builtRows * builtCols)")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(isComplete ? DS.Color.accent : DS.Color.textSecondary)
                .padding(.top, 2)
        }
    }

    private func stepper(label: String, value: Int, target: Int, set: @escaping (Int) -> Void) -> some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(DS.Color.textSecondary)
            HStack(spacing: 10) {
                stepButton("minus") { if value > 1 { withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) { set(value - 1) } } }
                Text("\(value)")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(DS.Color.textPrimary)
                    .frame(minWidth: 24)
                stepButton("plus") { if value < target { withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) { set(value + 1) } } }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(red: 0.996, green: 0.994, blue: 0.992))
        .clipShape(.rect(cornerRadius: 16))
        .shadow(color: DS.Color.accent.opacity(0.12), radius: 6, y: 2)
    }

    private func stepButton(_ system: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 14, weight: .heavy))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(DS.Color.accent)
                .clipShape(.circle)
        }
        .buttonStyle(.plain)
    }
}

/// Tap-to-distribute division: tap items in the tray to send them one at a time,
/// round-robin, into the bowls until every item is shared evenly. Completing an
/// even distribution reports the per-bowl count as the answer.
struct DivisionShareCard: View {
    let total: Int
    let buckets: Int
    let item: String
    let locked: Bool
    let report: (String?) -> Void

    @State private var placed: [Int] = []
    @State private var remaining: Int = -1   // -1 = not yet initialized

    private var bucketCount: Int { max(buckets, 1) }
    private var perGroup: Int { total / bucketCount }
    private var nextBucket: Int { (total - remaining) % bucketCount }

    var body: some View {
        VStack(spacing: 16) {
            if remaining > 0 {
                VStack(spacing: 8) {
                    Text("Tap an item to share it — \(remaining) left")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(DS.Color.accent)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44), spacing: 8)], spacing: 8) {
                        ForEach(0..<max(remaining, 0), id: \.self) { _ in
                            Button { shareOne() } label: {
                                Text(item)
                                    .font(.system(size: 30))
                                    .frame(width: 44, height: 44)
                                    .background(Color(red: 0.996, green: 0.994, blue: 0.992))
                                    .clipShape(.circle)
                                    .shadow(color: DS.Color.accent.opacity(0.18), radius: 4, y: 1)
                            }
                            .buttonStyle(.plain)
                            .disabled(locked)
                        }
                    }
                }
            } else if remaining == 0 {
                Text("All shared evenly! Tap Check.")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(DS.Color.accent)
            }

            HStack(alignment: .top, spacing: 10) {
                ForEach(0..<bucketCount, id: \.self) { b in bowl(b) }
            }
        }
        .onAppear {
            guard remaining == -1 else { return }
            placed = Array(repeating: 0, count: bucketCount)
            remaining = total
        }
    }

    private func bowl(_ b: Int) -> some View {
        let count = b < placed.count ? placed[b] : 0
        let isNext = remaining > 0 && b == nextBucket
        return VStack(spacing: 6) {
            Text("🥣").font(.system(size: 34))
            Text(String(repeating: item, count: count))
                .font(.system(size: 18))
                .multilineTextAlignment(.center)
                .frame(minHeight: 24)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(Color(red: 0.996, green: 0.994, blue: 0.992))
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isNext ? DS.Color.accent : Color.clear, style: StrokeStyle(lineWidth: 2, dash: [6, 5]))
        )
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 1)
    }

    private func shareOne() {
        guard !locked, remaining > 0 else { return }
        let target = nextBucket
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            if target < placed.count { placed[target] += 1 }
            remaining -= 1
        }
        report(currentAnswer())
    }

    /// nil until everything is placed; then the per-bowl count when the split is
    /// even (always, via round-robin), else a sentinel that will be marked wrong.
    private func currentAnswer() -> String? {
        guard remaining == 0 else { return nil }
        let even = placed.allSatisfy { $0 == placed.first }
        return even ? String(perGroup) : "__unsorted__"
    }
}

/// Each element of the pattern fades/scales in one at a time before the blank is
/// revealed, so the child watches the sequence build rather than seeing it all
/// at once.
struct PatternRowCard: View {
    let sequence: String
    @State private var shown: Int = 0

    private var tokens: [String] { sequence.split(separator: " ").map(String.init).filter { !$0.isEmpty } }

    var body: some View {
        HStack(spacing: 10) {
            ForEach(Array(tokens.enumerated()), id: \.offset) { i, tok in
                Text(tok)
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(tok == "__" ? DS.Color.accent : DS.Color.textPrimary)
                    .opacity(i < shown ? 1 : 0)
                    .scaleEffect(i < shown ? 1 : 0.4)
            }
        }
        .multilineTextAlignment(.center)
        .onAppear {
            shown = 0
            for i in 0..<tokens.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.18 * Double(i)) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { shown = i + 1 }
                }
            }
        }
    }
}

struct FractionBarCard: View {
    let parts: Int
    let filled: Int

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<max(parts, 1), id: \.self) { i in
                Rectangle()
                    .fill(i < filled ? DS.Color.accent : DS.Color.accentSoft)
                    .frame(height: 64)
            }
        }
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            Text("\(filled)/\(parts)")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(DS.Color.textPrimary)
        )
    }
}

/// The hour hand swings into place first, then the minute hand, giving a brief
/// animated reveal that reinforces reading order (hour, then minute).
struct ClockCard: View {
    let hour: Int
    let minute: Int

    @State private var hourAngle: Double = 0
    @State private var minuteAngle: Double = 0

    private var targetHour: Double { Double(hour % 12) * 30 + Double(minute) / 60 * 30 }
    private var targetMinute: Double { Double(minute) * 6 }

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(red: 0.996, green: 0.994, blue: 0.992))
                .frame(width: 160, height: 160)
            Circle()
                .stroke(DS.Color.border, lineWidth: 6)
                .frame(width: 150, height: 150)

            // Hour numerals positioned around the dial. Each numeral sits at the
            // top of a clock-sized frame that is rotated into place, then the
            // numeral itself is counter-rotated so it always reads upright.
            ForEach(1...12, id: \.self) { n in
                VStack(spacing: 0) {
                    Text("\(n)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(DS.Color.textSecondary)
                        .rotationEffect(.degrees(Double(n) * -30))
                    Spacer(minLength: 0)
                }
                .frame(width: 126, height: 126)
                .rotationEffect(.degrees(Double(n) * 30))
            }

            Rectangle()
                .fill(DS.Color.textPrimary)
                .frame(width: 5, height: 42)
                .offset(y: -21)
                .rotationEffect(.degrees(hourAngle))

            Rectangle()
                .fill(DS.Color.accent)
                .frame(width: 4, height: 54)
                .offset(y: -27)
                .rotationEffect(.degrees(minuteAngle))

            Circle()
                .fill(DS.Color.accent)
                .frame(width: 12, height: 12)
        }
        .onAppear {
            hourAngle = 0
            minuteAngle = 0
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) { hourAngle = targetHour }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) { minuteAngle = targetMinute }
            }
        }
    }
}

// MARK: - English Visual Components

struct MatchingCardSet: View {
    let left: String
    let right: [String]
    let selected: String?
    let locked: Bool
    var fadedChoice: String? = nil
    let action: (String) -> Void

    var body: some View {
        HStack(spacing: 14) {
            Text(left)
                .font(.system(size: 52, weight: .heavy, design: .rounded))
                .frame(maxWidth: .infinity, minHeight: 110)
                .background(Color(red: 0.996, green: 0.994, blue: 0.992))
                .clipShape(.rect(cornerRadius: 22))
                .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)

            FlowRow(items: right, selected: selected, locked: locked, fadedChoice: fadedChoice, action: action)
                .environment(\.choiceStyle, .letter)
        }
    }
}

struct StoryEmojiStrip: View {
    let emojis: String
    let text: String

    var body: some View {
        VStack(spacing: 12) {
            Text(emojis)
                .font(.system(size: 38))
            Text(text)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(DS.Color.textPrimary)
                .multilineTextAlignment(.center)
                .padding()
                .background(Color(red: 0.996, green: 0.994, blue: 0.992))
                .clipShape(.rect(cornerRadius: 16))
                .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
        }
    }
}

// MARK: - Unscramble Word Card

/// Shared, hoistable state for the unscramble interaction. Lifting this out of
/// `UnscrambleCard` lets the back and hint buttons render in the parent's key
/// row (bottom corners) while the card keeps owning the letter tray.
@Observable
final class UnscrambleState {
    var active: Bool = false
    var picked: [Int] = []
    var letters: [String] = []
    var correctCount: Int = 0
    var hintRevealed: Bool = false
    var hintAvailable: Bool = false
    var hintGlow: Bool = false
    var isLocked: Bool = false
}

struct UnscrambleBackButton: View {
    @Bindable var state: UnscrambleState

    var body: some View {
        Button {
            guard !state.isLocked, !state.picked.isEmpty else { return }
            withAnimation(.spring(duration: 0.2)) { state.picked.removeLast() }
        } label: {
            Image(systemName: "delete.left.fill")
                .font(.system(size: 18, weight: .heavy))
                .foregroundStyle(state.picked.isEmpty ? DS.Color.textTertiary.opacity(0.4) : DS.Color.accent)
                .frame(width: 46, height: 46)
                .background(Color(red: 0.996, green: 0.994, blue: 0.992))
                .clipShape(.capsule)
                .shadow(color: DS.Color.accent.opacity(state.picked.isEmpty ? 0.08 : 0.28), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(state.picked.isEmpty || state.isLocked)
    }
}

struct UnscrambleHintButton: View {
    @Bindable var state: UnscrambleState

    var body: some View {
        let glowActive = state.hintAvailable && !state.hintRevealed
        return Button {
            guard !state.isLocked else { return }
            withAnimation(.spring(duration: 0.3)) {
                state.hintRevealed.toggle()
                state.hintGlow = false
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 13, weight: .heavy))
                Text("Hint!")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                state.hintRevealed
                    ? DS.Color.accent
                    : Color(red: 1.0, green: 0.78, blue: 0.10)
            )
            .clipShape(.capsule)
            .shadow(
                color: glowActive
                    ? Color.yellow.opacity(state.hintGlow ? 0.85 : 0.25)
                    : Color.black.opacity(0.08),
                radius: glowActive ? (state.hintGlow ? 16 : 6) : 4,
                y: 2
            )
            .scaleEffect(glowActive && state.hintGlow ? 1.06 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(state.isLocked)
    }
}

struct UnscrambleCard: View {
    let letters: [String]            // chips in their scrambled order
    let correctAnswer: String        // e.g. "monkey"
    let emoji: String?
    @Binding var selectedAnswer: String?
    let isLocked: Bool
    @Bindable var state: UnscrambleState

    private var correctLetters: [String] { correctAnswer.map { String($0) } }

    var body: some View {
        VStack(spacing: 18) {
            if let emoji {
                Text(emoji).font(.system(size: 58))
            }

            // Assembled answer row — tap a filled slot to send the letter back
            HStack(spacing: 8) {
                ForEach(0..<max(correctLetters.count, 1), id: \.self) { i in
                    slotView(at: i)
                }
            }

            // Letter tray. The back + hint buttons now live in the parent's key
            // row at the bottom corners.
            chipsView
                .frame(maxWidth: .infinity)
        }
        .onAppear {
            state.active = true
            state.letters = letters
            state.correctCount = correctLetters.count
            state.picked = []
            state.hintRevealed = false
            state.hintAvailable = false
            state.hintGlow = false
            state.isLocked = isLocked
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                guard state.active, !state.hintRevealed else { return }
                state.hintAvailable = true
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                    state.hintGlow = true
                }
            }
        }
        .onDisappear { state.active = false }
        .onChange(of: isLocked) { _, newValue in state.isLocked = newValue }
        .onChange(of: state.picked) { _, _ in
            let joined = state.picked.map { letters[$0] }.joined()
            selectedAnswer = joined.isEmpty ? nil : joined
        }
    }

    private func slotView(at i: Int) -> some View {
        let hasLetter = i < state.picked.count
        let letter = hasLetter ? letters[state.picked[i]] : nil
        return Button {
            guard !isLocked, hasLetter else { return }
            withAnimation(.spring(duration: 0.2)) { state.picked.remove(at: i) }
        } label: {
            // Letter sits on top of a simple underline — no card, no orange border.
            VStack(spacing: 6) {
                Text(letter ?? " ")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(DS.Color.textPrimary)
                    .frame(height: 40)
                Capsule()
                    .fill(DS.Color.accent)
                    .frame(width: 34, height: 4)
            }
            .frame(width: 42)
        }
        .buttonStyle(.plain)
        .disabled(!hasLetter || isLocked)
    }

    private var chipsView: some View {
        // Fit up to 6 chips per row.
        let columns = min(max(letters.count, 1), 6)
        return LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: columns),
            spacing: 10
        ) {
            ForEach(Array(letters.enumerated()), id: \.offset) { idx, letter in
                chipView(idx: idx, letter: letter)
            }
        }
    }

    private func chipView(idx: Int, letter: String) -> some View {
        let isUsed = state.picked.contains(idx)
        let hintNumber: Int? = {
            guard state.hintRevealed, !isUsed else { return nil }
            return (correctLetters.firstIndex(of: letter)).map { $0 + 1 }
        }()

        return Button {
            guard !isLocked, !isUsed, state.picked.count < correctLetters.count else { return }
            withAnimation(.spring(duration: 0.2)) { state.picked.append(idx) }
        } label: {
            ZStack(alignment: .topTrailing) {
                Text(letter)
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(isUsed ? DS.Color.textTertiary : DS.Color.textPrimary)
                    .frame(maxWidth: .infinity, minHeight: 58)
                    .background(Color(red: 0.996, green: 0.994, blue: 0.992))
                    .clipShape(.rect(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isUsed ? DS.Color.accent : Color.clear, lineWidth: isUsed ? 2 : 0)
                    )
                    .shadow(
                        color: isUsed ? DS.Color.accent.opacity(0.3) : DS.Color.accent.opacity(0.4),
                        radius: isUsed ? 12 : 14,
                        y: 3
                    )
                    .opacity(isUsed ? 0.45 : 1)

                if let hintNumber {
                    Text("\(hintNumber)")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 20, height: 20)
                        .background(DS.Color.accent)
                        .clipShape(Circle())
                        .offset(x: 6, y: -6)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isUsed || isLocked)
    }
}

// MARK: - True or False Math Statement (concrete emoji visual)

/// Shows the equation as concrete emoji groups (e.g. 6 + 2 = 9) so the child can
/// verify the statement visually before judging True or False.
struct TrueFalseMathCard: View {
    let statement: String        // e.g. "6 + 2 = 9"
    let choices: [String]
    let selected: String?
    let locked: Bool
    var fadedChoice: String? = nil
    let onSelect: (String) -> Void

    private let dot = "🔵"

    private var parsed: (a: Int, op: String, b: Int, c: Int)? {
        let parts = statement.split(separator: " ").map(String.init)
        guard parts.count == 5, parts[3] == "=",
              let a = Int(parts[0]), let b = Int(parts[2]), let c = Int(parts[4]) else { return nil }
        return (a, parts[1], b, c)
    }

    var body: some View {
        VStack(spacing: 18) {
            if let p = parsed {
                VStack(spacing: 12) {
                    HStack(spacing: 10) {
                        emojiGroup(p.a)
                        Text(p.op).font(.system(size: 28, weight: .heavy, design: .rounded)).foregroundStyle(DS.Color.accent)
                        emojiGroup(p.b)
                    }
                    Text("=").font(.system(size: 24, weight: .heavy, design: .rounded)).foregroundStyle(DS.Color.textSecondary)
                    emojiGroup(p.c)
                }
                Text(statement)
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundStyle(DS.Color.textPrimary)
            } else {
                Text(statement)
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundStyle(DS.Color.textPrimary)
            }

            FlowRow(items: choices, selected: selected, locked: locked, fadedChoice: fadedChoice, action: onSelect)
                .environment(\.choiceStyle, .word)
        }
    }

    private func emojiGroup(_ n: Int) -> some View {
        let cols = min(max(n, 1), 5)
        return LazyVGrid(columns: Array(repeating: GridItem(.fixed(26), spacing: 4), count: cols), spacing: 4) {
            ForEach(0..<max(n, 0), id: \.self) { _ in
                Text(dot).font(.system(size: 22))
            }
        }
        .fixedSize()
        .padding(8)
        .background(DS.Color.accentSoft.opacity(0.4))
        .clipShape(.rect(cornerRadius: 12))
    }
}

// MARK: - Rhyme / Word Family Grid (shared-ending highlight on hint)

/// Choice grid for rhyming and word families. When the hint is revealed, the
/// shared ending letters (rime) are colored and underlined across the choices
/// that share them, reinforcing the sound pattern.
struct RhymeFamilyGrid: View {
    let choices: [String]
    let rime: String
    let selected: String?
    let locked: Bool
    var fadedChoice: String? = nil
    let revealed: Bool
    let onSelect: (String) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 12)], spacing: 12) {
            ForEach(choices, id: \.self) { choice in button(choice) }
        }
    }

    private func highlights(_ word: String) -> Bool {
        revealed && !rime.isEmpty && word.lowercased().hasSuffix(rime) && word.count > rime.count
    }

    private func styled(_ word: String) -> Text {
        guard highlights(word) else {
            return Text(word).foregroundColor(DS.Color.textPrimary)
        }
        let splitIndex = word.index(word.endIndex, offsetBy: -rime.count)
        let head = String(word[..<splitIndex])
        let tail = String(word[splitIndex...])
        return Text(head).foregroundColor(DS.Color.textPrimary)
            + Text(tail).foregroundColor(DS.Color.accent).underline()
    }

    private func button(_ choice: String) -> some View {
        let isSelected = selected == choice
        return Button {
            guard !locked else { return }
            withAnimation(.spring(duration: 0.2)) { onSelect(choice) }
        } label: {
            styled(choice)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 66)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(red: 0.996, green: 0.994, blue: 0.992))
                .clipShape(.rect(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? DS.Color.accent : Color.clear, lineWidth: isSelected ? 2.5 : 0)
                )
                .shadow(
                    color: isSelected ? DS.Color.accent.opacity(0.55) : DS.Color.accent.opacity(0.28),
                    radius: isSelected ? 16 : 11, x: 0, y: isSelected ? 5 : 3
                )
        }
        .buttonStyle(.plain)
        .opacity(fadedChoice == choice ? 0.28 : 1)
        .scaleEffect(isSelected ? 1.08 : 1.0)
        .animation(.spring(response: 0.22, dampingFraction: 0.45), value: selected)
        .animation(.easeInOut(duration: 0.3), value: fadedChoice)
        .animation(.easeInOut(duration: 0.3), value: revealed)
    }
}

// MARK: - Punctuation Choice (reacting mascot)

/// A mascot face reacts to the punctuation being considered — curious for "?",
/// excited for "!", calm for "." — reinforcing sentence tone over rote symbols.
struct PunctuationCard: View {
    let sentence: String
    let choices: [String]
    let selected: String?
    let locked: Bool
    var fadedChoice: String? = nil
    let onSelect: (String) -> Void

    private func face(for punct: String?) -> String {
        switch punct {
        case "?": return "🤔"
        case "!": return "😃"
        case ".": return "🙂"
        default: return "😐"
        }
    }

    var body: some View {
        VStack(spacing: 18) {
            Text(face(for: selected))
                .font(.system(size: 64))
                .scaleEffect(selected == nil ? 1.0 : 1.1)
                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: selected)

            Text(sentence + (selected ?? " __"))
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundStyle(DS.Color.textPrimary)
                .multilineTextAlignment(.center)

            FlowRow(items: choices, selected: selected, locked: locked, fadedChoice: fadedChoice, action: onSelect)
                .environment(\.choiceStyle, .word)
        }
    }
}

// MARK: - Missing Letter Card

/// Renders a word with one or more blank slots. Tapping an answer choice fills
/// the blank with the chosen letter(s) and highlights the selected choice, the
/// same way the number-comparison choices give visual feedback.
struct MissingLetterCard: View {
    let pattern: String          // e.g. "c_t", "sh_p", or "b__k"
    let choices: [String]
    let emoji: String?
    let selected: String?
    let locked: Bool
    var fadedChoice: String? = nil
    let onSelect: (String) -> Void

    private struct Segment: Identifiable {
        let id = UUID()
        let text: String
        let isBlank: Bool
    }

    /// Splits the pattern into literal letters and blank runs (consecutive
    /// underscores collapse into a single blank — "b__k" has one blank).
    private var segments: [Segment] {
        var result: [Segment] = []
        var index = pattern.startIndex
        while index < pattern.endIndex {
            if pattern[index] == "_" {
                while index < pattern.endIndex && pattern[index] == "_" {
                    index = pattern.index(after: index)
                }
                result.append(Segment(text: "", isBlank: true))
            } else {
                result.append(Segment(text: String(pattern[index]), isBlank: false))
                index = pattern.index(after: index)
            }
        }
        return result
    }

    var body: some View {
        VStack(spacing: 18) {
            if let emoji {
                Text(emoji).font(.system(size: 52))
            }

            HStack(spacing: 6) {
                ForEach(segments) { segment in
                    if segment.isBlank {
                        blankBox
                    } else {
                        Text(segment.text)
                            .font(.system(size: 40, weight: .heavy, design: .rounded))
                            .foregroundStyle(DS.Color.textPrimary)
                    }
                }
            }

            FlowRow(items: choices, selected: selected, locked: locked, fadedChoice: fadedChoice, action: onSelect)
                .environment(\.choiceStyle, .letter)
        }
    }

    private var blankBox: some View {
        Text(selected ?? "")
            .font(.system(size: 40, weight: .heavy, design: .rounded))
            .foregroundStyle(DS.Color.accent)
            .frame(minWidth: 50, minHeight: 60)
            .background(DS.Color.accentSoft.opacity(selected == nil ? 0.35 : 0.7))
            .clipShape(.rect(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        DS.Color.accent,
                        style: StrokeStyle(lineWidth: 2.5, dash: selected == nil ? [6, 5] : [])
                    )
            )
            .scaleEffect(selected == nil ? 1.0 : 1.06)
            .animation(.spring(response: 0.25, dampingFraction: 0.55), value: selected)
    }
}

// MARK: - Letter-to-Sound Match (Beginning Sounds — no audio)

/// Shows the target letter big and bold, then emoji-only choices. The child taps
/// the picture whose word starts with that letter's sound. Choices carry no
/// written word, so the exercise can't be solved by reading.
struct LetterSoundMatchCard: View {
    let letter: String           // e.g. "b"
    let choices: [String]        // emoji-only, e.g. "🐻"
    let selected: String?
    let locked: Bool
    var fadedChoice: String? = nil
    let action: (String) -> Void

    private var displayLetter: String {
        let trimmed = letter.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "?" : trimmed.uppercased()
    }

    var body: some View {
        VStack(spacing: 22) {
            Text(displayLetter)
                .font(.system(size: 78, weight: .heavy, design: .rounded))
                .foregroundStyle(DS.Color.accent)
                .frame(width: 132, height: 132)
                .background(DS.Color.accentSoft.opacity(0.6))
                .clipShape(.rect(cornerRadius: 28))
                .shadow(color: DS.Color.accent.opacity(0.18), radius: 10, y: 4)

            HStack(spacing: 12) {
                ForEach(choices, id: \.self) { choice in
                    EmojiSoundChoiceCard(
                        emoji: choice,
                        isSelected: selected == choice,
                        faded: fadedChoice == choice,
                        locked: locked
                    ) { action(choice) }
                }
            }
        }
    }
}

struct EmojiSoundChoiceCard: View {
    let emoji: String
    let isSelected: Bool
    let faded: Bool
    let locked: Bool
    let action: () -> Void

    @State private var bounce = false

    var body: some View {
        Text(emoji)
            .font(.system(size: 52))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color(red: 0.996, green: 0.994, blue: 0.992))
            .clipShape(.rect(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? DS.Color.accent : Color.clear, lineWidth: 2.5)
            )
            .shadow(
                color: isSelected ? DS.Color.accent.opacity(0.45) : DS.Color.accent.opacity(0.18),
                radius: isSelected ? 14 : 9,
                y: 3
            )
            .opacity(faded ? 0.28 : 1)
            .scaleEffect(bounce ? 1.1 : (isSelected ? 1.04 : 1.0))
            .contentShape(.rect)
            .onTapGesture {
                guard !locked else { return }
                withAnimation(.spring(response: 0.16, dampingFraction: 0.45)) { bounce = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
                    withAnimation(.spring(response: 0.26, dampingFraction: 0.6)) { bounce = false }
                }
                action()
            }
            .animation(.easeInOut(duration: 0.3), value: faded)
    }
}

// MARK: - Number Comparison Card (progressive reveal)

struct NumberComparisonCard: View {
    /// One comparison card: either a large numeral (`emoji == nil`) or a counted
    /// grid of objects. `value` is the underlying quantity and the choice key.
    struct Side {
        let value: Int
        let emoji: String?
    }

    let left: Side
    let right: Side
    let selected: String?
    let locked: Bool
    var fadedChoice: String? = nil
    let action: (String) -> Void

    private var greater: Int { max(left.value, right.value) }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            sideCard(left)
            Text("or")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(DS.Color.accent)
            sideCard(right)
        }
    }

    /// After any selection, the greater quantity grows and the smaller shrinks
    /// so the child sees "greater" reinforced, not just a right/wrong mark.
    private func revealScale(for value: Int) -> CGFloat {
        guard selected != nil else { return 1.0 }
        return value == greater ? 1.12 : 0.88
    }

    private func sideCard(_ side: Side) -> some View {
        let key = String(side.value)
        let isSelected = selected == key
        return Button {
            guard !locked else { return }
            action(key)
        } label: {
            Group {
                if let emoji = side.emoji {
                    objectGrid(emoji: emoji, count: side.value)
                } else {
                    Text(key)
                        .font(.system(size: 46, weight: .heavy, design: .rounded))
                        .foregroundStyle(DS.Color.textPrimary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 140)
            .padding(.vertical, 14)
            .padding(.horizontal, 10)
            .background(Color(red: 0.996, green: 0.994, blue: 0.992))
            .clipShape(.rect(cornerRadius: 22))
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(isSelected ? DS.Color.accent : Color.clear, lineWidth: 2.5)
            )
            .shadow(
                color: isSelected ? DS.Color.accent.opacity(0.45) : DS.Color.accent.opacity(0.2),
                radius: isSelected ? 14 : 9,
                y: 3
            )
        }
        .buttonStyle(.plain)
        .disabled(locked)
        .opacity(fadedChoice == key ? 0.28 : 1)
        .scaleEffect(revealScale(for: side.value) * (isSelected ? 1.03 : 1.0))
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: selected)
        .animation(.easeInOut(duration: 0.3), value: fadedChoice)
    }

    /// Objects laid out in a clean 2–4 column grid so the child must count them,
    /// never a single ambiguous row.
    private func objectGrid(emoji: String, count: Int) -> some View {
        let cols = count <= 4 ? 2 : (count <= 9 ? 3 : 4)
        let glyph: CGFloat = count > 12 ? 18 : (count > 6 ? 22 : 26)
        return LazyVGrid(
            columns: Array(repeating: GridItem(.fixed(glyph + 6), spacing: 6), count: cols),
            spacing: 6
        ) {
            ForEach(0..<max(count, 1), id: \.self) { _ in
                Text(emoji).font(.system(size: glyph))
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Memory Match Card (flip-card pairs)

/// A grid of face-down cards. Tap two to flip; matching pairs stay up. When all
/// pairs are found the question is complete. Great for uppercase↔lowercase or
/// word↔picture matching.
struct MemoryMatchCard: View {
    let pairs: [(String, String)]   // (front, back) — each side becomes one card
    let locked: Bool
    let onComplete: () -> Void

    private struct Card: Identifiable {
        let id = UUID()
        let label: String
        let pairKey: Int            // cards sharing a pairKey are a match
    }

    @State private var cards: [Card] = []
    @State private var flipped: Set<UUID> = []
    @State private var matched: Set<UUID> = []
    @State private var busy: Bool = false
    @State private var wiggle: UUID? = nil

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 10), count: min(max(cards.count / 2, 2), 4))
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(cards) { card in
                cardView(card)
            }
        }
        .onAppear(perform: setup)
    }

    private func setup() {
        guard cards.isEmpty else { return }
        var built: [Card] = []
        for (i, pair) in pairs.enumerated() {
            built.append(Card(label: pair.0, pairKey: i))
            built.append(Card(label: pair.1, pairKey: i))
        }
        var rng = SeededRNG(UInt64(pairs.count + 7))
        cards = built.shuffled(using: &rng)
    }

    private func cardView(_ card: Card) -> some View {
        let isUp = flipped.contains(card.id) || matched.contains(card.id)
        let isMatched = matched.contains(card.id)
        return Button {
            tap(card)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(isUp ? Color(red: 0.996, green: 0.994, blue: 0.992) : DS.Color.accent)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isMatched ? DS.Color.accent : Color.clear, lineWidth: 2.5)
                    )
                    .shadow(color: isUp ? DS.Color.accent.opacity(0.25) : Color.black.opacity(0.06), radius: 6, y: 2)
                if isUp {
                    Text(card.label)
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundStyle(DS.Color.textPrimary)
                } else {
                    Image(systemName: "questionmark")
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
            .frame(height: 70)
            .opacity(isMatched ? 0.55 : 1)
            .scaleEffect(wiggle == card.id ? 1.08 : 1.0)
            .rotation3DEffect(.degrees(isUp ? 0 : 180), axis: (x: 0, y: 1, z: 0))
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isUp)
        }
        .buttonStyle(.plain)
        .disabled(locked || isMatched)
    }

    private func tap(_ card: Card) {
        guard !locked, !busy, !matched.contains(card.id), !flipped.contains(card.id) else { return }
        flipped.insert(card.id)
        let open = cards.filter { flipped.contains($0.id) && !matched.contains($0.id) }
        guard open.count == 2 else { return }
        busy = true
        let isMatch = open[0].pairKey == open[1].pairKey
        if isMatch {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(.spring(duration: 0.3)) {
                    matched.formUnion(open.map(\.id))
                    flipped.subtract(open.map(\.id))
                }
                busy = false
                if matched.count == cards.count { onComplete() }
            }
        } else {
            wiggle = open[1].id
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.spring(duration: 0.3)) { flipped.subtract(open.map(\.id)) }
                wiggle = nil
                busy = false
            }
        }
    }
}

// MARK: - Sort Buckets Card (multi-item drag-to-sort)

/// Several items must each be placed into the correct bucket. Tap an item to
/// pick it up, then tap a bucket to drop it (tap a placed item to return it).
/// The question is answered only once every item is placed.
struct SortBucketsCard: View {
    let buckets: [String]
    let items: [(label: String, bucket: String)]
    let correct: String                 // value to report when all placements are right
    let locked: Bool
    let report: (String?) -> Void

    @State private var placement: [String: String] = [:]   // label -> chosen bucket
    @State private var picked: String? = nil

    private var unplaced: [String] { items.map(\.label).filter { placement[$0] == nil } }

    var body: some View {
        VStack(spacing: 16) {
            // Tray of items still to place
            if !unplaced.isEmpty {
                FlowChips(items: unplaced, highlighted: picked) { label in
                    guard !locked else { return }
                    withAnimation(.spring(duration: 0.2)) {
                        picked = (picked == label) ? nil : label
                    }
                }
            } else {
                Text("All sorted! Tap Check.")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(DS.Color.accent)
            }

            HStack(alignment: .top, spacing: 12) {
                ForEach(buckets, id: \.self) { bucket in
                    bucketColumn(bucket)
                }
            }
        }
    }

    private func bucketColumn(_ bucket: String) -> some View {
        let placed = items.map(\.label).filter { placement[$0] == bucket }
        return VStack(spacing: 8) {
            Text(bucket)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundStyle(DS.Color.textPrimary)
            VStack(spacing: 6) {
                ForEach(placed, id: \.self) { label in
                    Text(label)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(DS.Color.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .clipShape(.rect(cornerRadius: 12))
                        .shadow(color: DS.Color.accent.opacity(0.18), radius: 4, y: 1)
                        .onTapGesture {
                            guard !locked else { return }
                            withAnimation(.spring(duration: 0.2)) { placement[label] = nil; report(currentAnswer()) }
                        }
                }
                if placed.isEmpty {
                    Text(" ")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .padding(.vertical, 8)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 56)
            .padding(10)
            .background(DS.Color.accentSoft.opacity(0.35))
            .clipShape(.rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(picked != nil ? DS.Color.accent : Color.clear, style: StrokeStyle(lineWidth: 2, dash: [6, 5]))
            )
        }
        .contentShape(.rect)
        .onTapGesture {
            guard !locked, let label = picked else { return }
            withAnimation(.spring(duration: 0.2)) {
                placement[label] = bucket
                picked = nil
                report(currentAnswer())
            }
        }
    }

    /// nil until every item is placed; then `correct` if all correct, else a
    /// sentinel that will be marked wrong.
    private func currentAnswer() -> String? {
        guard placement.count == items.count else { return nil }
        let allRight = items.allSatisfy { placement[$0.label] == $0.bucket }
        return allRight ? correct : "__unsorted__"
    }
}

/// Simple wrapping chip row used by the sort tray.
struct FlowChips: View {
    let items: [String]
    let highlighted: String?
    let action: (String) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 70), spacing: 10)], spacing: 10) {
            ForEach(items, id: \.self) { item in
                Button { action(item) } label: {
                    Text(item)
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundStyle(DS.Color.textPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Color(red: 0.996, green: 0.994, blue: 0.992))
                        .clipShape(.rect(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(highlighted == item ? DS.Color.accent : Color.clear, lineWidth: 2.5)
                        )
                        .shadow(color: highlighted == item ? DS.Color.accent.opacity(0.4) : DS.Color.accent.opacity(0.18), radius: highlighted == item ? 12 : 7, y: 2)
                        .scaleEffect(highlighted == item ? 1.06 : 1.0)
                }
                .buttonStyle(.plain)
            }
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: highlighted)
    }
}

// MARK: - Timed Bonus Card (countdown ring)

/// A multiple-choice question wrapped in a countdown ring. Answering before the
/// ring empties lights a bonus star; running out of time has no penalty.
struct TimedBonusCard: View {
    let choices: [String]
    let selected: String?
    let locked: Bool
    let seconds: Double
    let questionKey: String
    var fadedChoice: String? = nil
    let action: (String) -> Void

    @State private var progress: CGFloat = 1.0
    @State private var earnedBonus: Bool = false
    @State private var timedOut: Bool = false

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .stroke(DS.Color.accentSoft, lineWidth: 8)
                    .frame(width: 84, height: 84)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        timedOut ? DS.Color.textTertiary : DS.Color.accent,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 84, height: 84)
                Image(systemName: earnedBonus ? "star.fill" : (timedOut ? "hourglass" : "bolt.fill"))
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundStyle(earnedBonus ? Color(red: 1.0, green: 0.78, blue: 0.10) : DS.Color.accent)
                    .scaleEffect(earnedBonus ? 1.15 : 1.0)
            }
            Text(earnedBonus ? "Bonus earned! ⭐" : (timedOut ? "Time's up — still counts!" : "Answer fast for a bonus!"))
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(earnedBonus ? Color(red: 0.9, green: 0.6, blue: 0.0) : DS.Color.textSecondary)

            FlowRow(items: choices, selected: selected, locked: locked, fadedChoice: fadedChoice) { item in
                guard !locked else { return }
                if progress > 0 && !timedOut { earnedBonus = true }
                action(item)
            }
            .environment(\.choiceStyle, .number)
        }
        .onAppear {
            progress = 1.0
            earnedBonus = false
            timedOut = false
            withAnimation(.linear(duration: seconds)) { progress = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                if selected == nil { timedOut = true }
            }
        }
        .onChange(of: questionKey) { _, _ in
            progress = 1.0
            earnedBonus = false
            timedOut = false
            withAnimation(.linear(duration: seconds)) { progress = 0 }
        }
    }
}
