//
//  SeedData.swift
//  Yoko
//

import SwiftUI

enum SeedData {
    /// Build the initial subject queues procedurally for the given grade.
    static func subjects(grade: Int = 1) -> [SubjectProgress] {
        let math = CurriculumGenerator.generateBatch(
            subject: .math, grade: grade, count: 20, startSeed: 1001
        )
        let english = CurriculumGenerator.generateBatch(
            subject: .english, grade: grade, count: 20, startSeed: 2002
        )
        return [
            SubjectProgress(subject: .math, lessons: math, xp: 0, streak: 0, generationCursor: 1001 + 20 + 31),
            SubjectProgress(subject: .english, lessons: english, xp: 0, streak: 0, generationCursor: 2002 + 20 + 31)
        ]
    }

    static func locks() -> [AppLock] {
        [
            AppLock(name: "YouTube", symbol: "play.rectangle.fill", iconColor: Color(red: 0.93, green: 0.18, blue: 0.18), category: "Video", type: .reward, enabled: false, requiredMinutes: 20, requiredQuestions: 10, requiredSubject: .math, rewardRule: "session", earnedMinutesAvailable: 0),
            AppLock(name: "TikTok", symbol: "music.note", iconColor: Color(red: 0.05, green: 0.05, blue: 0.05), category: "Social", type: .reward, enabled: false, requiredMinutes: 30, rewardRule: "time", earnedMinutesAvailable: 0),
            AppLock(name: "Roblox", symbol: "gamecontroller.fill", iconColor: Color(red: 0.85, green: 0.2, blue: 0.2), category: "Games", type: .timed, enabled: false, earnedMinutesAvailable: 0, scheduleStart: 16, scheduleEnd: 20),
            AppLock(name: "Instagram", symbol: "camera.fill", iconColor: Color(red: 0.85, green: 0.3, blue: 0.55), category: "Social", type: .full, enabled: false),
            AppLock(name: "Snapchat", symbol: "bubble.left.and.bubble.right.fill", iconColor: Color(red: 1.0, green: 0.85, blue: 0.0), category: "Social", type: .reward, enabled: false, requiredMinutes: 15, rewardRule: "daily", earnedMinutesAvailable: 0)
        ]
    }

    static func achievements() -> [Achievement] {
        // The full unlockable catalog, shown locked until earned.
        MilestoneEngine.lockedCatalog
    }
}
