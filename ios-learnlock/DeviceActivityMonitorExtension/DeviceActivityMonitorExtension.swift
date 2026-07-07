//
//  DeviceActivityMonitorExtension.swift
//  DeviceActivityMonitorExtension
//
//  Created by bella vitale on 7/6/26.
//

import DeviceActivity
import ManagedSettings
import UserNotifications
import Foundation

class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        ManagedSettingsStore().shield.applications = nil
        SharedState.isUnlocked = true
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        if let data = SharedState.selectedAppTokensData {
            if let tokens = try? NSKeyedUnarchiver.unarchivedObject(
                ofClasses: [NSSet.self],
                from: data
            ) as? Set<ApplicationToken> {
                ManagedSettingsStore().shield.applications = tokens
            }
        }

        SharedState.isUnlocked = false

        let content = UNMutableNotificationContent()
        content.title = "Screen time is up! ⏰"
        content.body = "Open Yoko and complete a lesson to unlock your apps again."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "yoko.timeup",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }
}
