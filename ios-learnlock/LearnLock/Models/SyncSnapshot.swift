//
//  SyncSnapshot.swift
//  LearnLock
//
//  Compact, Codable representation of the shared household state synced between
//  a parent device and a child device. Kept deliberately summary-level — the
//  full lesson queue is regenerated locally on each device.
//

import Foundation

nonisolated struct SyncSnapshot: Codable, Sendable {
    var childName: String
    var grade: Int
    var streak: Int
    var dailyMinuteGoal: Int
    var minutesLearnedToday: Int
    var lessonsCompletedToday: Int
    var earnedScreenTimeMinutes: Int
    var totalXP: Int
    var lifetimeXP: Int
    var totalLessonsCompleted: Int
    var perfectLessons: Int
    var totalCorrectAnswers: Int
    var totalAnswersGiven: Int
    var pendingGradePromotion: Bool
    var achievements: [SyncAchievement]
    var subjects: [SyncSubject]
    var locks: [SyncLock]
    var updatedAtEpoch: Double
}

nonisolated struct SyncAchievement: Codable, Sendable {
    var title: String
    var detail: String
    var symbol: String
    var unlocked: Bool
}

nonisolated struct SyncSubject: Codable, Sendable {
    var subject: String
    var xp: Int
    var lessonsCompleted: Int
    var mastery: Double
}

nonisolated struct SyncLock: Codable, Sendable {
    var name: String
    var enabled: Bool
    var earnedMinutesAvailable: Int
}
