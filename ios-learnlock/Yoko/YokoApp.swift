//
//  YokoApp.swift
//  Yoko
//

import SwiftUI
import RevenueCat

@main
struct YokoApp: App {
    @State private var store = AppStore()
    @State private var screenTime = ScreenTimeService()
    @State private var account = ParentAccountService()
    @State private var storeVM = StoreViewModel()
    @Environment(\.scenePhase) private var scenePhase

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
