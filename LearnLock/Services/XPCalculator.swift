//
//  XPCalculator.swift
//  LearnLock
//
//  Pure XP scoring for a completed lesson.
//

import Foundation

nonisolated enum XPCalculator {
    /// XP for a 3-question lesson.
    /// - 10 XP per correct answer
    /// - +5 bonus for a perfect lesson (all 3 correct)
    /// - +15 bonus when the learner has a 3+ day streak
    static func calculate(correctCount: Int, streak: Int) -> Int {
        var xp = max(0, correctCount) * 10
        if correctCount == 3 { xp += 5 }
        if streak >= 3 { xp += 15 }
        return max(0, xp)
    }
}
