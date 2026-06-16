//
//  LessonPlayerView.swift
//  Yoko
//

import SwiftUI

struct LessonPlayerView: View {
    @Environment(AppStore.self) private var store
    @Environment(ParentAccountService.self) private var account
    @Environment(\.dismiss) private var dismiss
    let lesson: Lesson

    @State private var index: Int = 0
    @State private var correctCount: Int = 0
    @State private var feedback: Feedback = .none
    @State private var selectedOption: Int? = nil
    @State private var selectedAnswer: String? = nil
    @State private var typedAnswer: String = ""
    @State private var matchSelections: [String: String] = [:]
    @State private var matchPicked: String? = nil
    @State private var showSummary: Bool = false
    @State private var lastAnswerWasWrong: Bool = false
    @State private var wrongCount: Int = 0
    @State private var keyGlow: Bool = false
    @State private var screenHeight: CGFloat = 852
    @State private var contentHeight: CGFloat = 0
    @State private var viewportHeight: CGFloat = 0
    @State private var showScrollHint: Bool = false
    @State private var scrollHintTask: Task<Void, Never>?
    @State private var autoAdvanceTask: Task<Void, Never>?
    @State private var lessonResult: LessonResult?
    @State private var lessonRewards: [MilestoneReward] = []
    @State private var showStreak: Bool = false
    @State private var unscramble = UnscrambleState()

    enum Feedback { case none, correct, incorrect }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if showStreak {
                    StreakCelebrationView(
                        streak: store.profile.streak,
                        childName: store.profile.name,
                        onContinue: { dismiss() }
                    )
                    .transition(.opacity)
                } else if showSummary, let lessonResult {
                    LessonCompleteView(
                        result: lessonResult,
                        rewards: lessonRewards,
                        childName: store.profile.name,
                        onDone: { withAnimation(.spring(duration: 0.5)) { showStreak = true } },
                        onTellParent: { store.tellParentAboutPromotion() }
                    )
                } else {
                    splitBackground
                    questionView
                }
            }
            .onAppear { screenHeight = geo.size.height }
            .onChange(of: geo.size.height) { _, newValue in
                if abs(newValue - screenHeight) > 1 {
                    screenHeight = newValue
                }
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .navigationBarBackButtonHidden(true)
        .onChange(of: contentHeight) { _, _ in evaluateScrollHint() }
        .onChange(of: index) { _, _ in evaluateScrollHint() }
        .onDisappear {
            autoAdvanceTask?.cancel()
            scrollHintTask?.cancel()
        }
    }

    private var question: Question { lesson.questions[index] }

    // MARK: - Background

    private var splitBackground: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                AsyncImage(url: URL(string: "https://pyikafpvphzqdadjvktz.supabase.co/storage/v1/object/public/Yoko/UnlockScreen.png")) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                            .scaleEffect(1.05)
                            .offset(y: -54)
                    } else {
                        Color(red: 0.35, green: 0.55, blue: 0.30)
                    }
                }
                .clipped()

                LinearGradient(
                    colors: [.clear, .white.opacity(0.95)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 110)
            }
            .frame(height: screenHeight * 0.50)

            Color.white
                .frame(maxHeight: .infinity)
        }
        .ignoresSafeArea()
    }

    // MARK: - Question View

    private var questionView: some View {
        VStack(spacing: 0) {
            // Top bar
            HStack {
                closeButton
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, screenHeight * 0.06)

            // Mascot centered in hero area
            mascotImage(urlString: mascotURL)
                .frame(width: 162, height: 162)
                .padding(.top, -9)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)

            // White content area with rounded top corners layered over hero (up 15pt)
            contentArea
        }
    }

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private var contentArea: some View {
        VStack(spacing: 0) {
            // Scrollable question content so overflow never pushes the footer
            ScrollView(.vertical, showsIndicators: true) {
                QuestionRenderer(
                    question: question,
                    selectedAnswer: $selectedAnswer,
                    feedback: feedback,
                    unscramble: unscramble
                )
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 8)
                .background(
                    GeometryReader { proxy in
                        Color.clear.onAppear { contentHeight = proxy.size.height }
                            .onChange(of: proxy.size.height) { _, h in contentHeight = h }
                    }
                )
                .id(index)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
            .background(
                GeometryReader { proxy in
                    Color.clear.onAppear { viewportHeight = proxy.size.height }
                        .onChange(of: proxy.size.height) { _, h in viewportHeight = h }
                }
            )
            .overlay(alignment: .bottom) { scrollHint }

            // Key progress centered above CTA — pinned, with the unscramble
            // back/hint buttons docked in the bottom corners when active.
            keyProgressRow
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                .padding(.top, 8)

            // Thin grey line above CTA
            Divider()
                .background(DS.Color.border)

            // Bottom white footer with CTA — pinned
            bottomFooter
        }
        .background(Color.white)
        .clipShape(
            .rect(
                topLeadingRadius: 30,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 30
            )
        )
        .shadow(color: Color.black.opacity(0.04), radius: 16, x: 0, y: -4)
        .padding(.top, -13)
    }

    // MARK: - Scroll Hint

    @ViewBuilder
    private var scrollHint: some View {
        if showScrollHint {
            HStack(spacing: 6) {
                Text("Scroll for more")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .heavy))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(DS.Color.accent.opacity(0.92))
            .clipShape(.capsule)
            .shadow(color: DS.Color.accent.opacity(0.35), radius: 10, y: 4)
            .padding(.bottom, 6)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private func evaluateScrollHint() {
        let overflows = contentHeight > viewportHeight + 8
        scrollHintTask?.cancel()
        guard overflows else {
            if showScrollHint { withAnimation(.easeOut(duration: 0.3)) { showScrollHint = false } }
            return
        }
        withAnimation(.spring(duration: 0.35)) { showScrollHint = true }
        scrollHintTask = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.4)) { showScrollHint = false }
            }
        }
    }

    // MARK: - Key Progress (Bottom Centered)

    private var keyProgressRow: some View {
        HStack(spacing: 0) {
            if unscramble.active {
                UnscrambleBackButton(state: unscramble)
                Spacer(minLength: 4)
            }
            HStack(spacing: 16) {
                ForEach(0..<lesson.questions.count, id: \.self) { keyIndex in
                    keyCircle(for: keyIndex)
                }
            }
            if unscramble.active {
                Spacer(minLength: 4)
                UnscrambleHintButton(state: unscramble)
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.spring(duration: 0.3), value: unscramble.active)
    }

    @ViewBuilder
    private func keyCircle(for keyIndex: Int) -> some View {
        let isCompleted = keyIndex < index
        let isCurrent = keyIndex == index
        let isCorrectNow = isCurrent && feedback == .correct
        let isGlowing = isCurrent && keyGlow

        ZStack {
            Circle()
                .fill(isCompleted || isCorrectNow ? Color.white : Color(red: 0.94, green: 0.94, blue: 0.94))
                .frame(width: 46, height: 46)
                .overlay(
                    Circle()
                        .stroke(isCompleted || isCorrectNow ? DS.Color.accent : Color.clear, lineWidth: 2)
                )
                .shadow(
                    color: isGlowing ? DS.Color.accent.opacity(0.35) : Color.black.opacity(0.04),
                    radius: isGlowing ? 10 : 4,
                    x: 0,
                    y: isGlowing ? 4 : 2
                )

            Image(systemName: isCompleted || isCorrectNow ? "key.fill" : "key")
                .font(.system(size: isGlowing ? 28 : 22, weight: .heavy))
                .foregroundStyle(
                    isCompleted || isCorrectNow
                        ? DS.Color.accent
                        : DS.Color.textTertiary.opacity(0.35)
                )
                .scaleEffect(isGlowing ? 1.3 : 1.0)
        }
        .animation(.spring(duration: 0.45, bounce: 0.3), value: keyGlow)
        .animation(.spring(duration: 0.3), value: index)
        .animation(.spring(duration: 0.3), value: feedback)
    }

    // MARK: - Mascot

    private func mascotImage(urlString: String) -> some View {
        AnimatedGIFView(urlString: urlString)
    }

    private var mascotURL: String {
        if showSummary {
            return wrongCount > lesson.questions.count / 2 ? GIFAssets.proud : GIFAssets.excited
        }
        if lastAnswerWasWrong {
            return GIFAssets.sad
        }
        if index == lesson.questions.count - 1 {
            return GIFAssets.determined
        }
        if index == 1 {
            return GIFAssets.thinking
        }
        return GIFAssets.happy
    }

    // MARK: - Bottom Footer

    private var bottomFooter: some View {
        VStack(spacing: 0) {
            bottomButton
                .padding(.horizontal, 24)
                .padding(.vertical, 18)
        }
        .background(Color.white)
    }

    // MARK: - Bottom Button

    private var bottomButton: some View {
        Button(action: primaryAction) {
            Text(primaryActionTitle)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(canSubmit ? DS.Color.accent : DS.Color.accent.opacity(0.28))
                .clipShape(.rect(cornerRadius: 20))
                .shadow(color: canSubmit ? DS.Color.accent.opacity(0.40) : Color.clear, radius: 18, y: 8)
        }
        .buttonStyle(.plain)
        .disabled(!canSubmit)
        .scaleEffect(canSubmit ? 1.0 : 0.97)
        .animation(.spring(duration: 0.3), value: canSubmit)
        .animation(.spring(duration: 0.25), value: feedback)
    }

    private var primaryActionTitle: String {
        if feedback != .none {
            return index + 1 < lesson.questions.count ? "Continue" : "Finish Lesson"
        }
        return "Check Answer"
    }

    private var canSubmit: Bool {
        if feedback != .none { return true }
        if let normalized = question.normalized {
            let template = normalized.templateType.snakeKey
            if ["sentence_building", "sequencing"].contains(template) {
                return selectedAnswer == normalized.correctAnswer
                    || selectedAnswer?.split(separator: " ").count == normalized.correctAnswer.split(separator: " ").count
                    || selectedAnswer?.split(separator: ">").count == normalized.correctAnswer.split(separator: ">").count
            }
            if ["unscramble_word", "missing_letter", "fill_missing_letters"].contains(template) {
                return selectedAnswer?.count == normalized.correctAnswer.count
            }
        }
        switch question.kind {
        case .multipleChoice: return selectedAnswer != nil
        case .fillInBlank: return selectedAnswer != nil || !typedAnswer.trimmingCharacters(in: .whitespaces).isEmpty
        case let .matching(pairs): return matchSelections.count == pairs.count
        }
    }

    private func primaryAction() {
        if feedback == .none {
            evaluate()
        } else {
            advance()
        }
    }

    private func evaluate() {
        let isCorrect: Bool
        if let normalized = question.normalized, let selectedAnswer {
            isCorrect = selectedAnswer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == normalized.correctAnswer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        } else {
            switch question.kind {
            case let .multipleChoice(options, correctIndex):
                isCorrect = selectedAnswer == options[correctIndex]
            case let .fillInBlank(answer):
                let submittedAnswer = selectedAnswer ?? typedAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
                isCorrect = submittedAnswer.lowercased() == answer.lowercased()
            case let .matching(pairs):
                isCorrect = pairs.allSatisfy { matchSelections[$0.0] == $0.1 }
            }
        }
        withAnimation(.spring(duration: 0.35)) {
            feedback = isCorrect ? .correct : .incorrect
        }
        if isCorrect {
            correctCount += 1
            lastAnswerWasWrong = false
            withAnimation(.spring(duration: 0.45, bounce: 0.3)) {
                keyGlow = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.spring(duration: 0.4)) {
                    keyGlow = false
                }
            }
            // Auto-advance after a short delay
            autoAdvanceTask?.cancel()
            autoAdvanceTask = Task {
                try? await Task.sleep(for: .seconds(1.2))
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    if feedback == .correct {
                        advance()
                    }
                }
            }
        } else {
            wrongCount += 1
            lastAnswerWasWrong = true
        }
        UIImpactFeedbackGenerator(style: isCorrect ? .medium : .rigid).impactOccurred()
    }

    private func advance() {
        autoAdvanceTask?.cancel()
        if index + 1 < lesson.questions.count {
            withAnimation(.spring(duration: 0.4)) {
                index += 1
                feedback = .none
                selectedOption = nil
                selectedAnswer = nil
                typedAnswer = ""
                matchSelections = [:]
                matchPicked = nil
                keyGlow = false
            }
        } else {
            let outcome = store.completeLesson(lesson, correctCount: correctCount)
            lessonResult = outcome.result
            lessonRewards = outcome.rewards
            withAnimation(.spring(duration: 0.5)) { showSummary = true }
            if account.isLinked {
                let snapshot = store.exportSnapshot()
                Task { await account.push(snapshot) }
            }
        }
    }

}

// MARK: - Option Button (legacy support)

struct OptionButton: View {
    enum State { case idle, selected, correct, wrong }
    let text: String
    let state: State
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(text)
                    .font(.dsHeadline)
                    .foregroundStyle(textColor)
                    .multilineTextAlignment(.leading)
                Spacer()
                if state == .correct {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(DS.Color.success)
                } else if state == .wrong {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(DS.Color.danger)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background)
            .clipShape(.rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(borderColor, lineWidth: state == .idle ? 1 : 2)
            )
        }
        .buttonStyle(.plain)
    }

    private var background: Color {
        switch state {
        case .idle: return DS.Color.surface
        case .selected: return DS.Color.accentSoft
        case .correct: return Color(red: 0.92, green: 0.98, blue: 0.94)
        case .wrong: return Color(red: 1, green: 0.94, blue: 0.93)
        }
    }
    private var textColor: Color {
        switch state {
        case .wrong: return DS.Color.danger
        default: return DS.Color.textPrimary
        }
    }
    private var borderColor: Color {
        switch state {
        case .idle: return DS.Color.border
        case .selected: return DS.Color.accent
        case .correct: return DS.Color.success
        case .wrong: return DS.Color.danger
        }
    }
}

// MARK: - Matching

struct MatchingView: View {
    let pairs: [(String, String)]
    @Binding var selections: [String: String]
    @Binding var picked: String?
    let locked: Bool

    var lefts: [String] { pairs.map(\.0) }
    var rights: [String] { pairs.map(\.1).shuffled(seed: pairs.count) }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 10) {
                ForEach(lefts, id: \.self) { l in
                    matchTile(text: l, isLeft: true, selected: picked == l, matched: selections[l] != nil)
                        .onTapGesture {
                            guard !locked else { return }
                            picked = (picked == l) ? nil : l
                        }
                }
            }
            VStack(spacing: 10) {
                ForEach(rights, id: \.self) { r in
                    matchTile(text: r, isLeft: false, selected: false, matched: selections.values.contains(r))
                        .onTapGesture {
                            guard !locked, let l = picked else { return }
                            for (k, v) in selections where v == r { selections.removeValue(forKey: k) }
                            selections[l] = r
                            picked = nil
                        }
                }
            }
        }
    }

    private func matchTile(text: String, isLeft: Bool, selected: Bool, matched: Bool) -> some View {
        Text(text)
            .font(.dsHeadline)
            .foregroundStyle(matched ? DS.Color.accent : DS.Color.textPrimary)
            .frame(maxWidth: .infinity, minHeight: 52)
            .padding(.horizontal, 14)
            .background(selected ? DS.Color.accentSoft : DS.Color.surface)
            .clipShape(.rect(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(selected || matched ? DS.Color.accent : DS.Color.border, lineWidth: selected ? 2 : 1)
            )
    }
}

private extension Array {
    func shuffled(seed: Int) -> [Element] {
        var g = SeededGenerator(seed: UInt64(seed) &+ 1)
        return self.shuffled(using: &g)
    }
}

private struct SeededGenerator: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 1 : seed }
    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
