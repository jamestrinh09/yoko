//
//  RootTabView.swift
//  Yoko
//

import SwiftUI

enum AppTab: Hashable, CaseIterable {
    case home, learn, locks, rewards, settings

    var title: String {
        switch self {
        case .home: "Home"
        case .learn: "Learn"
        case .locks: "Locks"
        case .rewards: "Rewards"
        case .settings: "Settings"
        }
    }

    var symbol: String {
        switch self {
        case .home: "house.fill"
        case .learn: "graduationcap.fill"
        case .locks: "lock.fill"
        case .rewards: "gift.fill"
        case .settings: "gearshape.fill"
        }
    }
}

struct RootTabView: View {
    @Environment(AppStore.self) private var store
    @State private var selection: AppTab = .home
    @State private var hideDock: Bool = false

    var body: some View {
        ZStack(alignment: .bottom) {
            DS.Color.background.ignoresSafeArea()

            Group {
                switch selection {
                case .home: HomeView(onOpenSettings: { selection = .settings })
                case .learn: LearnView(hideDock: $hideDock)
                case .locks: LocksView()
                case .rewards: RewardsView()
                case .settings: SettingsView()
                }
            }
            .iPadScaled()
            .transition(.opacity)

            if !hideDock {
                FloatingTabBar(selection: $selection)
                    .frame(maxWidth: 520)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.4), value: selection)
        .animation(.spring(duration: 0.35), value: hideDock)
        .onChange(of: store.pendingLessonRedirect) { _, pending in
            if pending {
                selection = .learn
                store.pendingLessonRedirect = false
            }
        }
    }
}

struct FloatingTabBar: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button {
                    let gen = UIImpactFeedbackGenerator(style: .light)
                    gen.impactOccurred()
                    selection = tab
                } label: {
                    VStack(spacing: 3) {
                        ZStack {
                            if selection == tab {
                                Capsule()
                                    .fill(DS.Color.accent.opacity(0.18))
                                    .frame(width: 48, height: 34)
                                    .matchedGeometryEffect(id: "tab", in: ns)
                            }
                            Image(systemName: tab.symbol)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(selection == tab ? DS.Color.accent : DS.Color.textTertiary)
                                .frame(width: 28, height: 28)
                        }
                        .frame(height: 34)
                        Text(tab.title)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(selection == tab ? DS.Color.accent : DS.Color.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.10), radius: 20, x: 0, y: 10)
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.35), lineWidth: 1)
        )
    }

    @Namespace private var ns
}
