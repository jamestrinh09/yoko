//
//  AppStore.swift
//  Yoko
//

import SwiftUI
import Observation
import UserNotifications

@Observable
final class AppStore {
    var profile: ChildProfile
    var subjects: [SubjectProgress]
    var locks: [AppLock]
    var achievements: [Achievement]
    var weeklyMinutes: [Int] = [0, 0, 0, 0, 0, 0, 0]
    var notificationsEnabled: Bool = true
    var bedtimeLockEnabled: Bool = true
    var schoolHoursLockEnabled: Bool = false
    var parentPasscodeEnabled: Bool = true
    var iCloudSyncEnabled: Bool = true
    var onboardingComplete: Bool = false

    /// How learning unlocks access. One of "session", "time", or "daily".
    /// Set during onboarding and applied to the app afterwards.
    var unlockRule: String = "session"

    /// A grade promotion awaiting parent approval (drives the promotion banner).
    var pendingPromotion: GradePromotion?

    /// Children in the household. All children share the same curriculum and
    /// progress; switching the active child only changes the displayed identity.
    var children: [Child]
    /// The currently active child's id.
    var activeChildId: UUID

    /// Number of lessons kept ahead of the user at any time.
    private let queueTargetSize: Int = 20
    /// Threshold of remaining incomplete lessons that triggers a refill.
    private let queueRefillThreshold: Int = 5

    init() {
        self.profile = ChildProfile(
            name: "James",
            grade: 1,
            streak: 0,
            dailyMinuteGoal: 30,
            minutesLearnedToday: 0,
            lessonsCompletedToday: 0,
            earnedScreenTimeMinutes: 0,
            totalXP: 0
        )
        self.subjects = SeedData.subjects(grade: 1)
        self.locks = SeedData.locks()
        self.achievements = SeedData.achievements()
        let firstChild = Child(name: "James", colorIndex: 0)
        self.children = [firstChild]
        self.activeChildId = firstChild.id
        self.profile.currentGrade = CurriculumGenerator.gradeBand(for: 1)
        self.profile.startDate = Date()
    }

    // MARK: - Children

    /// The currently active child identity.
    var activeChild: Child? {
        children.first(where: { $0.id == activeChildId })
    }

    /// Add a new child to the household. Children share the same curriculum and
    /// progress — only their name and avatar differ.
    func addChild(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let child = Child(name: trimmed, colorIndex: children.count)
        children.append(child)
        switchChild(child.id)
    }

    /// Switch the active child. The shared progress stays the same; only the
    /// displayed name updates.
    func switchChild(_ id: UUID) {
        guard let child = children.first(where: { $0.id == id }) else { return }
        activeChildId = id
        profile.name = child.name
    }

    /// Remove a child. The last remaining child cannot be removed.
    func removeChild(_ id: UUID) {
        guard children.count > 1 else { return }
        children.removeAll { $0.id == id }
        if activeChildId == id, let first = children.first {
            switchChild(first.id)
        }
    }

    // MARK: - Derived

    var dailyProgress: Double {
        guard profile.dailyMinuteGoal > 0 else { return 0 }
        return min(1, Double(profile.minutesLearnedToday) / Double(profile.dailyMinuteGoal))
    }

    var activeLocks: [AppLock] { locks.filter(\.enabled) }

    func subject(_ s: Subject) -> SubjectProgress? {
        subjects.first(where: { $0.subject == s })
    }

    // MARK: - Actions

    /// Complete a lesson with the raw number of correct answers (0...3).
    /// Returns the lesson result and any milestone rewards so the UI can
    /// celebrate them on the completion screen.
    @discardableResult
    func completeLesson(_ lesson: Lesson, correctCount: Int) -> (result: LessonResult, rewards: [MilestoneReward]) {
        let total = max(1, lesson.questions.count)
        let score = Int(Double(correctCount) / Double(total) * 100)
        let isPerfect = correctCount == total
        let xpEarned = XPCalculator.calculate(correctCount: correctCount, streak: profile.streak)

        if let sIdx = subjects.firstIndex(where: { $0.subject == lesson.subject }),
           let lIdx = subjects[sIdx].lessons.firstIndex(where: { $0.id == lesson.id }) {
            let alreadyDone = subjects[sIdx].lessons[lIdx].completed
            subjects[sIdx].lessons[lIdx].completed = true
            subjects[sIdx].lessons[lIdx].bestScore = max(subjects[sIdx].lessons[lIdx].bestScore, score)
            subjects[sIdx].xp += xpEarned
            profile.lessonsCompletedToday += alreadyDone ? 0 : 1
            updateMastery(for: lesson, score: score, subjectIndex: sIdx)
            refillQueueIfNeeded(subjectIndex: sIdx)
        }

        updateStreak()

        // Base screen time + lifetime stats. The unlock rule chosen during
        // onboarding determines how much access a completed lesson grants.
        let minutes = max(2, lesson.questions.count)
        profile.minutesLearnedToday += minutes
        profile.earnedScreenTimeMinutes += earnedMinutes(forBaseLearning: minutes)
        profile.totalXP += xpEarned
        profile.lifetimeXP += xpEarned
        profile.totalLessonsCompleted += 1
        profile.totalCorrectAnswers += correctCount
        profile.totalAnswersGiven += total
        if isPerfect { profile.perfectLessons += 1 }

        let result = LessonResult(
            lessonId: lesson.id,
            correctCount: correctCount,
            totalQuestions: total,
            xpEarned: xpEarned,
            isPerfect: isPerfect,
            subject: lesson.subject
        )

        let mathDone = subject(.math)?.lessonsCompleted ?? 0
        let englishDone = subject(.english)?.lessonsCompleted ?? 0
        let rewards = MilestoneEngine.evaluate(
            profile: profile,
            mathLessonsCompleted: mathDone,
            englishLessonsCompleted: englishDone
        )
        applyRewards(rewards)
        return (result, rewards)
    }

    /// Maps completed learning to earned screen time based on the active
    /// unlock rule: a fixed time block, a full-day allowance, or per-session.
    private func earnedMinutes(forBaseLearning minutes: Int) -> Int {
        switch unlockRule {
        case "time": return 30
        case "daily": return 240
        default: return minutes / 2 + 5
        }
    }

    /// Advances the daily streak. The first lesson completed on a new calendar
    /// day bumps the streak; a gap of more than one day resets it to 1.
    private func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let last = profile.lastLessonDate else {
            profile.streak = max(profile.streak, 1)
            profile.lastLessonDate = today
            return
        }
        let lastDay = calendar.startOfDay(for: last)
        guard lastDay != today else { return } // already counted today
        let gap = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
        profile.streak = gap == 1 ? profile.streak + 1 : 1
        profile.lastLessonDate = today
    }

    private func applyRewards(_ rewards: [MilestoneReward]) {
        for reward in rewards {
            switch reward {
            case let .freeScreenTime(minutes):
                profile.freeUnlockMinutesAvailable += minutes
                profile.earnedScreenTimeMinutes += minutes
            case let .achievementUnlocked(achievement):
                if !profile.achievements.contains(where: { $0.title == achievement.title }) {
                    profile.achievements.append(achievement)
                }
                mirrorAchievement(achievement)
            case let .gradePromotionReady(promotion):
                profile.pendingGradePromotion = true
                pendingPromotion = promotion
                scheduleParentPromotionNotification(promotion)
            }
        }
    }

    private func mirrorAchievement(_ a: Achievement) {
        if !achievements.contains(where: { $0.title == a.title }) {
            achievements.append(a)
        }
    }

    func toggleLock(_ lock: AppLock) {
        guard let idx = locks.firstIndex(of: lock) else { return }
        locks[idx].enabled.toggle()
    }

    func updateLock(_ lock: AppLock) {
        guard let idx = locks.firstIndex(where: { $0.id == lock.id }) else { return }
        locks[idx] = lock
    }

    /// Set an app's unlock rule. For reward locks, `rewardRule` is one of
    /// "session", "time", or "daily". The on/off toggle is independent of this.
    func setLockRule(_ lock: AppLock, type: LockType, rewardRule: String) {
        guard let idx = locks.firstIndex(where: { $0.id == lock.id }) else { return }
        locks[idx].type = type
        locks[idx].rewardRule = rewardRule
    }

    func unlockApp(_ lock: AppLock, minutes: Int) {
        guard let idx = locks.firstIndex(where: { $0.id == lock.id }) else { return }
        let used = min(minutes, locks[idx].earnedMinutesAvailable, profile.earnedScreenTimeMinutes)
        locks[idx].earnedMinutesAvailable -= used
        profile.earnedScreenTimeMinutes -= used
    }

    func resetOnboarding() {
        onboardingComplete = false
    }

    // MARK: - Profile editing

    /// Update the child's display name (trimmed; ignored when empty).
    func updateProfileName(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        profile.name = trimmed
        if let idx = children.firstIndex(where: { $0.id == activeChildId }) {
            children[idx].name = trimmed
        }
    }

    /// Update the daily learning goal in minutes (clamped to a sensible range).
    func setDailyGoal(_ minutes: Int) {
        profile.dailyMinuteGoal = max(5, min(120, minutes))
    }

    // MARK: - Grade level

    /// Update the child's grade. Keeps completed lessons (history) and mastery,
    /// but regenerates the upcoming lesson queue at the new difficulty.
    func setGrade(_ newGrade: Int) {
        profile.grade = newGrade
        profile.currentGrade = CurriculumGenerator.gradeBand(for: newGrade)
        for i in subjects.indices {
            let completed = subjects[i].lessons.filter(\.completed)
            let weak = subjects[i].weakSkills.compactMap { CurriculumSkill(rawValue: $0) }
            let seed = subjects[i].generationCursor
            let fresh = CurriculumGenerator.generateBatch(
                subject: subjects[i].subject,
                grade: newGrade,
                count: queueTargetSize,
                startSeed: seed &+ 7919,
                weakSkills: weak
            )
            subjects[i].lessons = completed + fresh
            subjects[i].generationCursor = seed &+ UInt64(queueTargetSize) &+ 7919
        }
    }

    // MARK: - Grade promotion approval

    /// Parent approves the pending promotion: advance the grade, regenerate
    /// the queue at the new difficulty, and award the Grade Graduate badge.
    func approveGradePromotion() {
        guard let promo = pendingPromotion else { return }
        profile.pendingGradePromotion = false
        pendingPromotion = nil
        setGrade(promo.toGrade.numericGrade)
        let badge = MilestoneEngine.gradeGraduate
        if !profile.achievements.contains(where: { $0.title == badge.title }) {
            profile.achievements.append(badge)
            mirrorAchievement(badge)
        }
    }

    /// Parent chooses to keep practising — grade stays the same. The pending
    /// promotion remains so they can decide later.
    func keepPractising() {
        // Intentionally leaves grade and pending state unchanged.
    }

    /// Re-sends the parent promotion notification (used by the child's
    /// "Tell a parent" button on the completion screen).
    func tellParentAboutPromotion() {
        guard let promo = pendingPromotion else { return }
        scheduleParentPromotionNotification(promo)
    }

    private func scheduleParentPromotionNotification(_ promo: GradePromotion) {
        let name = profile.name
        let gradeName = promo.toGrade.rawValue
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "Grade Promotion Ready 🎓"
            content.body = "\(name) has completed 40 lessons and is ready for \(gradeName)! Open Yoko to approve."
            content.sound = .default
            let request = UNNotificationRequest(
                identifier: "grade_promo_\(gradeName)",
                content: content,
                trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            )
            center.add(request)
        }
    }

    // MARK: - Cross-device sync

    /// Build a compact snapshot of the shared household state for syncing.
    func exportSnapshot() -> SyncSnapshot {
        SyncSnapshot(
            childName: profile.name,
            grade: profile.grade,
            streak: profile.streak,
            dailyMinuteGoal: profile.dailyMinuteGoal,
            minutesLearnedToday: profile.minutesLearnedToday,
            lessonsCompletedToday: profile.lessonsCompletedToday,
            earnedScreenTimeMinutes: profile.earnedScreenTimeMinutes,
            totalXP: profile.totalXP,
            lifetimeXP: profile.lifetimeXP,
            totalLessonsCompleted: profile.totalLessonsCompleted,
            perfectLessons: profile.perfectLessons,
            totalCorrectAnswers: profile.totalCorrectAnswers,
            totalAnswersGiven: profile.totalAnswersGiven,
            pendingGradePromotion: profile.pendingGradePromotion,
            achievements: profile.achievements.map {
                SyncAchievement(title: $0.title, detail: $0.detail, symbol: $0.symbol, unlocked: $0.unlocked)
            },
            subjects: subjects.map {
                SyncSubject(subject: $0.subject.rawValue, xp: $0.xp, lessonsCompleted: $0.lessonsCompleted, mastery: $0.masteryProgress)
            },
            locks: locks.map {
                SyncLock(name: $0.name, enabled: $0.enabled, earnedMinutesAvailable: $0.earnedMinutesAvailable)
            },
            updatedAtEpoch: Date().timeIntervalSince1970
        )
    }

    /// Merge a remote snapshot into the local state (last-write-wins on summary
    /// fields). The local lesson queue is preserved and regenerated locally.
    func applySnapshot(_ s: SyncSnapshot) {
        if s.grade != profile.grade {
            setGrade(s.grade)
        }
        profile.name = s.childName
        profile.streak = s.streak
        profile.dailyMinuteGoal = s.dailyMinuteGoal
        profile.minutesLearnedToday = s.minutesLearnedToday
        profile.lessonsCompletedToday = s.lessonsCompletedToday
        profile.earnedScreenTimeMinutes = s.earnedScreenTimeMinutes
        profile.totalXP = s.totalXP
        profile.lifetimeXP = s.lifetimeXP
        profile.totalLessonsCompleted = s.totalLessonsCompleted
        profile.perfectLessons = s.perfectLessons
        profile.totalCorrectAnswers = s.totalCorrectAnswers
        profile.totalAnswersGiven = s.totalAnswersGiven
        profile.pendingGradePromotion = s.pendingGradePromotion

        let merged = s.achievements.map {
            Achievement(title: $0.title, detail: $0.detail, symbol: $0.symbol, unlocked: $0.unlocked)
        }
        if !merged.isEmpty {
            profile.achievements = merged
            achievements = merged
        }

        for synced in s.subjects {
            guard let subj = Subject(rawValue: synced.subject),
                  let idx = subjects.firstIndex(where: { $0.subject == subj }) else { continue }
            subjects[idx].xp = synced.xp
            if synced.mastery > 0 {
                subjects[idx].skillMastery["synced"] = synced.mastery
            }
        }

        for synced in s.locks {
            guard let idx = locks.firstIndex(where: { $0.name == synced.name }) else { continue }
            locks[idx].enabled = synced.enabled
            locks[idx].earnedMinutesAvailable = synced.earnedMinutesAvailable
        }
    }

    // MARK: - Mastery

    private func updateMastery(for lesson: Lesson, score: Int, subjectIndex i: Int) {
        let scoreFraction = Double(max(0, min(100, score))) / 100.0
        var mastery = subjects[i].skillMastery
        var weak = Set(subjects[i].weakSkills)

        for q in lesson.questions {
            let tag = q.normalized?.masteryTag
                ?? q.normalized?.skill.replacingOccurrences(of: " ", with: "_")
            guard let key = tag else { continue }
            let current = mastery[key] ?? 0
            // Each appearance nudges mastery toward `scoreFraction`.
            let nudge = (scoreFraction - current) * 0.25
            mastery[key] = max(0, min(1, current + nudge))

            if scoreFraction >= 0.7 {
                weak.remove(key)
            } else {
                weak.insert(key)
            }
        }

        subjects[i].skillMastery = mastery
        subjects[i].weakSkills = Array(weak)
    }

    // MARK: - Lesson queue

    private func refillQueueIfNeeded(subjectIndex i: Int) {
        let remaining = subjects[i].lessons.filter { !$0.completed }.count
        guard remaining < queueRefillThreshold else { return }
        let seed = subjects[i].generationCursor
        let weak = subjects[i].weakSkills.compactMap { CurriculumSkill(rawValue: $0) }
        let batch = CurriculumGenerator.generateBatch(
            subject: subjects[i].subject,
            grade: profile.grade,
            count: queueTargetSize,
            startSeed: seed,
            weakSkills: weak
        )
        subjects[i].lessons.append(contentsOf: batch)
        subjects[i].generationCursor = seed &+ UInt64(queueTargetSize) &+ 31
    }
}
