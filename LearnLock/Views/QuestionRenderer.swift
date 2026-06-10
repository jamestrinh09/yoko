import SwiftUI

struct QuestionRenderer: View {
    let question: Question
    @Binding var selectedAnswer: String?
    let feedback: LessonPlayerView.Feedback
    var unscramble: UnscrambleState = UnscrambleState()

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
        }
    }

    // MARK: - Question Meta

    private var questionTitle: String { normalized?.prompt ?? question.prompt }

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
        normalized?.directions ?? "Tap your answer"
    }

    // MARK: - Interactive Content

    @ViewBuilder
    private var interactiveContent: some View {
        switch template {
        case "counting_objects":
            EmojiCounterRow(items: split(content["items"]), hint: feedback == .incorrect, fixedColumns: int(content["columns"]) > 0 ? int(content["columns"]) : nil)

        case "which_has_more_or_less":
            tappableComparison

        case "addition_by_counting":
            AdditionGroupsCard(left: split(content["left"]), right: split(content["right"]), equation: content["equation"])

        case "subtraction_by_taking_away":
            VStack(spacing: 12) {
                EmojiCounterRow(items: split(content["items"]), hint: feedback == .incorrect)
                equationLabel(content["equation"])
            }

        case "missing_number_equation":
            buildBlankCard(pattern: content["equation"] ?? question.prompt, chips: chipValues, directSelect: true)

        case "number_line_jump":
            NumberLineCard(start: int(content["start"]), jump: signedInt(content["jump"]), selected: selectedAnswer, locked: isLocked) { selectedAnswer = $0 }

        case "make_ten":
            TenFrameCard(filled: int(content["filled"]), hint: feedback == .incorrect)

        case "multiplication_arrays":
            ArrayBuilderCard(rows: int(content["rows"]), columns: int(content["columns"]), item: content["item"] ?? "●")

        case "division_as_sharing":
            GroupingBucketsCard(total: totalObjects(content["objects"]), buckets: int(content["buckets"]), item: objectEmoji(content["objects"]))

        case "pattern_recognition":
            PatternRowCard(sequence: visualSequence)

        case "fractions":
            FractionBarCard(parts: int(content["parts"]), filled: int(content["filled"]))

        case "telling_time":
            ClockCard(hour: int(content["hour"]), minute: int(content["minute"]))

        case "letter_recognition":
            visualTapGrid(items: choices, style: .letter)

        case "uppercase_lowercase_matching":
            MatchingCardSet(left: content["uppercase"] ?? "B", right: choices, selected: selectedAnswer, locked: isLocked) { selectedAnswer = $0 }

        case "beginning_sounds", "choose_correct_spelling", "sight_word_recognition", "punctuation_choice", "rhyming_words", "word_families", "vocabulary_matching":
            visualTapGrid(items: choices, style: englishChoiceStyle)

        case "missing_letter", "fill_missing_letters":
            buildBlankCard(pattern: content["wordWithBlank"] ?? content["wordWithBlanks"] ?? question.prompt, chips: choices, emoji: content["emoji"])

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

        case "grammar_sorting":
            GrammarBucketsCard(word: content["word"] ?? question.prompt, buckets: choices, selected: selectedAnswer, locked: isLocked) { selectedAnswer = $0 }

        case "reading_comprehension":
            StoryEmojiStrip(emojis: (content["emojis"] ?? "").replacingOccurrences(of: ",", with: " "), text: content["text"] ?? question.prompt)

        case "sequencing":
            sequenceBuildCard(cards: sequenceCards)

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

    private func visualTapGrid(items: [String], style: ChoiceStyle) -> some View {
        FlowRow(items: items, selected: selectedAnswer, locked: isLocked) { item in
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
        let buildTemplates: Set<String> = [
            "missing_number_equation", "missing_letter", "fill_missing_letters",
            "unscramble_word", "sentence_building", "sequencing",
            "letter_recognition", "uppercase_lowercase_matching",
            "which_has_more_or_less", "number_line_jump", "grammar_sorting",
            "beginning_sounds", "choose_correct_spelling",
            "sight_word_recognition", "punctuation_choice",
            "rhyming_words", "word_families", "vocabulary_matching"
        ]
        return !buildTemplates.contains(template) && choices.count > 1
    }

    private var englishChoiceStyle: ChoiceStyle { template == "letter_recognition" ? .letter : .word }
    private var fallbackChoices: [String] { if case let .multipleChoice(options, _) = question.kind { options } else { [] } }
    private var chipValues: [String] { splitComma(content["chips"]).isEmpty ? choices : splitComma(content["chips"]) }
    private var tokenValues: [String] { splitComma(content["tokens"]).isEmpty ? choices : splitComma(content["tokens"]) }
    private var sequenceCards: [String] { splitComma(content["cards"]).isEmpty ? choices : splitComma(content["cards"]) }
    private var letterChips: [String] { splitComma(content["letters"]).isEmpty ? choices : splitComma(content["letters"]) }
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

private enum ChoiceStyle { case word, letter, number }
private struct ChoiceStyleKey: EnvironmentKey { static let defaultValue: ChoiceStyle = .word }
private extension EnvironmentValues {
    var choiceStyle: ChoiceStyle {
        get { self[ChoiceStyleKey.self] }
        set { self[ChoiceStyleKey.self] = newValue }
    }
}

// MARK: - Flow Row (Answer Chips)

struct FlowRow: View {
    let items: [String]
    let selected: String?
    let locked: Bool
    let action: (String) -> Void
    @Environment(\.choiceStyle) private var style

    var body: some View {
        // With exactly two choices an adaptive grid can fit two columns and ends
        // up rendering each item twice. Use a fixed 2-column grid in that case.
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
                .scaleEffect(selected == item ? 1.04 : 1.0)
                .animation(.spring(duration: 0.2), value: selected)
            }
        }
    }

    private var minWidth: CGFloat { style == .letter ? 72 : 96 }
    private var height: CGFloat { style == .letter ? 78 : 66 }
    private var font: Font {
        switch style {
        case .letter: .system(size: 36, weight: .heavy, design: .rounded)
        case .number: .system(size: 26, weight: .heavy, design: .rounded)
        case .word: .system(size: 22, weight: .heavy, design: .rounded)
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

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 0) {
                ForEach(0...12, id: \.self) { n in
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
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .disabled(locked)
                    .scaleEffect(selected == "\(n)" ? 1.15 : 1)
                    .animation(.spring(duration: 0.2), value: selected)
                }
            }
            Text("Start at \(start)  →  jump \(jump >= 0 ? "+" : "")\(jump)")
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(DS.Color.accent)
        }
    }
}

struct TenFrameCard: View {
    let filled: Int
    let hint: Bool

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(44)), count: 5), spacing: 8) {
            ForEach(0..<10, id: \.self) { i in
                Circle()
                    .fill(i < filled ? DS.Color.accent : DS.Color.accentSoft)
                    .frame(width: 42, height: 42)
                    .overlay(
                        Circle()
                            .stroke(
                                DS.Color.accent.opacity(i >= filled && hint ? 0.8 : 0.15),
                                lineWidth: 2
                            )
                    )
            }
        }
    }
}

struct ArrayBuilderCard: View {
    let rows: Int
    let columns: Int
    let item: String
    private let maxVisibleRows = 4

    var body: some View {
        VStack(spacing: 8) {
            ForEach(0..<min(max(rows, 1), maxVisibleRows), id: \.self) { _ in
                HStack(spacing: 8) {
                    ForEach(0..<max(columns, 1), id: \.self) { _ in
                        Text(item)
                            .font(.system(size: 24))
                    }
                }
            }
            if rows > maxVisibleRows {
                Text("+ \(rows - maxVisibleRows) more rows")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(DS.Color.textSecondary)
            }
            Text("\(rows) rows × \(columns) columns = ?")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(DS.Color.textSecondary)
                .padding(.top, 4)
        }
    }
}

struct GroupingBucketsCard: View {
    let total: Int
    let buckets: Int
    let item: String

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<max(buckets, 1), id: \.self) { _ in
                VStack(spacing: 6) {
                    Text("🥣")
                        .font(.system(size: 36))
                    Text(String(repeating: item, count: max(total / max(buckets, 1), 1)))
                        .font(.system(size: 20))
                }
                .frame(maxWidth: .infinity)
                .padding(10)
                .background(Color(red: 0.996, green: 0.994, blue: 0.992))
                .clipShape(.rect(cornerRadius: 16))
                .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 1)
            }
        }
    }
}

struct PatternRowCard: View {
    let sequence: String

    var body: some View {
        Text(sequence)
            .font(.system(size: 30, weight: .heavy, design: .rounded))
            .foregroundStyle(DS.Color.textPrimary)
            .multilineTextAlignment(.center)
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

struct ClockCard: View {
    let hour: Int
    let minute: Int

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(red: 0.996, green: 0.994, blue: 0.992))
                .frame(width: 160, height: 160)
            Circle()
                .stroke(DS.Color.border, lineWidth: 6)
                .frame(width: 150, height: 150)

            ForEach(1...12, id: \.self) { n in
                Text("\(n)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .offset(y: -60)
                    .rotationEffect(.degrees(Double(n) * 30))
                    .rotationEffect(.degrees(Double(n) * -30))
            }

            Rectangle()
                .fill(DS.Color.textPrimary)
                .frame(width: 5, height: 42)
                .offset(y: -21)
                .rotationEffect(.degrees(Double(hour % 12) * 30))

            Rectangle()
                .fill(DS.Color.accent)
                .frame(width: 4, height: 54)
                .offset(y: -27)
                .rotationEffect(.degrees(Double(minute) * 6))

            Circle()
                .fill(DS.Color.accent)
                .frame(width: 12, height: 12)
        }
    }
}

// MARK: - English Visual Components

struct MatchingCardSet: View {
    let left: String
    let right: [String]
    let selected: String?
    let locked: Bool
    let action: (String) -> Void

    var body: some View {
        HStack(spacing: 14) {
            Text(left)
                .font(.system(size: 52, weight: .heavy, design: .rounded))
                .frame(maxWidth: .infinity, minHeight: 110)
                .background(Color(red: 0.996, green: 0.994, blue: 0.992))
                .clipShape(.rect(cornerRadius: 22))
                .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)

            FlowRow(items: right, selected: selected, locked: locked, action: action)
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

struct GrammarBucketsCard: View {
    let word: String
    let buckets: [String]
    let selected: String?
    let locked: Bool
    let action: (String) -> Void

    var body: some View {
        VStack(spacing: 14) {
            Text(word)
                .font(.system(size: 36, weight: .heavy, design: .rounded))
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(Color(red: 0.996, green: 0.994, blue: 0.992))
                .clipShape(.capsule)
                .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 1)

            FlowRow(items: buckets, selected: selected, locked: locked, action: action)
                .environment(\.choiceStyle, .word)
        }
    }
}
