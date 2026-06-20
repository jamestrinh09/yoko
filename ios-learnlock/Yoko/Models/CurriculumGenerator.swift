//
//  CurriculumGenerator.swift
//  Yoko
//
//  Procedural lesson generation engine.
//  Skills + templates produce an unlimited stream of grade-scaled questions.
//

import Foundation

// MARK: - Skills

enum CurriculumSkill: String, CaseIterable, Codable, Hashable {
    // Math
    case counting, addition, subtraction, missingNumber, numberLine, makeTen
    case skipCounting, multiplicationArray, divisionSharing, patterns, fractions, time, compareNumbers
    case timedBonus
    // English
    case letterRecognition, uppercaseLowercase, beginningSound, missingLetter
    case spelling, unscramble, rhyming, vocabulary, sightWord, wordFamily, sentenceBuilding, punctuation
    case memoryMatch, wordSort

    var subject: Subject {
        switch self {
        case .counting, .addition, .subtraction, .missingNumber, .numberLine, .makeTen,
             .skipCounting, .multiplicationArray, .divisionSharing, .patterns, .fractions, .time, .compareNumbers,
             .timedBonus:
            return .math
        default:
            return .english
        }
    }

    var title: String {
        switch self {
        case .counting: "Counting"
        case .addition: "Addition"
        case .subtraction: "Subtraction"
        case .missingNumber: "Missing Numbers"
        case .numberLine: "Number Line"
        case .makeTen: "Make Ten"
        case .skipCounting: "Skip Counting"
        case .multiplicationArray: "Multiplication"
        case .divisionSharing: "Division"
        case .patterns: "Patterns"
        case .fractions: "Fractions"
        case .time: "Telling Time"
        case .compareNumbers: "Compare Numbers"
        case .timedBonus: "Speed Round"
        case .letterRecognition: "Letters"
        case .uppercaseLowercase: "Upper & Lower"
        case .beginningSound: "Beginning Sounds"
        case .missingLetter: "Missing Letter"
        case .spelling: "Spelling"
        case .unscramble: "Unscramble"
        case .rhyming: "Rhyming"
        case .vocabulary: "Vocabulary"
        case .sightWord: "Sight Words"
        case .wordFamily: "Word Families"
        case .sentenceBuilding: "Sentences"
        case .punctuation: "Punctuation"
        case .memoryMatch: "Memory Match"
        case .wordSort: "Word Sort"
        }
    }
}

// MARK: - Seeded RNG

struct SeededRNG: RandomNumberGenerator {
    var state: UInt64
    init(_ seed: UInt64) { state = seed == 0 ? 0xdead_beef_cafe_babe : seed }
    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}

// MARK: - Grade helpers

enum GradeLevelOption: Int, CaseIterable, Identifiable {
    case preschool = -1, kindergarten = 0, grade1 = 1, grade2 = 2, grade3 = 3, grade4 = 4, grade5 = 5
    var id: Int { rawValue }
    var displayName: String {
        switch self {
        case .preschool: "Preschool"
        case .kindergarten: "Kindergarten"
        case .grade1: "1st Grade"
        case .grade2: "2nd Grade"
        case .grade3: "3rd Grade"
        case .grade4: "4th Grade"
        case .grade5: "5th Grade"
        }
    }
}

extension Subject {
    var curriculum: CurriculumSubject { self == .math ? .math : .english }
}

// MARK: - Generator

@MainActor
enum CurriculumGenerator {

    /// Map a numeric grade to a `GradeBand` used by templates.
    static func gradeBand(for grade: Int) -> GradeBand {
        switch grade {
        case ...0: return .kindergarten
        case 1: return .grade1
        case 2: return .grade2
        default: return .grade3 // 3+ uses grade3 with bumped level/difficulty
        }
    }

    /// Effective "level boost" beyond grade band (drives ranges for 4th/5th).
    static func levelBoost(for grade: Int) -> Int { max(0, grade - 3) }

    static let mathPool: [GradeBand: [CurriculumSkill]] = [
        .kindergarten: [.counting, .addition, .subtraction, .makeTen, .patterns, .compareNumbers, .timedBonus],
        .grade1: [.counting, .addition, .subtraction, .makeTen, .missingNumber, .numberLine, .patterns, .compareNumbers, .time, .timedBonus],
        .grade2: [.addition, .subtraction, .missingNumber, .numberLine, .skipCounting, .patterns, .compareNumbers, .time, .multiplicationArray, .timedBonus],
        .grade3: [.missingNumber, .numberLine, .skipCounting, .multiplicationArray, .divisionSharing, .fractions, .time, .compareNumbers, .patterns, .timedBonus]
    ]
    static let englishPool: [GradeBand: [CurriculumSkill]] = [
        .kindergarten: [.letterRecognition, .uppercaseLowercase, .beginningSound, .missingLetter, .vocabulary, .sightWord, .memoryMatch],
        .grade1: [.beginningSound, .missingLetter, .unscramble, .rhyming, .vocabulary, .sightWord, .wordFamily, .sentenceBuilding, .punctuation, .memoryMatch, .wordSort],
        .grade2: [.spelling, .unscramble, .rhyming, .vocabulary, .sightWord, .wordFamily, .sentenceBuilding, .punctuation, .memoryMatch, .wordSort],
        .grade3: [.spelling, .unscramble, .vocabulary, .sightWord, .sentenceBuilding, .punctuation, .memoryMatch, .wordSort]
    ]

    static func skills(subject: Subject, grade: GradeBand) -> [CurriculumSkill] {
        subject == .math ? (mathPool[grade] ?? []) : (englishPool[grade] ?? [])
    }

    // MARK: Lesson / batch

    static func generateLesson(subject: Subject, grade: Int, focus: CurriculumSkill? = nil, level: Int = 1, seed: UInt64) -> Lesson {
        var used = Set<String>()
        return generateLesson(subject: subject, grade: grade, focus: focus, level: level, seed: seed, usedSignatures: &used)
    }

    /// Full question fingerprint: prompt + answer + the content payload (the
    /// pairs/items/values that actually distinguish two questions sharing one
    /// fixed prompt, e.g. memory match or "What time does the clock show?").
    /// Skills whose questions are built around a single word (or word family).
    /// For these we de-dup by the core word so the same word never appears in two
    /// questions — e.g. "monkey" can't show up in two unscrambles or vocab cards.
    private static let wordDedupSkills: Set<String> = [
        "unscramble", "vocabulary", "spelling", "sight words", "rhyming", "word families"
    ]

    /// A coarse de-dup key for word-based english questions. `nil` for everything
    /// else (those fall back to the full content signature).
    private static func wordToken(_ q: NormalizedQuestion) -> String? {
        guard wordDedupSkills.contains(q.skill) else { return nil }
        let word = q.questionContent["word"]
            ?? q.questionContent["target"]
            ?? q.questionContent["meaning"]
            ?? q.questionContent["family"]
            ?? q.correctAnswer
        return "wt|\(q.skill)|\(word.lowercased())"
    }

    private static func signature(_ q: NormalizedQuestion) -> String {
        let contentSig = q.questionContent
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: ";")
        return q.prompt + "|" + q.correctAnswer + "|" + contentSig
    }

    /// Generate one lesson, avoiding any question signature already present in
    /// `usedSignatures` (shared across the whole batch) so the same question is
    /// never assigned to two different lessons until the pool is exhausted.
    static func generateLesson(subject: Subject, grade: Int, focus: CurriculumSkill? = nil, level: Int = 1, seed: UInt64, usedSignatures: inout Set<String>) -> Lesson {
        var rng = SeededRNG(seed)
        let band = gradeBand(for: grade)
        let boost = levelBoost(for: grade)
        let pool = skills(subject: subject, grade: band)
        let fallback: CurriculumSkill = subject == .math ? .counting : .letterRecognition
        let focusSkill = focus ?? pool.randomElement(using: &rng) ?? fallback
        let count = 3 // every lesson is exactly 3 questions
        var qs: [NormalizedQuestion] = []
        var seen = Set<String>()
        // Pass 1 — unique within this lesson AND not used by any earlier lesson.
        var safety = 0
        while qs.count < count && safety < 90 {
            safety += 1
            let candidate = generate(skill: focusSkill, band: band, level: level + boost, rng: &rng)
            let sig = signature(candidate)
            guard !seen.contains(sig), !usedSignatures.contains(sig) else { continue }
            let token = wordToken(candidate)
            if let token, seen.contains(token) || usedSignatures.contains(token) { continue }
            seen.insert(sig)
            usedSignatures.insert(sig)
            if let token { seen.insert(token); usedSignatures.insert(token) }
            qs.append(candidate)
        }
        // Pass 2 — pool exhausted across lessons: relax the cross-lesson rule but
        // keep the lesson internally unique (a full cycle has completed).
        safety = 0
        while qs.count < count && safety < 60 {
            safety += 1
            let candidate = generate(skill: focusSkill, band: band, level: level + boost, rng: &rng)
            let sig = signature(candidate)
            let token = wordToken(candidate)
            if let token, seen.contains(token) { continue }
            guard seen.insert(sig).inserted else { continue }
            usedSignatures.insert(sig)
            if let token { seen.insert(token); usedSignatures.insert(token) }
            qs.append(candidate)
        }
        // Last resort — guarantee exactly 3 questions.
        while qs.count < count {
            qs.append(generate(skill: focusSkill, band: band, level: level + boost, rng: &rng))
        }
        let questions = qs.map(toQuestion)
        let title = "\(focusSkill.title) Challenge"
        return Lesson(title: title, subject: subject, level: level, questions: questions)
    }

    static func generateBatch(subject: Subject, grade: Int, count: Int, startSeed: UInt64, weakSkills: [CurriculumSkill] = []) -> [Lesson] {
        let band = gradeBand(for: grade)
        let pool = skills(subject: subject, grade: band)
        guard !pool.isEmpty else { return [] }
        var lessons: [Lesson] = []
        var rng = SeededRNG(startSeed)
        // Shared across the batch so no question is reused until the pool cycles.
        var usedSignatures = Set<String>()
        for i in 0..<count {
            let focus: CurriculumSkill
            let weakInPool = weakSkills.filter { pool.contains($0) }
            if !weakInPool.isEmpty, i % 2 == 0, let w = weakInPool.randomElement(using: &rng) {
                focus = w
            } else {
                focus = pool.randomElement(using: &rng) ?? pool[0]
            }
            let level = 1 + Int(rng.next() % 4)
            let seed = startSeed &+ UInt64(i + 1) &* 1_000_003
            lessons.append(generateLesson(subject: subject, grade: grade, focus: focus, level: level, seed: seed, usedSignatures: &usedSignatures))
        }
        return lessons
    }

    // MARK: Dispatch

    static func generate(skill: CurriculumSkill, band: GradeBand, level: Int, rng: inout SeededRNG) -> NormalizedQuestion {
        switch skill {
        case .counting: return genCounting(band: band, level: level, rng: &rng)
        case .addition: return genAddition(band: band, level: level, rng: &rng)
        case .subtraction: return genSubtraction(band: band, level: level, rng: &rng)
        case .missingNumber: return genMissingNumber(band: band, level: level, rng: &rng)
        case .numberLine: return genNumberLine(band: band, level: level, rng: &rng)
        case .makeTen: return genMakeTen(rng: &rng)
        case .skipCounting: return genSkipCounting(band: band, level: level, rng: &rng)
        case .multiplicationArray: return genArray(band: band, level: level, rng: &rng)
        case .divisionSharing: return genDivision(band: band, level: level, rng: &rng)
        case .patterns: return genPattern(band: band, level: level, rng: &rng)
        case .fractions: return genFraction(level: level, rng: &rng)
        case .time: return genTime(band: band, level: level, rng: &rng)
        case .compareNumbers: return genCompare(band: band, level: level, rng: &rng)
        case .timedBonus: return genTimedBonus(band: band, level: level, rng: &rng)
        case .letterRecognition: return genLetter(rng: &rng)
        case .uppercaseLowercase: return genUpperLower(rng: &rng)
        case .beginningSound: return genBeginningSound(rng: &rng)
        case .missingLetter: return genMissingLetter(rng: &rng)
        case .spelling: return genSpelling(band: band, rng: &rng)
        case .unscramble: return genUnscramble(band: band, level: level, rng: &rng)
        case .rhyming: return genRhyme(rng: &rng)
        case .vocabulary: return genVocab(band: band, rng: &rng)
        case .sightWord: return genSightWord(band: band, rng: &rng)
        case .wordFamily: return genWordFamily(rng: &rng)
        case .sentenceBuilding: return genSentence(band: band, rng: &rng)
        case .punctuation: return genPunctuation(rng: &rng)
        case .memoryMatch: return genMemoryMatch(band: band, rng: &rng)
        case .wordSort: return genWordSort(band: band, rng: &rng)
        }
    }

    // MARK: Question wrapping

    private static func toQuestion(_ n: NormalizedQuestion) -> Question {
        if n.answerChoices.count <= 1 {
            return Question(prompt: n.prompt, kind: .fillInBlank(answer: n.correctAnswer), normalized: n)
        }
        if let i = n.answerChoices.firstIndex(of: n.correctAnswer) {
            return Question(prompt: n.prompt, kind: .multipleChoice(options: n.answerChoices, correctIndex: i), normalized: n)
        }
        return Question(prompt: n.prompt, kind: .fillInBlank(answer: n.correctAnswer), normalized: n)
    }

    // MARK: - NormalizedQuestion builder

    private static func nq(subject: CurriculumSubject, skill: String, component: String, template: String,
                           prompt: String, directions: String, source: String,
                           content: [String: String], choices: [String], correct: String,
                           grade: GradeBand) -> NormalizedQuestion {
        let uid = UUID().uuidString
        return NormalizedQuestion(
            id: uid, subject: subject, skill: skill, component: component, templateType: template,
            prompt: prompt, directions: directions, visualSource: source,
            questionContent: content, answerChoices: choices, correctAnswer: correct,
            interactionType: choices.count == 1 ? "drag_or_reorder" : "tap_choice",
            difficulty: .balanced, hintType: skill,
            feedbackCorrect: "Nice work — time earned!",
            feedbackIncorrect: "Almost. Use the visual hint and try again.",
            gradeBand: grade, estimatedSeconds: 20,
            masteryTag: skill.replacingOccurrences(of: " ", with: "_"),
            curriculumUnit: subject.rawValue,
            sessionGoal: "unlock_app_time",
            unlockContext: nil, questionSeed: uid)
    }

    // MARK: - Math generators

    private static let fruitEmojis = ["🍎","🍌","🍊","🍇","🍓","🍉","🍑","🍐"]
    private static let animalEmojis = ["🐶","🐱","🐻","🐸","🐢","🐟","🐰","🦁"]
    private static let foodEmojis = ["🍪","🍕","🥕","🧁","🌽","🍞"]
    private static let shapeEmojis = ["⭐","🔴","🔵","🟢","🟡","🟣"]

    private static func mcChoices(_ correct: Int, around: Int = 2, exclude: Set<Int> = [], rng: inout SeededRNG) -> [String] {
        var pool = Set<Int>()
        pool.insert(correct)
        var attempts = 0
        while pool.count < 3 && attempts < 30 {
            let delta = 1 + Int(rng.next() % UInt64(around + 1))
            let sign = Int(rng.next() % 2) == 0 ? -1 : 1
            let v = max(0, correct + sign * delta)
            // Skip values the question itself shows (operands) so distractors
            // can't just mirror numbers already on screen.
            if v != correct && exclude.contains(v) { attempts += 1; continue }
            pool.insert(v)
            attempts += 1
        }
        return Array(pool).map(String.init).shuffled(using: &rng)
    }

    private static func genCounting(band: GradeBand, level: Int, rng: inout SeededRNG) -> NormalizedQuestion {
        let max: Int
        switch band {
        case .kindergarten: max = 8
        case .grade1: max = 12
        case .grade2: max = 20
        case .grade3: max = 30
        }
        let count = 3 + Int(rng.next() % UInt64(max - 2))
        let pack = [fruitEmojis, animalEmojis, foodEmojis].randomElement(using: &rng) ?? fruitEmojis
        let emoji = pack.randomElement(using: &rng) ?? "🍎"
        let items = String(repeating: emoji + " ", count: count).trimmingCharacters(in: .whitespaces)
        var content: [String: String] = ["items": items, "count": String(count)]
        if count >= 6 {
            let cols = count % 4 == 0 ? 4 : (count % 3 == 0 ? 3 : 4)
            content["columns"] = String(cols)
        }
        return nq(subject: .math, skill: "counting objects", component: "Emoji Counter Row", template: "Counting Objects",
                  prompt: "How many \(emoji) do you see?",
                  directions: "Count each one, then choose the number.",
                  source: "fruit_pack",
                  content: content,
                  choices: mcChoices(count, rng: &rng),
                  correct: String(count), grade: band)
    }

    private static func genAddition(band: GradeBand, level: Int, rng: inout SeededRNG) -> NormalizedQuestion {
        let cap: Int
        switch band {
        case .kindergarten: cap = 5
        case .grade1: cap = 10
        case .grade2: cap = 50
        case .grade3: cap = 100
        }
        let scale = cap + level * (cap / 5)
        let a = 1 + Int(rng.next() % UInt64(scale))
        let b = 1 + Int(rng.next() % UInt64(scale))
        let sum = a + b
        var content: [String: String] = ["equation": "\(a) + \(b) = __"]
        if a <= 5 && b <= 5 {
            let emoji = animalEmojis.randomElement(using: &rng) ?? "🐶"
            content["left"] = String(repeating: emoji + " ", count: a).trimmingCharacters(in: .whitespaces)
            content["right"] = String(repeating: emoji + " ", count: b).trimmingCharacters(in: .whitespaces)
        }
        return nq(subject: .math, skill: "addition by counting", component: "Emoji Counter Row", template: "Addition by Counting",
                  prompt: "\(a) + \(b) = ?",
                  directions: a <= 5 && b <= 5 ? "Count both groups together." : "Add the two numbers.",
                  source: "animal_pack", content: content,
                  choices: mcChoices(sum, around: 3, rng: &rng), correct: String(sum), grade: band)
    }

    private static func genSubtraction(band: GradeBand, level: Int, rng: inout SeededRNG) -> NormalizedQuestion {
        let cap: Int
        switch band {
        case .kindergarten: cap = 6
        case .grade1: cap = 12
        case .grade2: cap = 30
        case .grade3: cap = 100
        }
        let scale = cap + level * (cap / 5)
        // Keep both operands >= 1 so the question never reads "5 take away 0".
        let a = 3 + Int(rng.next() % UInt64(scale))
        let b = 1 + Int(rng.next() % UInt64(a - 1))
        let diff = a - b
        var content: [String: String] = ["equation": "\(a) - \(b) = __"]
        if a <= 6 {
            let emoji = foodEmojis.randomElement(using: &rng) ?? "🍪"
            let filled = String(repeating: emoji + " ", count: diff)
            let faded = String(repeating: "◌ ", count: b)
            content["items"] = (filled + faded).trimmingCharacters(in: .whitespaces)
        }
        return nq(subject: .math, skill: "subtraction by taking away", component: "Emoji Counter Row", template: "Subtraction by Taking Away",
                  prompt: "\(a) take away \(b). How many are left?",
                  directions: "Count what is not faded.",
                  source: "food_pack", content: content,
                  choices: mcChoices(diff, around: 3, exclude: [a, b], rng: &rng), correct: String(diff), grade: band)
    }

    private static func genMissingNumber(band: GradeBand, level: Int, rng: inout SeededRNG) -> NormalizedQuestion {
        let cap = band == .grade1 ? 10 : band == .grade2 ? 20 : 30
        let total = 5 + Int(rng.next() % UInt64(cap))
        let a = 1 + Int(rng.next() % UInt64(total - 1))
        let missing = total - a
        let blankFirst = Int(rng.next() % 2) == 0
        let equation = blankFirst ? "__ + \(a) = \(total)" : "\(a) + __ = \(total)"
        let choices = mcChoices(missing, around: 3, rng: &rng)
        return nq(subject: .math, skill: "missing number equations", component: "Blank Slot Builder", template: "Missing Number Equation",
                  prompt: equation,
                  directions: "Tap the number that fills the blank.",
                  source: "symbol_support_pack",
                  content: ["equation": equation, "chips": choices.joined(separator: ",")],
                  choices: choices, correct: String(missing), grade: band)
    }

    private static func genNumberLine(band: GradeBand, level: Int, rng: inout SeededRNG) -> NormalizedQuestion {
        // The NumberLineCard always renders ticks 0...12, so every start and
        // landing value must stay within that range regardless of grade band.
        let start = 2 + Int(rng.next() % 9) // 2...10
        let forward = Int(rng.next() % 2) == 0
        // Cap the jump so the landing never leaves 0...12.
        let room = forward ? (12 - start) : start
        // Level scaling: longer jumps at higher levels (jumpCap = 1 + level,
        // bounded by the remaining room and the 0...12 range).
        let lvl = max(1, level)
        let jumpCap = max(1, min(1 + lvl, room))
        let jump = 1 + Int(rng.next() % UInt64(jumpCap))
        let landing = forward ? start + jump : start - jump
        let prompt = forward
            ? "Start at \(start). Jump forward \(jump). Where do you land?"
            : "Start at \(start). Jump back \(jump). Where do you land?"
        return nq(subject: .math, skill: "number line jumps", component: "Number Line", template: "Number Line Jump",
                  prompt: prompt, directions: "Tap the landing number.",
                  source: "symbol_support_pack",
                  content: ["start": String(start), "jump": "\(forward ? "+" : "-")\(jump)", "range": "0-12"],
                  choices: mcChoices(landing, around: 2, rng: &rng), correct: String(landing), grade: band)
    }

    private static func genMakeTen(rng: inout SeededRNG) -> NormalizedQuestion {
        let filled = 4 + Int(rng.next() % 5) // 4..8
        let need = 10 - filled
        return nq(subject: .math, skill: "make ten", component: "Ten-Frame", template: "Make Ten",
                  prompt: "There are \(filled) dots. How many more make 10?",
                  directions: "Look at the empty spaces.",
                  source: "symbol_support_pack",
                  content: ["filled": String(filled), "empty": String(need)],
                  choices: mcChoices(need, around: 2, rng: &rng), correct: String(need), grade: .grade1)
    }

    private static func genSkipCounting(band: GradeBand, level: Int, rng: inout SeededRNG) -> NormalizedQuestion {
        // Difficulty scales with BOTH grade band and level: older grades skip by
        // bigger / less obvious steps and start from higher numbers.
        let gradeBoost: Int
        switch band {
        case .grade3: gradeBoost = 2
        case .grade2: gradeBoost = 1
        default: gradeBoost = 0
        }
        let tier = max(1, level) + gradeBoost
        let steps: [Int]
        switch tier {
        case ...1: steps = [2, 5]
        case 2: steps = [2, 5, 10]
        case 3: steps = [3, 4, 5, 10]
        case 4: steps = [3, 4, 6, 8, 10]
        default: steps = [4, 6, 7, 8, 9, 10, 25, 50]
        }
        let step = steps.randomElement(using: &rng) ?? 2
        let start = step * (1 + Int(rng.next() % UInt64(2 + tier)))
        let seq = (0..<4).map { start + step * $0 }
        let next = start + step * 4
        let seqText = seq.map(String.init).joined(separator: ", ") + ", __"
        return nq(subject: .math, skill: "skip counting", component: "Pattern Row", template: "Skip Counting Sequence",
                  prompt: "What comes next: \(seqText)?",
                  directions: "Count by \(step)s.",
                  source: "symbol_support_pack",
                  content: ["sequence": seqText],
                  choices: mcChoices(next, around: 3, rng: &rng), correct: String(next), grade: band)
    }

    private static func genArray(band: GradeBand, level: Int, rng: inout SeededRNG) -> NormalizedQuestion {
        // Level scaling: larger array dimensions at higher levels.
        // maxDim = min(2 + level, cap) where cap = 6 (grade2) or 8.
        let lvl = max(1, level)
        let cap = band == .grade2 ? 6 : 8
        let maxDim = max(3, min(2 + lvl, cap))
        let rows = 2 + Int(rng.next() % UInt64(maxDim - 1))
        let cols = 2 + Int(rng.next() % UInt64(maxDim - 1))
        let total = rows * cols
        let emoji = shapeEmojis.randomElement(using: &rng) ?? "⭐"
        return nq(subject: .math, skill: "multiplication arrays", component: "Array Builder", template: "Multiplication Arrays",
                  prompt: "\(rows) rows of \(cols) \(emoji). How many in all?",
                  directions: "Count the array or use \(rows) × \(cols).",
                  source: "shape_pack",
                  content: ["rows": String(rows), "columns": String(cols), "item": emoji],
                  choices: mcChoices(total, around: 4, rng: &rng), correct: String(total), grade: band)
    }

    private static func genDivision(band: GradeBand, level: Int, rng: inout SeededRNG) -> NormalizedQuestion {
        // Level scaling: larger share-per-group and more groups (kept even so the
        // tap-to-distribute interaction always resolves to an equal split).
        // per ∈ [2, 2+level], groups ∈ [2, 1+min(level,3)+1].
        let lvl = max(1, level)
        let per = 2 + Int(rng.next() % UInt64(1 + lvl))
        let groups = 2 + Int(rng.next() % UInt64(min(lvl, 3) + 1))
        let total = per * groups
        let emoji = animalEmojis.randomElement(using: &rng) ?? "🐟"
        return nq(subject: .math, skill: "division as sharing", component: "Grouping Buckets", template: "Division as Sharing",
                  prompt: "Share \(total) \(emoji) equally into \(groups) groups. How many in each?",
                  directions: "Put the same number in every group.",
                  source: "animal_pack",
                  content: ["objects": "\(emoji)x\(total)", "buckets": String(groups)],
                  choices: mcChoices(per, around: 2, rng: &rng), correct: String(per), grade: band)
    }

    private static func genPattern(band: GradeBand, level: Int, rng: inout SeededRNG) -> NormalizedQuestion {
        let lvl = max(1, level)
        // Numeric pattern at grade2+, shape pattern (AB / AAB / ABC) below.
        if band == .grade2 || band == .grade3 {
            // Level scaling: bigger step sizes and a longer visible sequence.
            let step = 2 + Int(rng.next() % UInt64(3 + lvl))
            let start = 1 + Int(rng.next() % 8)
            let terms = lvl >= 3 ? 5 : 4
            let seq = (0..<terms).map { start + step * $0 }
            let next = start + step * terms
            let seqText = seq.map(String.init).joined(separator: ", ") + ", __"
            return nq(subject: .math, skill: "pattern recognition", component: "Pattern Row", template: "Pattern Recognition",
                      prompt: "What comes next: \(seqText)?",
                      directions: "Find the rule.",
                      source: "symbol_support_pack",
                      content: ["sequence": seqText],
                      choices: mcChoices(next, around: 3, rng: &rng), correct: String(next), grade: band)
        } else {
            // Kindergarten / Grade 1: AB by default, with AAB and ABC variants
            // appearing more often as the level rises (within-grade progression).
            let a = shapeEmojis.randomElement(using: &rng) ?? "🔴"
            let b = shapeEmojis.filter { $0 != a }.randomElement(using: &rng) ?? "🔵"
            let c = shapeEmojis.filter { $0 != a && $0 != b }.randomElement(using: &rng) ?? "⭐"
            let distract = shapeEmojis.filter { $0 != a && $0 != b && $0 != c }.randomElement(using: &rng) ?? "🟢"
            // Roll for complexity: chance of a harder-than-AB pattern grows with level.
            let hardChance = min(20 + lvl * 15, 75)
            let roll = Int(rng.next() % 100)
            let unit: [String]
            if roll < hardChance {
                // ABC becomes more likely than AAB at higher levels.
                if Int(rng.next() % 100) < min(30 + lvl * 10, 70) {
                    unit = [a, b, c]               // ABC
                } else {
                    unit = [a, a, b]               // AAB
                }
            } else {
                unit = [a, b]                      // AB
            }
            // Show two full repeats of the unit, then the blank; the answer is the
            // first element of the unit (what continues the repeat).
            let shown = unit + unit
            let correct = unit[0]
            let seqText = (shown.map { $0 } + ["blank"]).joined(separator: ", ")
            let promptSeq = shown.joined(separator: " ")
            // Distractors: the other unit members plus a never-seen shape.
            var choicePool = Array(Set(unit)).filter { $0 != correct }
            choicePool.append(distract)
            var choices = ([correct] + Array(choicePool.prefix(2))).shuffled(using: &rng)
            if !choices.contains(correct) { choices[0] = correct }
            return nq(subject: .math, skill: "pattern recognition", component: "Pattern Row", template: "Pattern Recognition",
                      prompt: "What comes next? \(promptSeq) __",
                      directions: "Choose the missing piece.",
                      source: "shape_pack",
                      content: ["sequence": seqText],
                      choices: choices, correct: correct, grade: band)
        }
    }

    private static func genFraction(level: Int, rng: inout SeededRNG) -> NormalizedQuestion {
        // Level scaling: more parts (finer fractions) at higher levels.
        // level<=1 → [2,3,4]; level==2 → [2,3,4,6]; level>=3 → [3,4,6,8].
        let lvl = max(1, level)
        let partPool: [Int] = lvl <= 1 ? [2, 3, 4] : lvl == 2 ? [2, 3, 4, 6] : [3, 4, 6, 8]
        let parts = partPool.randomElement(using: &rng) ?? 4
        let filled = 1 + Int(rng.next() % UInt64(parts - 1))
        let correct = "\(filled)/\(parts)"
        var distractors: [String] = []
        let altParts = [2, 3, 4].filter { $0 != parts }
        for p in altParts.prefix(2) { distractors.append("1/\(p)") }
        var choices = ([correct] + distractors).shuffled(using: &rng)
        if !choices.contains(correct) { choices[0] = correct }
        return nq(subject: .math, skill: "fractions basics", component: "Fraction or Fill Bar", template: "Fractions",
                  prompt: "What fraction of the bar is shaded?",
                  directions: "Choose the matching fraction.",
                  source: "symbol_support_pack",
                  content: ["parts": String(parts), "filled": String(filled)],
                  choices: Array(choices.prefix(3)), correct: correct, grade: .grade3)
    }

    private static func genTime(band: GradeBand, level: Int, rng: inout SeededRNG) -> NormalizedQuestion {
        let hour = 1 + Int(rng.next() % 12)
        // Level scaling: finer minute increments at higher levels. The band sets a
        // floor; level can refine it further (0 → half-hour → quarter-hour).
        let lvl = max(1, level)
        let levelMinutes: [Int] = lvl <= 1 ? [0] : lvl == 2 ? [0, 30] : [0, 15, 30, 45]
        let bandMinutes: [Int]
        switch band {
        case .kindergarten, .grade1: bandMinutes = [0]
        case .grade2: bandMinutes = [0, 30]
        case .grade3: bandMinutes = [0, 15, 30, 45]
        }
        // Use whichever band/level allows the finer set.
        let minutePool = levelMinutes.count >= bandMinutes.count ? levelMinutes : bandMinutes
        let minute = minutePool.randomElement(using: &rng) ?? 0
        let correct = String(format: "%d:%02d", hour, minute)
        let altHour1 = hour == 12 ? 1 : hour + 1
        let altHour2 = hour == 1 ? 12 : hour - 1
        let distractors = [
            String(format: "%d:%02d", altHour1, minute),
            String(format: "%d:%02d", altHour2, minute),
            String(format: "%d:%02d", hour, minute == 0 ? 30 : 0)
        ]
        var choices = ([correct] + distractors).prefix(3).map { $0 }
        choices.shuffle(using: &rng)
        if !choices.contains(correct) { choices[0] = correct }
        return nq(subject: .math, skill: "telling time", component: "Clock Card", template: "Telling Time",
                  prompt: "What time does the clock show?",
                  directions: "Look at the hour and minute hands.",
                  source: "symbol_support_pack",
                  content: ["hour": String(hour), "minute": String(minute), "clock": "analog"],
                  choices: choices, correct: correct, grade: band)
    }

    /// Child-friendly, easy-to-count objects used for the quantity card.
    private static let compareObjects: [String] = [
        "🍎", "⭐️", "🐱", "🐶", "⚽️", "🍦", "📚", "✏️", "🌸", "🐟", "🚗", "🎈"
    ]

    private static func genCompare(band: GradeBand, level: Int, rng: inout SeededRNG) -> NormalizedQuestion {
        // A numeral vs. a counted group of objects. Keep both quantities close
        // (differ by 1–2) and small enough to actually count so the child must
        // compare a number against a visual quantity rather than two numerals.
        let base: Int
        switch band {
        case .kindergarten: base = 5 + Int(rng.next() % 4)   // 5...8
        case .grade1:       base = 6 + Int(rng.next() % 6)   // 6...11
        case .grade2:       base = 8 + Int(rng.next() % 7)   // 8...14
        case .grade3:       base = 9 + Int(rng.next() % 7)   // 9...15
        }
        let gap = 1 + Int(rng.next() % 2)                    // 1 or 2
        let other = Int(rng.next() % 2) == 0 ? base + gap : max(2, base - gap)
        let numberFirst = Int(rng.next() % 2) == 0
        let numberValue = numberFirst ? base : other
        let objectCount = numberFirst ? other : base
        let bigger = max(numberValue, objectCount)
        let emoji = compareObjects.randomElement(using: &rng) ?? "🍎"
        let prompt = ["Which is greater?", "Which is larger?", "Which has more?", "Which amount is bigger?"]
            .randomElement(using: &rng) ?? "Which is greater?"
        return nq(subject: .math, skill: "compare numbers", component: "Comparison Card Pair", template: "Compare Numbers",
                  prompt: prompt,
                  directions: "Count carefully before choosing.",
                  source: "symbol_support_pack",
                  content: [
                    "number": String(numberValue),
                    "objectEmoji": emoji,
                    "objectCount": String(objectCount),
                    "numberSide": numberFirst ? "left" : "right"
                  ],
                  choices: [String(numberValue), String(objectCount)],
                  correct: String(bigger), grade: band)
    }

    private static func genTimedBonus(band: GradeBand, level: Int, rng: inout SeededRNG) -> NormalizedQuestion {
        // A quick arithmetic question wrapped in a countdown ring for a bonus.
        let cap: Int
        switch band {
        case .kindergarten: cap = 5
        case .grade1: cap = 10
        case .grade2: cap = 20
        case .grade3: cap = 50
        }
        let a = 1 + Int(rng.next() % UInt64(cap))
        let b = 1 + Int(rng.next() % UInt64(cap))
        let plus = Int(rng.next() % 2) == 0 || a <= b
        let answer = plus ? a + b : a - b
        let symbol = plus ? "+" : "−"
        return nq(subject: .math, skill: "timed bonus", component: "Choice Card Row", template: "Timed Bonus",
                  prompt: "Quick! \(a) \(symbol) \(b) = ?",
                  directions: "Answer before the timer runs out for a bonus!",
                  source: "symbol_support_pack",
                  content: ["equation": "\(a) \(symbol) \(b)"],
                  choices: mcChoices(answer, around: 3, rng: &rng), correct: String(answer), grade: band)
    }

    // MARK: - English generators

    private static let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".map { String($0) }
    /// Visually/phonetically confusable UPPERCASE letters so recognition requires
    /// real discrimination, not elimination of obviously-different shapes.
    private static let upperConfusables: [String: [String]] = [
        "B": ["D", "P", "R"], "D": ["B", "O", "P"], "P": ["R", "B", "F"], "R": ["P", "B", "K"],
        "M": ["N", "W", "H"], "N": ["M", "H", "W"], "W": ["M", "V", "N"], "V": ["W", "Y", "U"],
        "S": ["C", "G", "Z"], "C": ["G", "O", "S"], "G": ["C", "O", "Q"], "O": ["Q", "C", "D"],
        "Q": ["O", "G", "C"], "E": ["F", "B", "L"], "F": ["E", "P", "T"], "T": ["I", "F", "L"],
        "I": ["L", "J", "T"], "L": ["I", "J", "T"], "J": ["I", "L", "U"], "U": ["V", "Y", "J"],
        "K": ["X", "R", "H"], "X": ["K", "Y", "V"], "Y": ["V", "X", "U"], "H": ["M", "N", "K"],
        "A": ["H", "R", "V"], "Z": ["S", "N", "X"]
    ]
    /// Confusable LOWERCASE letters (b/d/p/q etc. are the classic reversals).
    private static let lowerConfusables: [String: [String]] = [
        "b": ["d", "p", "h"], "d": ["b", "p", "q"], "p": ["q", "b", "g"], "q": ["p", "g", "d"],
        "m": ["n", "w", "h"], "n": ["m", "h", "r"], "w": ["m", "v", "u"], "v": ["w", "y", "u"],
        "a": ["e", "o", "c"], "e": ["a", "c", "o"], "o": ["c", "e", "a"], "c": ["e", "o", "a"],
        "g": ["q", "p", "y"], "h": ["b", "n", "k"], "i": ["j", "l", "t"], "l": ["i", "j", "t"],
        "j": ["i", "l", "g"], "u": ["v", "n", "w"], "r": ["n", "v", "k"], "k": ["h", "x", "b"],
        "f": ["t", "l", "r"], "t": ["f", "l", "i"], "s": ["c", "z", "e"], "y": ["v", "g", "x"],
        "x": ["k", "y", "z"], "z": ["s", "x", "n"]
    ]
    private static let cvcWords: [(String, String)] = [
        ("cat", "🐱"), ("dog", "🐶"), ("hat", "🎩"), ("bat", "🦇"), ("pig", "🐷"),
        ("sun", "☀️"), ("bus", "🚌"), ("cup", "☕"), ("fox", "🦊"), ("hen", "🐔"),
        ("bed", "🛏️"), ("car", "🚗"), ("map", "🗺️"), ("pen", "🖊️"),
        ("bee", "🐝"), ("cow", "🐮"), ("owl", "🦉"), ("egg", "🥚"), ("key", "🔑"),
        ("box", "📦"), ("ant", "🐜"), ("jet", "🛩️"),
        ("bag", "👜"), ("web", "🕸️"), ("rug", "🧶"), ("mug", "🍺"), ("van", "🚐"),
        ("log", "🪵"), ("pie", "🥧"), ("axe", "🪓"), ("fan", "🪭"), ("saw", "🪚"),
        ("nut", "🥜"), ("ram", "🐏"), ("bug", "🐛"), ("ear", "👂"), ("eye", "👁️")
    ]
    /// 4-letter words with an emoji — used to gently stretch younger grades.
    private static let fourLetterWords: [(String, String)] = [
        ("frog", "🐸"), ("fish", "🐟"), ("bear", "🐻"), ("duck", "🦆"), ("lion", "🦁"),
        ("star", "⭐"), ("moon", "🌙"), ("cake", "🍰"), ("boat", "⛵"), ("ball", "⚽"),
        ("bird", "🐦"), ("crab", "🦀"), ("leaf", "🍃"), ("corn", "🌽"), ("drum", "🥁"),
        ("goat", "🐐"), ("wolf", "🐺"), ("frog", "🐸"), ("bone", "🦴"), ("kite", "🪁"),
        ("lamp", "💡"), ("ring", "💍"), ("shoe", "👟"), ("sock", "🧦"), ("door", "🚪"),
        ("bell", "🔔"), ("book", "📖"), ("gift", "🎁"), ("hand", "✋"), ("foot", "🦶")
    ]
    /// Longer 5-6 letter words with an emoji — harder unscrambles for older grades.
    private static let longerWords: [(String, String)] = [
        ("monkey", "🐒"), ("rabbit", "🐰"), ("turtle", "🐢"), ("banana", "🍌"),
        ("apple", "🍎"), ("school", "🏫"), ("flower", "🌸"), ("garden", "🌳"),
        ("rocket", "🚀"), ("dragon", "🐉"), ("pizza", "🍕"), ("tiger", "🐯"),
        ("zebra", "🦓"), ("panda", "🐼"), ("snake", "🐍"), ("whale", "🐳"),
        ("train", "🚆"), ("robot", "🤖"), ("grapes", "🍇"), ("cherry", "🍒"),
        ("guitar", "🎸"), ("pencil", "✏️"), ("castle", "🏰"), ("cookie", "🍪"),
        ("camel", "🐫"), ("mouse", "🐭"), ("truck", "🚚"), ("crown", "👑"),
        ("koala", "🐨"), ("horse", "🐴"), ("sheep", "🐑"), ("chick", "🐤"),
        ("lemon", "🍋"), ("melon", "🍈"), ("peach", "🍑"), ("onion", "🧅"),
        ("plane", "✈️"), ("anchor", "⚓"), ("bridge", "🌉"), ("violin", "🎻"),
        ("rainbow", "🌈"), ("pumpkin", "🎃"), ("island", "🏝️"), ("planet", "🪐"),
        ("parrot", "🦜"), ("donkey", "🫏"), ("flute", "🪈"), ("cactus", "🌵")
    ]
    private static let sightWordsK = ["the", "and", "is", "you", "to", "see", "we", "go"]
    private static let sightWords1 = ["was", "are", "have", "they", "with", "from", "this", "that"]
    private static let sightWords2 = ["because", "people", "their", "would", "could", "should", "about", "around"]
    private static let sightWords3 = ["thought", "through", "different", "another", "important", "together"]
    /// Look-alike distractor sets so the challenge is visual discrimination, not
    /// matching identical text. Each entry: target -> two similar-looking words.
    private static let sightWordConfusables: [String: [String]] = [
        "the": ["they", "then"], "and": ["end", "any"], "is": ["if", "it"],
        "you": ["your", "our"], "to": ["too", "toy"], "see": ["sea", "sees"],
        "we": ["me", "wet"], "go": ["got", "do"],
        "was": ["saw", "has"], "are": ["ore", "arm"], "have": ["gave", "hare"],
        "they": ["then", "them"], "with": ["wish", "width"], "from": ["form", "farm"],
        "this": ["thin", "that"], "that": ["than", "chat"],
        "because": ["became", "before"], "people": ["purple", "pebble"],
        "their": ["there", "these"], "would": ["could", "wound"],
        "could": ["cloud", "would"], "should": ["shout", "shoulder"],
        "about": ["above", "abort"], "around": ["aground", "round"],
        "thought": ["through", "though"], "through": ["thorough", "thought"],
        "different": ["difficult", "deferent"], "another": ["anther", "mother"],
        "important": ["imported", "impatient"], "together": ["tighter", "toughened"]
    ]
    private static let rhymePairs: [(String, [String])] = [
        ("cat", ["hat", "bat", "mat"]),
        ("dog", ["log", "fog", "jog"]),
        ("night", ["light", "sight", "fight"]),
        ("ring", ["king", "sing", "wing"]),
        ("bell", ["tell", "fell", "well"]),
        ("car", ["star", "far", "jar"])
    ]
    private static let wordFamilies: [(String, [String], [String])] = [
        ("-at", ["cat", "hat", "bat", "mat"], ["dog", "cup", "pen"]),
        ("-ig", ["pig", "wig", "big", "dig"], ["pan", "bug", "cat"]),
        ("-op", ["top", "hop", "mop", "pop"], ["bat", "sun", "hen"]),
        ("-un", ["sun", "run", "fun", "bun"], ["cat", "dog", "log"])
    ]
    private static let nouns = ["dog", "cat", "school", "book", "apple", "house", "happiness", "garden"]
    private static let verbs = ["jump", "run", "swim", "read", "eat", "sleep", "sing", "dance"]
    private static let vocabSynonyms: [(String, String, [String])] = [
        ("happy", "joyful", ["angry", "tired"]),
        ("big", "huge", ["small", "tiny"]),
        ("fast", "quick", ["slow", "still"]),
        ("smart", "clever", ["silly", "lazy"])
    ]
    /// Picture-vocabulary grouped by category so a word's distractors always
    /// come from the SAME category (e.g. matching "monkey" only shows other
    /// animals — never an unrelated object). This is what makes the question
    /// require real word knowledge instead of being solvable by elimination.
    private static let vocabCategories: [[(String, String)]] = [
        [("cat", "🐱"), ("dog", "🐶"), ("pig", "🐷"), ("fox", "🦊"), ("hen", "🐔"),
         ("monkey", "🐒"), ("rabbit", "🐰"), ("turtle", "🐢"), ("dragon", "🐉"),
         ("tiger", "🐯"), ("horse", "🐴"), ("sheep", "🐑"), ("koala", "🐨"),
         ("panda", "🐼"), ("zebra", "🦓"), ("mouse", "🐭"), ("snake", "🐍")],
        [("apple", "🍎"), ("banana", "🍌"), ("cookie", "🍪"), ("pizza", "🍕"),
         ("carrot", "🥕"), ("corn", "🌽"), ("bread", "🍞"),
         ("lemon", "🍋"), ("peach", "🍑"), ("grapes", "🍇"), ("cherry", "🍒"),
         ("melon", "🍈"), ("onion", "🧅")],
        [("car", "🚗"), ("bus", "🚌"), ("rocket", "🚀"), ("bed", "🛏️"),
         ("pen", "🖊️"), ("book", "📚"), ("clock", "⏰"),
         ("train", "🚆"), ("truck", "🚚"), ("plane", "✈️"), ("boat", "⛵"),
         ("lamp", "💡"), ("key", "🔑")],
        [("flower", "🌸"), ("tree", "🌳"), ("sun", "☀️"), ("star", "⭐"),
         ("cloud", "☁️"), ("moon", "🌙"),
         ("rainbow", "🌈"), ("leaf", "🍃"), ("cactus", "🌵"), ("island", "🏝️")]
    ]

    /// Picture clues whose word clearly starts with the paired letter. Used so a
    /// letter-recognition question shows an emoji and asks which letter it starts
    /// with — the target letter is never named in the prompt.
    private static let letterPicturePool: [(String, String)] = [
        ("A", "🍎"), ("B", "🐻"), ("C", "🐱"), ("D", "🐶"), ("E", "🥚"),
        ("F", "🐸"), ("G", "🐐"), ("H", "🎩"), ("L", "🦁"), ("M", "🐵"),
        ("O", "🐙"), ("P", "🐷"), ("R", "🐰"), ("S", "🐍"), ("T", "🐢"),
        ("U", "☂️"), ("V", "🎻"), ("W", "🐺"), ("Z", "🦓")
    ]

    private static func genLetter(rng: inout SeededRNG) -> NormalizedQuestion {
        // Show a picture and ask which letter its word starts with — the answer
        // letter is never written in the prompt.
        let pick = letterPicturePool.randomElement(using: &rng) ?? ("M", "🐵")
        let target = pick.0
        // Prefer look-alike distractors so the child must visually discriminate.
        let distractors: [String]
        if let confusable = upperConfusables[target] {
            distractors = Array(confusable.shuffled(using: &rng).prefix(2))
        } else {
            distractors = Array(letters.filter { $0 != target }.shuffled(using: &rng).prefix(2))
        }
        var choices = ([target] + distractors).shuffled(using: &rng)
        if !choices.contains(target) { choices[0] = target }
        return nq(subject: .english, skill: "letter recognition", component: "Letter Tile", template: "Letter Recognition",
                  prompt: "Which letter does \(pick.1) start with?",
                  directions: "Tap the first letter of the picture.",
                  source: "letter_pack",
                  content: ["target": target, "emoji": pick.1],
                  choices: choices, correct: target, grade: .kindergarten)
    }

    private static func genUpperLower(rng: inout SeededRNG) -> NormalizedQuestion {
        let upper = letters.randomElement(using: &rng) ?? "B"
        let lower = upper.lowercased()
        // Visually similar lowercase distractors (b/d/p reversals etc.).
        let distractors: [String]
        if let confusable = lowerConfusables[lower] {
            distractors = Array(confusable.shuffled(using: &rng).prefix(2))
        } else {
            distractors = Array(letters.filter { $0 != upper }.shuffled(using: &rng).prefix(2).map { $0.lowercased() })
        }
        var choices = ([lower] + Array(distractors)).shuffled(using: &rng)
        if !choices.contains(lower) { choices[0] = lower }
        return nq(subject: .english, skill: "uppercase-lowercase", component: "Matching Card Set", template: "Uppercase-Lowercase Matching",
                  prompt: "Match \(upper) to its lowercase letter.",
                  directions: "Tap its matching lowercase letter.",
                  source: "letter_pack",
                  content: ["uppercase": upper],
                  choices: choices, correct: lower, grade: .kindergarten)
    }

    private static func genBeginningSound(rng: inout SeededRNG) -> NormalizedQuestion {
        // Emoji-only choices: the child matches the target letter to the picture
        // whose word starts with that sound. No written words, no audio.
        let pool: [(String, String)] = [("b", "🐻"), ("s", "🐍"), ("c", "🐱"),
                                        ("d", "🐶"), ("f", "🐸"), ("r", "🐰")]
        let pick = pool.randomElement(using: &rng) ?? ("b", "🐻")
        let others = pool.filter { $0.0 != pick.0 }.shuffled(using: &rng).prefix(2).map { $0.1 }
        var choices = ([pick.1] + others).shuffled(using: &rng)
        if !choices.contains(pick.1) { choices[0] = pick.1 }
        return nq(subject: .english, skill: "beginning sounds", component: "Choice Card Row", template: "Beginning Sounds",
                  prompt: "Which picture starts with the letter \(pick.0.uppercased())?",
                  directions: "Tap the picture that starts with \(pick.0.uppercased()).",
                  source: "animal_vocab_pack",
                  content: ["sound": pick.0],
                  choices: choices, correct: pick.1, grade: .kindergarten)
    }

    private static func genMissingLetter(rng: inout SeededRNG) -> NormalizedQuestion {
        let pair = cvcWords.randomElement(using: &rng) ?? ("cat", "🐱")
        let word = pair.0
        let emoji = pair.1
        // Hide a vowel if present, else first letter.
        let vowels = Set("aeiou".map { String($0) })
        let chars = word.map { String($0) }
        let hideIndex: Int = chars.firstIndex(where: { vowels.contains($0) }) ?? 0
        let missing = chars[hideIndex]
        let displayed = chars.enumerated().map { i, c in i == hideIndex ? "_" : c }.joined()
        let promptShown = chars.enumerated().map { i, c in i == hideIndex ? "_" : c }.joined(separator: " ")
        var distractors = ["a", "o", "i", "e", "u"].filter { $0 != missing }.shuffled(using: &rng).prefix(2).map { $0 }
        var choices = ([missing] + Array(distractors)).shuffled(using: &rng)
        if !choices.contains(missing) { choices[0] = missing }
        return nq(subject: .english, skill: "missing letter", component: "Blank Slot Builder", template: "Missing Letter",
                  prompt: promptShown,
                  directions: "Use the picture to choose the missing letter.",
                  source: "cvc_pack",
                  content: ["wordWithBlank": displayed, "emoji": emoji],
                  choices: choices, correct: missing, grade: .kindergarten)
    }

    private static func genSpelling(band: GradeBand, rng: inout SeededRNG) -> NormalizedQuestion {
        let pool = longerWords + [("friend", "🤝"), ("because", "❓"), ("favorite", "⭐"), ("school", "🏫")]
        let pick = pool.randomElement(using: &rng) ?? ("school", "🏫")
        let word = pick.0
        // Build two misspellings: drop a letter, swap two letters.
        var dropped = word
        if dropped.count > 3 { dropped.remove(at: dropped.index(dropped.startIndex, offsetBy: 2)) }
        var swapped = Array(word)
        if swapped.count > 3 {
            swapped.swapAt(1, 2)
        }
        let swappedStr = String(swapped)
        var choices = [dropped, word, swappedStr].shuffled(using: &rng)
        if !choices.contains(word) { choices[0] = word }
        return nq(subject: .english, skill: "spelling", component: "Choice Card Row", template: "Choose Correct Spelling",
                  prompt: "Which word is spelled correctly? \(pick.1)",
                  directions: "Tap the correct spelling.",
                  source: "common_school_words_pack",
                  content: ["meaning": word],
                  choices: choices, correct: word, grade: band)
    }

    private static func genUnscramble(band: GradeBand, level: Int, rng: inout SeededRNG) -> NormalizedQuestion {
        // Word length scales with grade so older kids unscramble longer, harder
        // words (more letters out of place) while younger kids stay on CVC words.
        let pool: [(String, String)]
        switch band {
        case .grade3:
            pool = longerWords.filter { $0.0.count >= 5 }
        case .grade2:
            pool = fourLetterWords + longerWords.filter { $0.0.count <= 5 }
        case .grade1:
            pool = cvcWords + fourLetterWords
        default: // preschool, kindergarten
            pool = cvcWords
        }
        let pick = pool.randomElement(using: &rng) ?? ("dog", "🐶")
        let word = pick.0
        var letters = Array(word).map { String($0) }
        // Ensure shuffle doesn't equal original
        var attempts = 0
        var scrambled = letters
        repeat {
            scrambled.shuffle(using: &rng)
            attempts += 1
        } while scrambled.joined() == word && attempts < 6
        let lettersStr = scrambled.joined(separator: ",")
        let promptLetters = scrambled.joined(separator: "  ")
        return nq(subject: .english, skill: "unscramble", component: "Word Builder Tray", template: "Unscramble Word",
                  prompt: "Unscramble these letters: \(promptLetters)",
                  directions: "Tap the letters in the right order.",
                  source: "cvc_pack",
                  content: ["letters": lettersStr, "hint": pick.1],
                  choices: [word], correct: word, grade: band)
    }

    private static func genRhyme(rng: inout SeededRNG) -> NormalizedQuestion {
        let pick = rhymePairs.randomElement(using: &rng) ?? ("cat", ["hat"])
        let target = pick.0
        let rhyme = pick.1.randomElement(using: &rng) ?? "hat"
        let nonRhymes = ["dog", "sun", "fish", "tree", "book", "moon"].filter { !$0.hasSuffix(String(target.suffix(2))) }
        var distractors = Array(nonRhymes.shuffled(using: &rng).prefix(2))
        var choices = ([rhyme] + distractors).shuffled(using: &rng)
        if !choices.contains(rhyme) { choices[0] = rhyme }
        return nq(subject: .english, skill: "rhyming", component: "Pattern Row", template: "Rhyming Words",
                  prompt: "Which word rhymes with \(target)?",
                  directions: "Choose the rhyming word.",
                  source: "word_family_pack",
                  content: ["target": target],
                  choices: choices, correct: rhyme, grade: .grade1)
    }

    private static func genVocab(band: GradeBand, rng: inout SeededRNG) -> NormalizedQuestion {
        if band == .grade2 || band == .grade3 {
            let pick = vocabSynonyms.randomElement(using: &rng) ?? ("happy", "joyful", ["angry", "tired"])
            var choices = ([pick.1] + pick.2).shuffled(using: &rng)
            if !choices.contains(pick.1) { choices[0] = pick.1 }
            return nq(subject: .english, skill: "vocabulary", component: "Choice Card Row", template: "Vocabulary Matching",
                      prompt: "Which word means the same as \(pick.0)?",
                      directions: "Choose the best synonym.",
                      source: "emotion_pack",
                      content: ["word": pick.0],
                      choices: choices, correct: pick.1, grade: band)
        }
        // Same-category distractors only — see `vocabCategories`.
        let category = vocabCategories.randomElement(using: &rng) ?? vocabCategories[0]
        let pick = category.randomElement(using: &rng) ?? ("apple", "🍎")
        let others = category.filter { $0.0 != pick.0 }.shuffled(using: &rng).prefix(2).map { $0.1 }
        var choices = ([pick.1] + Array(others)).shuffled(using: &rng)
        if !choices.contains(pick.1) { choices[0] = pick.1 }
        return nq(subject: .english, skill: "vocabulary", component: "Matching Card Set", template: "Vocabulary Matching",
                  prompt: "Match \(pick.0) to its picture.",
                  directions: "Choose the matching emoji.",
                  source: "food_vocab_pack",
                  content: ["word": pick.0],
                  choices: choices, correct: pick.1, grade: band)
    }

    /// Sentence frames with a blank so the sight word is found by context, not by
    /// matching identical text. The blank is shown as "___".
    private static let sightWordSentences: [String: String] = [
        "the": "I see ___ dog.", "and": "I have a cat ___ a dog.", "is": "The sun ___ hot.",
        "you": "How are ___ today?", "to": "I want ___ play.", "see": "I can ___ the bird.",
        "we": "Today ___ will have fun.", "go": "Let's ___ to the park.",
        "was": "The puppy ___ happy.", "are": "We ___ best friends.", "have": "I ___ two apples.",
        "they": "Look, ___ are playing.", "with": "Come ___ me.", "from": "This gift is ___ Grandma.",
        "this": "I like ___ book.", "that": "Look at ___ bird.",
        "because": "I smiled ___ I was happy.", "people": "Many ___ live here.",
        "their": "The kids found ___ shoes.", "would": "___ you like a snack?",
        "could": "She ___ run very fast.", "should": "We ___ share our toys.",
        "about": "Tell me ___ your day.", "around": "We walked ___ the lake.",
        "thought": "I ___ about the story.", "through": "We walked ___ the door.",
        "different": "These shoes are ___ colors.", "another": "May I have ___ cookie?",
        "important": "It is ___ to be kind.", "together": "We can play ___."
    ]

    private static func genSightWord(band: GradeBand, rng: inout SeededRNG) -> NormalizedQuestion {
        let pool: [String]
        switch band {
        case .kindergarten: pool = sightWordsK
        case .grade1: pool = sightWords1 + sightWordsK
        case .grade2: pool = sightWords2 + sightWords1
        case .grade3: pool = sightWords3 + sightWords2
        }
        let target = pool.randomElement(using: &rng) ?? "the"
        // Prefer look-alike distractors so the child must visually discriminate.
        let distractors: [String]
        if let confusable = sightWordConfusables[target] {
            distractors = confusable
        } else {
            distractors = pool.filter { $0 != target }.shuffled(using: &rng).prefix(2).map { $0 }
        }
        var choices = ([target] + distractors).shuffled(using: &rng)
        if !choices.contains(target) { choices[0] = target }
        let sentence = sightWordSentences[target] ?? "I can read the word ___."
        return nq(subject: .english, skill: "sight words", component: "Choice Card Row", template: "Sight Word Recognition",
                  prompt: sentence,
                  directions: "Tap the word that completes the sentence.",
                  source: "sight_words_pack",
                  content: ["target": target, "sentence": sentence],
                  choices: choices, correct: target, grade: band)
    }

    private static func genWordFamily(rng: inout SeededRNG) -> NormalizedQuestion {
        let pick = wordFamilies.randomElement(using: &rng) ?? ("-at", ["cat"], ["dog"])
        let correct = pick.1.randomElement(using: &rng) ?? "cat"
        let other = pick.2.randomElement(using: &rng) ?? "dog"
        let other2 = pick.2.filter { $0 != other }.randomElement(using: &rng) ?? "sun"
        var choices = [correct, other, other2].shuffled(using: &rng)
        if !choices.contains(correct) { choices[0] = correct }
        let pair = pick.1.filter { $0 != correct }.prefix(2).joined(separator: " and ")
        return nq(subject: .english, skill: "word families", component: "Pattern Row", template: "Word Families",
                  prompt: "Which word belongs with \(pair)?",
                  directions: "Find the \(pick.0) word.",
                  source: "word_family_pack",
                  content: ["family": pick.0],
                  choices: choices, correct: correct, grade: .grade1)
    }

    /// Short sentences for K–Grade 2. Kept large and varied so the cross-lesson
    /// de-dup (which keys on the full sentence) almost never has to repeat one.
    private static let simpleSentences: [String] = [
        "The dog runs.", "I see a cat.", "We go home.", "She read a book.",
        "The sun is hot.", "A bird can fly.", "He has a ball.", "My mom is kind.",
        "The fish can swim.", "We like to play.", "The cat is soft.", "I love my dad.",
        "The frog can jump.", "She rode a bike.", "We see the moon.", "The bus is big.",
        "A cow says moo.", "He ate the cake.", "The tree is tall.", "I can count ten.",
        "The duck is wet.", "We made a fort.", "My pen is red.", "The bee can buzz.",
        "She sang a song.", "The ant is small.", "We ran very fast.", "He found a rock.",
        "The pig is pink.", "I drew a star."
    ]

    /// Longer Grade 3 sentences with an adjective or adverb for richer ordering.
    private static let grade3Sentences: [String] = [
        "The big dog ran quickly.", "A small cat sat softly.", "The bright sun shines warmly.",
        "The happy boy jumped high.", "A tiny bird sang sweetly.", "The cold wind blew hard.",
        "The brave girl climbed slowly.", "A green frog leaped far.", "The old truck moved loudly.",
        "The kind teacher smiled gently.", "A fast train rushed past.", "The red apple fell down.",
        "The wet dog shook hard.", "A bright star glowed softly.", "The young deer ran away.",
        "The tall tree swayed gently.", "A loud bell rang twice.", "The new shoes felt great.",
        "The hungry cat meowed loudly.", "A warm fire crackled softly.", "The clever fox hid quietly.",
        "The little duck swam slowly.", "A heavy rain poured down.", "The proud lion roared loudly.",
        "The sleepy baby yawned softly.", "A shiny coin rolled away.", "The strong horse galloped fast.",
        "The gentle breeze felt cool.", "A bright kite flew high.", "The busy bee worked hard."
    ]

    private static func genSentence(band: GradeBand, rng: inout SeededRNG) -> NormalizedQuestion {
        let templates: [String] = band == .grade3 ? grade3Sentences : simpleSentences
        let sentence = templates.randomElement(using: &rng) ?? "The dog runs."
        let stripped = sentence.replacingOccurrences(of: ".", with: "")
        let tokens = stripped.split(separator: " ").map(String.init).shuffled(using: &rng)
        return nq(subject: .english, skill: "sentence building", component: "Sentence Strip", template: "Sentence Building",
                  prompt: "Put the words in order to make a sentence.",
                  directions: "Tap the words in the right order.",
                  source: "simple_nouns_pack",
                  content: ["tokens": tokens.joined(separator: ",")],
                  choices: [sentence], correct: sentence, grade: band)
    }

    private static let memoryEmojiPairs: [(String, String)] = [
        ("🐱", "cat"), ("🐶", "dog"), ("🍎", "apple"), ("☀️", "sun"),
        ("🚗", "car"), ("📚", "book"), ("🌸", "flower"), ("⭐", "star")
    ]

    private static func genMemoryMatch(band: GradeBand, rng: inout SeededRNG) -> NormalizedQuestion {
        // Kindergarten: uppercase↔lowercase. Older grades: word↔picture.
        let pairs: [(String, String)]
        let prompt: String
        if band == .kindergarten {
            let picks = letters.shuffled(using: &rng).prefix(3).map { $0 }
            pairs = picks.map { ($0, $0.lowercased()) }
            prompt = "Match each capital letter to its lowercase."
        } else {
            let count = band == .grade1 ? 3 : 4
            let picks = memoryEmojiPairs.shuffled(using: &rng).prefix(count)
            pairs = picks.map { ($0.0, $0.1) }
            prompt = "Find the matching pairs."
        }
        let encoded = pairs.map { "\($0.0)|\($0.1)" }.joined(separator: ",")
        return nq(subject: .english, skill: "memory match", component: "Memory Cards", template: "Memory Match",
                  prompt: prompt,
                  directions: "Tap two cards to find a pair.",
                  source: "letter_pack",
                  content: ["pairs": encoded],
                  choices: ["matched"], correct: "matched", grade: band)
    }

    private static let sortGroups: [(String, String, [String], [String])] = [
        ("Animals", "Food", ["🐶 dog", "🐱 cat", "🐰 rabbit"], ["🍎 apple", "🍕 pizza", "🍪 cookie"]),
        ("Animals", "Things", ["🐸 frog", "🐢 turtle", "🐍 snake"], ["🚗 car", "📚 book", "⭐ star"]),
        ("Nouns", "Verbs", ["dog", "book", "school"], ["run", "jump", "read"]),
        ("Food", "Plants", ["🍌 banana", "🥕 carrot", "🌽 corn"], ["🌸 flower", "🌳 tree", "🌱 sprout"])
    ]

    private static func genWordSort(band: GradeBand, rng: inout SeededRNG) -> NormalizedQuestion {
        // Grammar sort (Nouns/Verbs) at grade2+, picture-category sort below.
        let group: (String, String, [String], [String])
        if band == .grade2 || band == .grade3 {
            group = sortGroups[2]
        } else {
            group = [sortGroups[0], sortGroups[1], sortGroups[3]].randomElement(using: &rng) ?? sortGroups[0]
        }
        let perBucket = band == .kindergarten ? 2 : 3
        let aItems = Array(group.2.shuffled(using: &rng).prefix(perBucket))
        let bItems = Array(group.3.shuffled(using: &rng).prefix(perBucket))
        let items = (aItems.map { "\($0)|\(group.0)" } + bItems.map { "\($0)|\(group.1)" }).shuffled(using: &rng).joined(separator: ",")
        return nq(subject: .english, skill: "word sort", component: "Sort Buckets", template: "Category Sort",
                  prompt: "Sort each into \(group.0) or \(group.1).",
                  directions: "Tap an item, then tap its bucket.",
                  source: "word_packs",
                  content: ["buckets": "\(group.0),\(group.1)", "items": items],
                  choices: ["sorted"], correct: "sorted", grade: band)
    }

    private static func genPunctuation(rng: inout SeededRNG) -> NormalizedQuestion {
        let pool: [(String, String)] = [
            ("Where are you", "?"),
            ("We won the game", "!"),
            ("The cat is happy", "."),
            ("Look at the bird", "!"),
            ("Is that your book", "?")
        ]
        let pick = pool.randomElement(using: &rng) ?? ("Where are you", "?")
        return nq(subject: .english, skill: "punctuation", component: "Sentence Strip", template: "Punctuation Choice",
                  prompt: "\(pick.0) __",
                  directions: "Choose the correct punctuation mark.",
                  source: "symbol_support_pack",
                  content: ["sentence": pick.0],
                  choices: [".", "?", "!"], correct: pick.1, grade: .grade1)
    }
}
