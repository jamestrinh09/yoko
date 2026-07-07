//
//  ShieldActionExtension.swift
//  ShieldActionExtension
//
//  Created by bella vitale on 7/6/26.
//

import ManagedSettings
import UserNotifications
import Foundation

class ShieldActionExtension: ShieldActionDelegate {

    private func scheduleYokoNotificationAndDefer(completionHandler: @escaping (ShieldActionResponse) -> Void) {
        let content = UNMutableNotificationContent()
        content.title = "Your lesson is ready! 🎓"
        content.body = "Tap here to open Yoko and earn your screen time"
        content.userInfo = ["source": "shield_action"]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "yoko.unlock", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { _ in
            completionHandler(.defer)
        }
    }

    override func handle(action: ShieldAction, for application: ApplicationToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            scheduleYokoNotificationAndDefer(completionHandler: completionHandler)
        case .secondaryButtonPressed:
            completionHandler(.defer)
        @unknown default:
            completionHandler(.defer)
        }
    }

    override func handle(action: ShieldAction, for webDomain: WebDomainToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            scheduleYokoNotificationAndDefer(completionHandler: completionHandler)
        case .secondaryButtonPressed:
            completionHandler(.defer)
        @unknown default:
            completionHandler(.defer)
        }
    }

    override func handle(action: ShieldAction, for category: ActivityCategoryToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            scheduleYokoNotificationAndDefer(completionHandler: completionHandler)
        case .secondaryButtonPressed:
            completionHandler(.defer)
        @unknown default:
            completionHandler(.defer)
        }
    }
}
