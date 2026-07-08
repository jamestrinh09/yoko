//
//  HomeView.swift
//  Yoko
//

import SwiftUI

struct HomeView: View {
    @Environment(AppStore.self) private var store
    @Environment(ScreenTimeService.self) private var screenTime
    @Environment(ParentAccountService.self) private var account

    /// Switches the app to the Settings tab (provided by RootTabView) so the
    /// parent-device usage note can link straight to the child-device toggle.
    var onOpenSettings: (() -> Void)? = nil

    @State private var showSyncOffer: Bool = false
    @State private var showAccountSheet: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                greeting
                weeklyStreakCard
                quickStatsRow
                AppUsageCard()
                activeLocksSection
                rewardsPreview
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
        .dsScreenBackground()
        .onAppear(perform: maybeOfferSyncSetup)
        .onChange(of: account.isLinked) { _, linked in
            if linked { store.pendingSyncSetupOffer = false }
        }
        .sheet(isPresented: $showSyncOffer) {
            SyncSetupOfferSheet(
                onSetUp: {
                    showSyncOffer = false
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(350))
                        showAccountSheet = true
                    }
                },
                onLater: { showSyncOffer = false }
            )
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showAccountSheet) {
            ParentAccountSheet()
                .presentationDetents([.large])
        }
    }

    /// Shows the one-time sync-setup offer the first time a fresh-purchase parent
    /// (no account yet) lands on Home. Skipped for signed-in/linked parents and
    /// permanently after it has been shown once (persisted, not session state).
    private func maybeOfferSyncSetup() {
        guard store.pendingSyncSetupOffer, !account.isLinked, !store.hasShownSyncPrompt else { return }
        store.hasShownSyncPrompt = true
        showSyncOffer = true
    }

    /// Whether to render the live App Usage card on this device.
    /// - Single-device household (never linked): always live.
    /// - Linked household: only the device whose id matches the designated child
    ///   device shows live data; if no device has been explicitly marked yet,
    ///   default to showing live data here rather than hiding it.
    private var showsLiveUsage: Bool {
        guard account.isLinked else { return true }
        if let childId = store.childDeviceId { return childId == store.deviceId }
        return true
    }

    // MARK: - Greeting

    private var greeting: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(timeGreeting)
                    .font(.dsCallout)
                    .foregroundStyle(DS.Color.textSecondary)
                Text(store.profile.name)
                    .font(.dsDisplay)
                    .foregroundStyle(DS.Color.textPrimary)
            }
            Spacer()
            // App icon mark (replaces the old streak capsule — the streak now
            // lives in its own weekly card below).
            Image("AppMark")
                .resizable()
                .scaledToFill()
                .frame(width: 46, height: 46)
                .clipShape(.rect(cornerRadius: 13))
                .overlay(
                    RoundedRectangle(cornerRadius: 13)
                        .stroke(DS.Color.border, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.10), radius: 7, y: 3)
        }
        .padding(.top, 8)
    }

    private var bonusSubtitle: String {
        let remaining = max(0, 5 - store.profile.lessonsCompletedToday)
        if store.profile.freeUnlockMinutesAvailable > 0 {
            return "Bonus minutes from milestones"
        }
        if remaining == 0 {
            return "Daily lessons complete"
        }
        return "Finish \(remaining) more lesson\(remaining == 1 ? "" : "s") to earn bonuses"
    }

    private var timeGreeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 12 { return "Good morning" }
        if h < 18 { return "Good afternoon" }
        return "Good evening"
    }

    // MARK: - Weekly streak

    /// White card with a soft orange glow behind it, showing the current streak
    /// and which days this week the child has learned.
    private var weeklyStreakCard: some View {
        VStack(spacing: 18) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(DS.Color.accentSoft).frame(width: 42, height: 42)
                    Text("🔥")
                        .font(.system(size: 20))
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("Weekly Streak")
                        .font(.dsCaption)
                        .foregroundStyle(DS.Color.textSecondary)
                    HStack(alignment: .lastTextBaseline, spacing: 5) {
                        Text("\(store.profile.streak)")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(DS.Color.textPrimary)
                        Text(store.profile.streak == 1 ? "day" : "days")
                            .font(.dsCallout)
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                }
                Spacer()
            }

            HStack(spacing: 0) {
                ForEach(weekActivity) { day in
                    VStack(spacing: 7) {
                        ZStack {
                            Circle()
                                .fill(day.active ? DS.Color.accent : DS.Color.surface)
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle().stroke(day.active ? Color.clear : DS.Color.border, lineWidth: 1.5)
                                )
                            if day.active {
                                Text("🔥")
                                    .font(.system(size: 13))
                            }
                        }
                        .overlay {
                            if day.isToday {
                                Circle()
                                    .stroke(DS.Color.accent, lineWidth: 2)
                                    .frame(width: 38, height: 38)
                            }
                        }
                        .frame(height: 38)
                        Text(day.label)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(day.isToday ? DS.Color.accent : DS.Color.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(22)
        .background(DS.Color.surface)
        .clipShape(.rect(cornerRadius: DS.Radius.large))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.large)
                .stroke(DS.Color.border, lineWidth: 1)
        )
        // Subtle orange glow behind the white card.
        .shadow(color: DS.Color.accent.opacity(0.28), radius: 20, y: 8)
        .shadow(color: DS.Color.accent.opacity(0.10), radius: 5, y: 2)
    }

    /// The 7 days of the current week (Mon–Sun) with whether the child learned
    /// that day, derived from `weeklyMinutes`, plus a today marker.
    private var weekActivity: [DayActivity] {
        let labels = ["M", "T", "W", "T", "F", "S", "S"]
        let weekday = Calendar.current.component(.weekday, from: Date()) // 1=Sun...7=Sat
        let todayIndex = (weekday + 5) % 7 // Monday-based 0...6
        return (0..<7).map { i in
            let minutes = i < store.weeklyMinutes.count ? store.weeklyMinutes[i] : 0
            return DayActivity(
                id: i,
                label: labels[i],
                active: minutes > 0 || (i == todayIndex && store.profile.minutesLearnedToday > 0),
                isToday: i == todayIndex
            )
        }
    }

    // MARK: - App usage (parent device note)

    /// Shown on a non-child device in place of the live App Usage card. Usage can
    /// only be read on the device it happens on, so analytics live on the child's
    /// device — the parent flips the toggle in Settings to show it there.
    private var parentDeviceUsageNote: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "hourglass")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(DS.Color.accent)
                Text("App Usage")
                    .font(.dsTitle2)
                    .foregroundStyle(DS.Color.textPrimary)
                Spacer()
            }
            HStack(spacing: 12) {
                Image(systemName: "ipad.and.iphone")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(DS.Color.accent.opacity(0.7))
                Text("App usage is tracked on your child's device. Turn on \u{201C}This is the child's device\u{201D} in Settings to show it here.")
                    .font(.dsCaption)
                    .foregroundStyle(DS.Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 6)

            if let onOpenSettings {
                Button(action: onOpenSettings) {
                    HStack(spacing: 6) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Change in Settings")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(DS.Color.accent)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .background(DS.Color.surface)
        .clipShape(.rect(cornerRadius: DS.Radius.large))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.large)
                .stroke(DS.Color.border, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 6)
    }

    // MARK: - Stats

    private var quickStatsRow: some View {
        HStack(spacing: 12) {
            StatCard(symbol: "clock", value: "\(store.profile.minutesLearnedToday)m", label: "Learned today")
            StatCard(symbol: "checkmark.seal.fill", value: "\(store.profile.lessonsCompletedToday)", label: "Lessons done")
            StatCard(symbol: "gift.fill", value: "\(store.profile.earnedScreenTimeMinutes)m", label: "Earned time")
        }
    }

    // MARK: - Active locks

    private var activeLocksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Active Locks", trailing: "\(store.activeLocks.count)")
            VStack(spacing: 10) {
                ForEach(Array(store.activeLocks.prefix(3))) { lock in
                    HomeLockRow(lock: lock)
                }
            }
        }
    }

    // MARK: - Rewards preview

    private var rewardsPreview: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Rewards")
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Earned screen time")
                        .font(.dsCaption)
                        .foregroundStyle(DS.Color.textSecondary)
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(store.profile.earnedScreenTimeMinutes)")
                            .font(.dsDisplay)
                            .foregroundStyle(DS.Color.accent)
                        Text("min")
                            .font(.dsHeadline)
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                    ProgressBar(progress: min(1, Double(store.profile.earnedScreenTimeMinutes) / 90))
                        .frame(height: 8)
                        .padding(.top, 4)
                    Text("Daily cap: 90 min")
                        .font(.dsTiny)
                        .foregroundStyle(DS.Color.textTertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Bonus time")
                        .font(.dsCaption)
                        .foregroundStyle(DS.Color.textSecondary)
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(DS.Color.accent)
                        Text("+\(store.profile.freeUnlockMinutesAvailable) min")
                            .font(.dsTitle2)
                            .foregroundStyle(DS.Color.textPrimary)
                    }
                    Text(bonusSubtitle)
                        .font(.dsCaption)
                        .foregroundStyle(DS.Color.textSecondary)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DS.Color.accentSoft)
                .clipShape(.rect(cornerRadius: 16))
            }
            .dsCard(padding: 18)
        }
    }
}

/// One-time, dismissible prompt offering to set up cross-device sync after a
/// fresh purchase. "Set Up Sync" opens the existing Create Parent Account flow.
private struct SyncSetupOfferSheet: View {
    let onSetUp: () -> Void
    let onLater: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                ZStack {
                    Circle().fill(DS.Color.accentSoft).frame(width: 70, height: 70)
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(DS.Color.accent)
                }
                Text("Set up sync across your devices")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(DS.Color.textPrimary)
                    .multilineTextAlignment(.center)
                Text("Takes 30 seconds. Watch progress and manage locks from your phone while your child learns on theirs.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(DS.Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 28)

            Spacer(minLength: 0)

            VStack(spacing: 12) {
                Button(action: onSetUp) {
                    Text("Set Up Sync")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(DS.Color.accent)
                        .clipShape(.rect(cornerRadius: 18))
                        .shadow(color: DS.Color.accent.opacity(0.35), radius: 16, y: 8)
                }
                .buttonStyle(.plain)

                Button(action: onLater) {
                    Text("Maybe Later")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(DS.Color.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 18)
        .frame(maxWidth: .infinity)
        .background(DS.Color.background.ignoresSafeArea())
    }
}

/// One day cell in the weekly streak card.
private struct DayActivity: Identifiable {
    let id: Int
    let label: String
    let active: Bool
    let isToday: Bool
}

private struct HomeLockRow: View {
    let lock: AppLock

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(lock.iconColor.opacity(0.14))
                    .frame(width: 44, height: 44)
                Image(systemName: lock.symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(lock.iconColor)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(lock.name)
                    .font(.dsHeadline)
                    .foregroundStyle(DS.Color.textPrimary)
                Text(lock.type.subtitle)
                    .font(.dsCaption)
                    .foregroundStyle(DS.Color.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(lock.earnedMinutesAvailable)m")
                    .font(.dsHeadline)
                    .foregroundStyle(lock.earnedMinutesAvailable > 0 ? DS.Color.accent : DS.Color.textTertiary)
                Text("available")
                    .font(.dsTiny)
                    .foregroundStyle(DS.Color.textSecondary)
            }
        }
        .padding(14)
        .background(DS.Color.surface)
        .clipShape(.rect(cornerRadius: DS.Radius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.medium)
                .stroke(DS.Color.border, lineWidth: 1)
        )
    }
}
