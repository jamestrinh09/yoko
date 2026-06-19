//
//  HomeView.swift
//  Yoko
//

import SwiftUI

struct HomeView: View {
    @Environment(AppStore.self) private var store
    @Environment(ScreenTimeService.self) private var screenTime

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
                    Image(systemName: "flame.fill")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(DS.Color.accent)
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
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .heavy))
                                    .foregroundStyle(.white)
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
