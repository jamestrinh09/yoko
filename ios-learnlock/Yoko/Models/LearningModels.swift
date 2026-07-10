//
//  LearningModels.swift
//  Yoko
//

import SwiftUI

enum Subject: String, CaseIterable, Identifiable, Hashable {
    case math, english
    var id: String { rawValue }

    var title: String {
        switch self {
        case .math: "Math"
        case .english: "English"
        }
    }

    var symbol: String {
        switch self {
        case .math: "function"
        case .english: "textformat"
        }
    }

    var tint: Color {
        switch self {
        case .math: Color(red: 1.0, green: 0.478, blue: 0.0)
        case .english: Color(red: 0.95, green: 0.55, blue: 0.15)
        }
    }
}

enum QuestionKind: Hashable {
    case multipleChoice(options: [String], correctIndex: Int)
    case fillInBlank(answer: String)
    case matching(pairs: [(String, String)])

    static func == (lhs: QuestionKind, rhs: QuestionKind) -> Bool {
        switch (lhs, rhs) {
        case let (.multipleChoice(a, ai), .multipleChoice(b, bi)):
            return a == b && ai == bi
        case let (.fillInBlank(a), .fillInBlank(b)):
            return a == b
        case let (.matching(a), .matching(b)):
            return a.map(\.0) == b.map(\.0) && a.map(\.1) == b.map(\.1)
        default: return false
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case let .multipleChoice(o, i):
            hasher.combine(0); hasher.combine(o); hasher.combine(i)
        case let .fillInBlank(a):
            hasher.combine(1); hasher.combine(a)
        case let .matching(p):
            hasher.combine(2); hasher.combine(p.map(\.0)); hasher.combine(p.map(\.1))
        }
    }
}

struct Question: Identifiable, Hashable {
    let id = UUID()
    let prompt: String
    let kind: QuestionKind
    let normalized: NormalizedQuestion?
    var xp: Int = 10

    init(prompt: String, kind: QuestionKind, normalized: NormalizedQuestion? = nil, xp: Int = 10) {
        self.prompt = prompt
        self.kind = kind
        self.normalized = normalized
        self.xp = xp
    }
}

struct Lesson: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subject: Subject
    let level: Int
    let questions: [Question]
    var completed: Bool = false
    var bestScore: Int = 0

    var totalXP: Int { questions.reduce(0) { $0 + $1.xp } }
}

struct SubjectProgress: Identifiable, Hashable {
    var id: Subject { subject }
    let subject: Subject
    var lessons: [Lesson]
    var xp: Int = 0
    var streak: Int = 0
    /// Skill mastery 0...1 keyed by skill raw value. Persists across grade changes.
    var skillMastery: [String: Double] = [:]
    /// Skills the learner has been weak on recently (drives adaptive lesson generation).
    var weakSkills: [String] = []
    /// Monotonically increasing counter used to seed the next batch of lessons.
    var generationCursor: UInt64 = 1
    /// The current curriculum level within this subject (1-based).
    var currentLevel: Int = 1
    /// Number of lessons completed at the current level (resets on level-up).
    var lessonsCompletedThisLevel: Int = 0
    /// Lifetime lesson count across all levels (never resets).
    var totalLessonsCompletedAllLevels: Int = 0

    var lessonsCompleted: Int { lessons.filter(\.completed).count }

    /// Queue-level completion ratio (used by the small subject row).
    var progress: Double {
        guard !lessons.isEmpty else { return 0 }
        return Double(lessonsCompleted) / Double(lessons.count)
    }

    /// Average mastery across explored skills. Curriculum is infinite, so we
    /// surface mastery rather than "finite" completion.
    var masteryProgress: Double {
        guard !skillMastery.isEmpty else { return 0 }
        let total = skillMastery.values.reduce(0, +)
        return min(1, total / Double(skillMastery.count))
    }
}

// MARK: - Lock Models

enum LockType: String, CaseIterable, Hashable {
    case timed, full, reward, educational

    var title: String {
        switch self {
        case .timed: "Timed Lock"
        case .full: "Full Lock"
        case .reward: "Reward Unlock"
        case .educational: "Reward Unlock"
        }
    }

    var subtitle: String {
        switch self {
        case .timed: "Locks during scheduled hours"
        case .full: "Always blocked"
        case .reward: "Earn time by learning"
        case .educational: "Earn time by learning"
        }
    }

    var symbol: String {
        switch self {
        case .timed: "clock.fill"
        case .full: "lock.fill"
        case .reward: "gift.fill"
        case .educational: "gift.fill"
        }
    }

    /// Educational is a legacy alias for Reward Unlock — both are quiz-gated access.
    /// The UI collapses them so every quiz-unlock app shows the same gift icon and
    /// "Reward Unlock" label. Always display/filter through this.
    var normalized: LockType { self == .educational ? .reward : self }
}

struct AppLock: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var symbol: String
    var iconColor: Color
    var category: String
    var type: LockType
    var enabled: Bool = true
    var requiredMinutes: Int = 15
    var requiredQuestions: Int = 10
    var requiredSubject: Subject = .math
    /// For reward-unlock apps: how completed learning grants access.
    /// One of "session", "time", or "daily" (mirrors the onboarding unlock rule).
    var rewardRule: String = "session"
    var earnedMinutesAvailable: Int = 0
    var scheduleStart: Int = 16   // 4PM
    var scheduleEnd: Int = 21     // 9PM
}

// MARK: - Achievements

struct Achievement: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let detail: String
    let symbol: String
    var unlocked: Bool
}

// MARK: - Profile

struct ChildProfile: Hashable {
    var name: String
    var grade: Int
    var streak: Int
    var dailyMinuteGoal: Int
    var minutesLearnedToday: Int
    var lessonsCompletedToday: Int
    var earnedScreenTimeMinutes: Int
    var totalXP: Int

    // MARK: - Growth & gamification
    var totalLessonsCompleted: Int = 0
    var perfectLessons: Int = 0
    var currentGrade: GradeBand = .kindergarten
    var pendingGradePromotion: Bool = false
    var lifetimeXP: Int = 0
    var achievements: [Achievement] = []
    var freeUnlockMinutesAvailable: Int = 0
    var totalCorrectAnswers: Int = 0
    var totalAnswersGiven: Int = 0
    var startDate: Date = Date()
    /// The day the most recent lesson was completed (drives the daily streak).
    var lastLessonDate: Date? = nil
    /// Per-grade progress map: grade -> subject progress array. When the child
    /// switches grades, their progress for that grade is saved/restored from here.
    var gradeProgressMap: [Int: [SubjectProgress]] = [:]

    /// Lifetime correct-answer ratio used for grade-promotion eligibility.
    var overallAccuracy: Double {
        guard totalAnswersGiven > 0 else { return 0 }
        return Double(totalCorrectAnswers) / Double(totalAnswersGiven)
    }

    /// Whole days elapsed since the child started using the app.
    var daysSinceStart: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
    }
}

// MARK: - Growth & reward models

/// Outcome of a single completed lesson (always 3 questions).
struct LessonResult: Hashable {
    let lessonId: UUID
    let correctCount: Int
    let totalQuestions: Int // always 3
    let xpEarned: Int
    let isPerfect: Bool
    let subject: Subject
}

/// A proposed grade-level promotion awaiting parent approval.
struct GradePromotion: Hashable {
    let fromGrade: GradeBand
    let toGrade: GradeBand
    let lessonsCompleted: Int
    var parentApproved: Bool = false
}

/// A reward fired by the milestone engine after a lesson completes.
enum MilestoneReward {
    case freeScreenTime(minutes: Int)
    case achievementUnlocked(Achievement)
    case gradePromotionReady(GradePromotion)
}

extension GradeBand {
    /// The next grade band, or `nil` when already at the top (Grade 3).
    var next: GradeBand? {
        switch self {
        case .kindergarten: return .grade1
        case .grade1: return .grade2
        case .grade2: return .grade3
        case .grade3: return nil
        }
    }

    /// Numeric grade used by the procedural generator (K = 0).
    var numericGrade: Int {
        switch self {
        case .kindergarten: return 0
        case .grade1: return 1
        case .grade2: return 2
        case .grade3: return 3
        }
    }
}
