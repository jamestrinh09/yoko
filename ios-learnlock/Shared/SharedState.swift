//
//  SharedState.swift
//  Yoko
//

import Foundation

struct SharedState {
    private static let suiteName = "group.app.rork.yoko"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    static var isUnlocked: Bool {
        get {
            defaults?.bool(forKey: "yoko.isUnlocked") ?? false
        }
        set {
            defaults?.set(newValue, forKey: "yoko.isUnlocked")
        }
    }

    static var nextLessonSeed: UInt64 {
        get {
            let doubleValue = defaults?.double(forKey: "yoko.nextLessonSeed") ?? 0
            return UInt64(doubleValue)
        }
        set {
            defaults?.set(Double(newValue), forKey: "yoko.nextLessonSeed")
        }
    }

    static var selectedAppTokensData: Data? {
        get {
            defaults?.data(forKey: "yoko.selectedAppTokensData")
        }
        set {
            defaults?.set(newValue, forKey: "yoko.selectedAppTokensData")
        }
    }

    static var unlockExpiryDate: Date? {
        get {
            defaults?.object(forKey: "yoko.unlockExpiryDate") as? Date
        }
        set {
            defaults?.set(newValue, forKey: "yoko.unlockExpiryDate")
        }
    }
}
