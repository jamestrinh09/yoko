//
//  LearnLockApp.swift
//  LearnLock
//

import SwiftUI

@main
struct LearnLockApp: App {
    @State private var store = AppStore()
    @State private var screenTime = ScreenTimeService()
    @State private var account = ParentAccountService()
    @Environment(\.scenePhase) private var scenePhase

    init() {
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
