//
//  YokoApp.swift
//  Yoko
//

import SwiftUI
import RevenueCat
import UserNotifications

// MARK: - Notification Delegate

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    var onLessonRedirect: (() -> Void)?

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let id = response.notification.request.identifier
        if id == "yoko.unlock" || id == "yoko.timeup" {
            onLessonRedirect?()
        }
        completionHandler()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}

@main
struct YokoApp: App {
    @State private var store = AppStore()
    @State private var screenTime = ScreenTimeService()
    @State private var account = ParentAccountService()
    @State private var storeVM = StoreViewModel()
    @Environment(\.scenePhase) private var scenePhase

    private let notificationDelegate = NotificationDelegate()

    init() {
        // Configure RevenueCat once, before any Purchases.shared access. DEBUG/
        // sandbox builds use the Test Store key; release uses the App Store key.
        #if DEBUG
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: Config.EXPO_PUBLIC_REVENUECAT_TEST_API_KEY)
        #else
        Purchases.configure(withAPIKey: Config.EXPO_PUBLIC_REVENUECAT_IOS_API_KEY)
        #endif
        MediaPreloader.preloadAll()
        UNUserNotificationCenter.current().delegate = notificationDelegate
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if store.onboardingComplete {
                    RootTabView()
                } else {
                    OnboardingView()
                }
            }
            .environment(store)
            .environment(screenTime)
            .environment(account)
            .environment(storeVM)
            .preferredColorScheme(.light)
            .tint(DS.Color.accent)
            .task {
                notificationDelegate.onLessonRedirect = { [store] in
                    store.pendingLessonRedirect = true
                }
                if account.isLinked, let remote = await account.pull() {
                    store.applySnapshot(remote)
                }
            }
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active, account.isLinked else { return }
                Task {
                    if let remote = await account.pull() { store.applySnapshot(remote) }
                }
            }
        }
    }
}
