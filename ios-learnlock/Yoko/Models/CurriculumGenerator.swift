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
    // English
    case letterRecognition, uppercaseLowercase, beginningSound, missingLetter
    case spelling, unscramble, rhyming, vocabulary, sightWord, wordFamily, sentenceBuilding, punctuation

    var subject: Subject {
        switch self {
        case .counting, .addition, .subtraction, .missingNumber, .numberLine, .makeTen,
             .skipCounting, .multiplicationArray, .divisionSharing, .patterns, .fractions, .time, .compareNumbers:
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
        .kindergarten: [.counting, .addition, .subtraction, .makeTen, .patterns, .compareNumbers],
        .grade1: [.counting, .addition, .subtraction, .makeTen, .missingNumber, .numberLine, .patterns, .compareNumbers, .time],
        .grade2: [.addition, .subtraction, .missingNumber, .numberLine, .skipCounting, .patterns, .compareNumbers, .time, .multiplicationArray],
        .grade3: [.missingNumber, .numberLine, .skipCounting, .multiplicationArray, .divisionSharing, .fractions, .time, .compareNumbers, .patterns]
    ]
    static let englishPool: [GradeBand: [CurriculumSkill]] = [
        .kindergarten: [.letterRecognition, .uppercaseLowercase, .beginningSound, .missingLetter, .vocabulary, .sightWord],
        .grade1: [.beginningSound, .missingLetter, .unscramble, .rhyming, .vocabulary, .sightWord, .wordFamily, .sentenceBuilding, .punctuation],
        .grade2: [.spelling, .unscramble, .rhyming, .vocabulary, .sightWord, .wordFamily, .sentenceBuilding, .punctuation],
        .grade3: [.spelling, .unscramble, .vocabulary, .sightWord, .sentenceBuilding, .punctuation]
    ]

    static func skills(subject: Subject, grade: GradeBand) -> [CurriculumSkill] {
        subject == .math ? (mathPool[grade] ?? []) : (englishPool[grade] ?? [])
    }

    // MARK: Lesson / batch

    static func generateLesson(subject: Subject, grade: Int, focus: CurriculumSkill? = nil, level: Int = 1, seed: UInt64) -> Lesson {
        var rng = SeededRNG(seed)
        let band = gradeBand(for: grade)
        let boost = levelBoost(for: grade)
        let pool = skills(subject: subject, grade: band)
        let fallback: CurriculumSkill = subject == .math ? .counting : .letterRecognition
        let focusSkill = focus ?? pool.randomElement(using: &rng) ?? fallback
        let count = 3 // every lesson is exactly 3 questions
        var qs: [NormalizedQuestion] = []
        var seenPrompts = Set<String>()
        var safety = 0
        while qs.count < count && safety < 40 {
            safety += 1
            // Alternate focus skill with related siblings for spaced practice.
            let useFocus = (qs.count == 0) || (qs.count == count - 1) || pool.count <= 1
            let skill = useFocus ? focusSkill : (pool.randomElement(using: &rng) ?? focusSkill)
            let candidate = generate(skill: skill, band: band, level: level + boost, rng: &rng)
            // Avoid showing the same question twice inside one lesson.
            guard seenPrompts.insert(candidate.prompt).inserted else { continue }
            qs.append(candidate)
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
            lessons.append(generateLesson(subject: subject, grade: grade, focus: focus, level: level, seed: seed))
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

    private static func mcChoices(_ correct: Int, around: Int = 2, rng: inout SeededRNG) -> [String] {
        var pool = Set<Int>()
        pool.insert(correct)
        var attempts = 0
        while pool.count < 3 && attempts < 20 {
            let delta = 1 + Int(rng.next() % UInt64(around + 1))
            let sign = Int(rng.next() % 2) == 0 ? -1 : 1
            let v = max(0, correct + sign * delta)
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
        let a = 2 + Int(rng.next() % UInt64(scale))
        let b = Int(rng.next() % UInt64(a))
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
                  choices: mcChoices(diff, around: 3, rng: &rng), correct: String(diff), grade: band)
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
                  directions: "Drag the missing number into the blank.",
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
        let jumpCap = max(1, min(5, room))
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
        let steps = [2, 5, 10]
        let step = steps.randomElement(using: &rng) ?? 2
        let start = step * (1 + Int(rng.next() % 3))
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
        let maxDim = band == .grade2 ? 5 : 6
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
        let per = 2 + Int(rng.next() % 5)
        let groups = 2 + Int(rng.next() % 4)
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
        // Numeric pattern at grade2+, shape AB at lower grades.
        if band == .grade2 || band == .grade3 {
            let step = 2 + Int(rng.next() % 5)
            let start = 1 + Int(rng.next() % 8)
            let seq = (0..<4).map { start + step * $0 }
            let next = start + step * 4
            let seqText = seq.map(String.init).joined(separator: ", ") + ", __"
            return nq(subject: .math, skill: "pattern recognition", component: "Pattern Row", template: "Pattern Recognition",
                      prompt: "What comes next: \(seqText)?",
                      directions: "Find the rule.",
                      source: "symbol_support_pack",
                      content: ["sequence": seqText],
                      choices: mcChoices(next, around: 3, rng: &rng), correct: String(next), grade: band)
        } else {
            let a = shapeEmojis.randomElement(using: &rng) ?? "🔴"
            let b = shapeEmojis.filter { $0 != a }.randomElement(using: &rng) ?? "🔵"
            let distract = shapeEmojis.filter { $0 != a && $0 != b }.randomElement(using: &rng) ?? "⭐"
            let seqText = "\(a), \(b), \(a), \(b), blank"
            return nq(subject: .math, skill: "pattern recognition", component: "Pattern Row", template: "Pattern Recognition",
                      prompt: "What comes next? \(a) \(b) \(a) \(b) __",
                      directions: "Choose the missing piece.",
                      source: "shape_pack",
                      content: ["sequence": seqText],
                      choices: [a, b, distract].shuffled(using: &rng), correct: a, grade: band)
        }
    }

    private static func genFraction(level: Int, rng: inout SeededRNG) -> NormalizedQuestion {
        let parts = [2, 3, 4, 6, 8].randomElement(using: &rng) ?? 4
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
        let minute: Int
        switch band {
        case .kindergarten, .grade1: minute = 0
        case .grade2: minute = Int(rng.next() % 2) == 0 ? 0 : 30
        case .grade3: minute = [0, 15, 30, 45].randomElement(using: &rng) ?? 0
        }
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

    private static func genCompare(band: GradeBand, level: Int, rng: inout SeededRNG) -> NormalizedQuestion {
        let cap = band == .grade1 ? 20 : band == .grade2 ? 100 : 999
        let a = 1 + Int(rng.next() % UInt64(cap))
        var b = 1 + Int(rng.next() % UInt64(cap))
        if b == a { b = a + 1 }
        let bigger = max(a, b)
        return nq(subject: .math, skill: "compare numbers", component: "Comparison Card Pair", template: "Compare Numbers",
                  prompt: "Which number is bigger: \(a) or \(b)?",
                  directions: "Tap the larger number.",
                  source: "symbol_support_pack",
                  content: ["left": String(a), "right": String(b)],
                  choices: [String(a), String(b)], correct: String(bigger), grade: band)
    }

    // MARK: - English generators

    private static let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".map { String($0) }
    private static let cvcWords: [(String, String)] = [
        ("cat", "🐱"), ("dog", "🐶"), ("hat", "🎩"), ("bat", "🦇"), ("pig", "🐷"),
        ("sun", "☀️"), ("bus", "🚌"), ("cup", "☕"), ("fox", "🦊"), ("hen", "🐔"),
        ("bed", "🛏️"), ("car", "🚗"), ("map", "🗺️"), ("pen", "🖊️")
    ]
    private static let longerWords: [(String, String)] = [
        ("monkey", "🐒"), ("rabbit", "🐰"), ("turtle", "🐢"), ("banana", "🍌"),
        ("apple", "🍎"), ("school", "🏫"), ("flower", "🌸"), ("garden", "🌳"),
        ("rocket", "🚀"), ("dragon", "🐉")
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

    private static func genLetter(rng: inout SeededRNG) -> NormalizedQuestion {
        let target = letters.randomElement(using: &rng) ?? "M"
        var pool = letters.filter { $0 != target }.shuffled(using: &rng)
        let distractors = Array(pool.prefix(2))
        var choices = ([target] + distractors).shuffled(using: &rng)
        if !choices.contains(target) { choices[0] = target }
        return nq(subject: .english, skill: "letter recognition", component: "Letter Tile", template: "Letter Recognition",
                  prompt: "Find the letter \(target)",
                  directions: "Tap the letter \(target).",
                  source: "letter_pack",
                  content: ["target": target],
                  choices: choices, correct: target, grade: .kindergarten)
    }

    private static func genUpperLower(rng: inout SeededRNG) -> NormalizedQuestion {
        let upper = letters.randomElement(using: &rng) ?? "B"
        let lower = upper.lowercased()
        var distractors = letters.filter { $0 != upper }.shuffled(using: &rng).prefix(2).map { $0.lowercased() }
        var choices = ([lower] + Array(distractors)).shuffled(using: &rng)
        if !choices.contains(lower) { choices[0] = lower }
        return nq(subject: .english, skill: "uppercase-lowercase", component: "Matching Card Set", template: "Uppercase-Lowercase Matching",
                  prompt: "Match \(upper) to its lowercase letter.",
                  directions: "Tap the lowercase \(lower).",
                  source: "letter_pack",
                  content: ["uppercase": upper],
                  choices: choices, correct: lower, grade: .kindergarten)
    }

    private static func genBeginningSound(rng: inout SeededRNG) -> NormalizedQuestion {
        let pool: [(String, String)] = [("b", "🐻 bear"), ("s", "🐍 snake"), ("c", "🐱 cat"),
                                        ("d", "🐶 dog"), ("f", "🐸 frog"), ("r", "🐰 rabbit")]
        let pick = pool.randomElement(using: &rng) ?? ("b", "🐻 bear")
        let others = pool.filter { $0.0 != pick.0 }.shuffled(using: &rng).prefix(2).map { $0.1 }
        var choices = ([pick.1] + others).shuffled(using: &rng)
        if !choices.contains(pick.1) { choices[0] = pick.1 }
        return nq(subject: .english, skill: "beginning sounds", component: "Choice Card Row", template: "Beginning Sounds",
                  prompt: "Which word starts with the /\(pick.0)/ sound?",
                  directions: "Tap the one that starts with \(pick.0).",
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
                  directions: "Choose the missing letter to make \(word).",
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
        let pool = band == .kindergarten || band == .grade1 ? cvcWords : (cvcWords + longerWords)
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
        let pick = (longerWords + cvcWords).randomElement(using: &rng) ?? ("apple", "🍎")
        let others = (cvcWords + longerWords).filter { $0.0 != pick.0 }.shuffled(using: &rng).prefix(2).map { $0.1 }
        var choices = ([pick.1] + Array(others)).shuffled(using: &rng)
        if !choices.contains(pick.1) { choices[0] = pick.1 }
        return nq(subject: .english, skill: "vocabulary", component: "Matching Card Set", template: "Vocabulary Matching",
                  prompt: "Match \(pick.0) to its picture.",
                  directions: "Choose the matching emoji.",
                  source: "food_vocab_pack",
                  content: ["word": pick.0],
                  choices: choices, correct: pick.1, grade: band)
    }

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
        return nq(subject: .english, skill: "sight words", component: "Choice Card Row", template: "Sight Word Recognition",
                  prompt: "Which word is \"\(target)\"?",
                  directions: "Tap the word that matches.",
                  source: "sight_words_pack",
                  content: ["target": target],
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

    private static func genSentence(band: GradeBand, rng: inout SeededRNG) -> NormalizedQuestion {
        let templates: [String] = band == .grade3
            ? ["The big dog ran quickly.", "A small cat sat softly.", "The bright sun shines warmly."]
            : ["The dog runs.", "I see a cat.", "We go home.", "She read a book."]
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
