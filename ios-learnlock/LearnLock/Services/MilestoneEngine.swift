//
//  MilestoneEngine.swift
//  LearnLock
//
//  Evaluates a child's progress after every lesson and returns any rewards
//  that should fire — free screen time, achievement unlocks, or a grade
//  promotion that is ready for parent approval. Pure & side-effect free; the
//  app store applies the rewards and schedules notifications.
//

import Foundation

nonisolated enum MilestoneEngine {

    // MARK: - Achievement catalog

    static let firstStep      = Achievement(title: "First Step 👣", detail: "Complete your very first lesson", symbol: "shoeprints.fill", unlocked: true)
    static let sharpStart     = Achievement(title: "Sharp Start ⚡", detail: "Finish 5 lessons", symbol: "bolt.fill", unlocked: true)
    static let sharpMind      = Achievement(title: "Sharp Mind 🧠", detail: "Finish 10 lessons", symbol: "brain.head.profile", unlocked: true)
    static let committed      = Achievement(title: "Committed 💪", detail: "Finish 25 lessons", symbol: "figure.strengthtraining.traditional", unlocked: true)
    static let hatTrick       = Achievement(title: "Hat Trick 🎩", detail: "Get 3 perfect lessons", symbol: "rosette", unlocked: true)
    static let perfectionist  = Achievement(title: "Perfectionist ⭐", detail: "Get 5 perfect lessons", symbol: "star.fill", unlocked: true)
    static let streakStarter  = Achievement(title: "Streak Starter 🔥", detail: "Reach a 3-day streak", symbol: "flame.fill", unlocked: true)
    static let weekWarrior    = Achievement(title: "Week Warrior ⚡", detail: "Reach a 7-day streak", symbol: "calendar.badge.checkmark", unlocked: true)
    static let mathWhiz       = Achievement(title: "Math Whiz 🔢", detail: "Finish 5 math lessons", symbol: "function", unlocked: true)
    static let wordWizard     = Achievement(title: "Word Wizard 📖", detail: "Finish 5 English lessons", symbol: "book.fill", unlocked: true)
    static let gradeGraduate  = Achievement(title: "Grade Graduate 🎓", detail: "Move up to the next grade", symbol: "graduationcap.fill", unlocked: true)

    // MARK: - Evaluation

    static func evaluate(profile: ChildProfile, mathLessonsCompleted: Int, englishLessonsCompleted: Int) -> [MilestoneReward] {
        var rewards: [MilestoneReward] = []
        let owned = Set(profile.achievements.map(\.title))

        func award(_ a: Achievement) {
            guard !owned.contains(a.title) else { return }
            let alreadyQueued = rewards.contains {
                if case let .achievementUnlocked(x) = $0 { return x.title == a.title }
                return false
            }
            guard !alreadyQueued else { return }
            rewards.append(.achievementUnlocked(a))
        }

        // Lesson-count milestones — fire once via exact equality.
        switch profile.totalLessonsCompleted {
        case 3:
            rewards.append(.freeScreenTime(minutes: 15))
        case 5:
            award(sharpStart)
        case 10:
            rewards.append(.freeScreenTime(minutes: 20))
            award(sharpMind)
        case 25:
            rewards.append(.freeScreenTime(minutes: 30))
            award(committed)
        default:
            break
        }

        // Achievement triggers checked on every completion.
        if profile.totalLessonsCompleted == 1 { award(firstStep) }
        if profile.perfectLessons == 3 { award(hatTrick) }
        if profile.perfectLessons == 5 { award(perfectionist) }
        if profile.streak == 3 { award(streakStarter) }
        if profile.streak == 7 { award(weekWarrior) }
        if mathLessonsCompleted == 5 { award(mathWhiz) }
        if englishLessonsCompleted == 5 { award(wordWizard) }

        // Grade promotion eligibility — all conditions simultaneously true.
        if profile.totalLessonsCompleted >= 40,
           profile.overallAccuracy >= 0.80,
           profile.daysSinceStart >= 14,
           !profile.pendingGradePromotion,
           let nextGrade = profile.currentGrade.next {
            rewards.append(.gradePromotionReady(
                GradePromotion(fromGrade: profile.currentGrade,
                               toGrade: nextGrade,
                               lessonsCompleted: profile.totalLessonsCompleted)
            ))
        }

        return rewards
    }
}
