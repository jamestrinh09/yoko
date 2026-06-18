//
//  MilestoneEngine.swift
//  Yoko
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
    static let risingStar     = Achievement(title: "Rising Star 🌟", detail: "Finish 50 lessons", symbol: "sparkles", unlocked: true)
    static let centuryClub    = Achievement(title: "Century Club 💯", detail: "Finish 100 lessons", symbol: "100.circle.fill", unlocked: true)
    static let flawless       = Achievement(title: "Flawless 💎", detail: "Get 10 perfect lessons", symbol: "diamond.fill", unlocked: true)
    static let mathMaster     = Achievement(title: "Math Master 🧮", detail: "Finish 15 math lessons", symbol: "x.squareroot", unlocked: true)
    static let storyMaster    = Achievement(title: "Story Master 📚", detail: "Finish 15 English lessons", symbol: "books.vertical.fill", unlocked: true)
    static let unstoppable    = Achievement(title: "Unstoppable 🚀", detail: "Reach a 14-day streak", symbol: "bolt.horizontal.fill", unlocked: true)
    static let monthlyMaster  = Achievement(title: "Monthly Master 📅", detail: "Reach a 30-day streak", symbol: "trophy.fill", unlocked: true)
    static let scholar        = Achievement(title: "Scholar 🦉", detail: "Earn 1,000 lifetime XP", symbol: "brain.fill", unlocked: true)
    static let bigBrain       = Achievement(title: "Big Brain 🧩", detail: "Earn 5,000 lifetime XP", symbol: "puzzlepiece.fill", unlocked: true)

    /// Every achievement in display order. Used to seed the locked grid so the
    /// Rewards tab shows the full set of unlockable badges from day one.
    static let catalog: [Achievement] = [
        firstStep, sharpStart, sharpMind, committed, risingStar, centuryClub,
        hatTrick, perfectionist, flawless, streakStarter, weekWarrior, unstoppable,
        monthlyMaster, mathWhiz, mathMaster, wordWizard, storyMaster,
        scholar, bigBrain, gradeGraduate
    ]

    /// The catalog rendered as locked placeholders for the initial Rewards grid.
    static var lockedCatalog: [Achievement] {
        catalog.map { Achievement(title: $0.title, detail: $0.detail, symbol: $0.symbol, unlocked: false) }
    }

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
        if mathLessonsCompleted == 15 { award(mathMaster) }
        if englishLessonsCompleted == 5 { award(wordWizard) }
        if englishLessonsCompleted == 15 { award(storyMaster) }
        if profile.totalLessonsCompleted == 50 { award(risingStar) }
        if profile.totalLessonsCompleted == 100 { award(centuryClub) }
        if profile.perfectLessons == 10 { award(flawless) }
        if profile.streak == 14 { award(unstoppable) }
        if profile.streak == 30 { award(monthlyMaster) }
        if profile.lifetimeXP >= 1000 { award(scholar) }
        if profile.lifetimeXP >= 5000 { award(bigBrain) }

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
