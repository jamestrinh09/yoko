//
//  HomeView.swift
//  LearnLock
//

import SwiftUI

struct HomeView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                greeting
                progressCard
                quickStatsRow
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
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(DS.Color.accent)
                Text("\(store.profile.streak)")
                    .font(.dsHeadline)
                    .foregroundStyle(DS.Color.textPrimary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(DS.Color.accentSoft)
            .clipShape(.capsule)
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

    // MARK: - Progress

    private var progressCard: some View {
        HStack(spacing: 18) {
            ZStack {
                ProgressRing(progress: store.dailyProgress, size: 96, lineWidth: 10)
                VStack(spacing: 0) {
                    Text("\(Int(store.dailyProgress * 100))%")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(DS.Color.textPrimary)
                    Text("today")
                        .font(.dsTiny)
                        .foregroundStyle(DS.Color.textSecondary)
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Daily Goal")
                    .font(.dsCaption)
                    .foregroundStyle(DS.Color.textSecondary)
                Text("\(store.profile.minutesLearnedToday) / \(store.profile.dailyMinuteGoal) min")
                    .font(.dsTitle2)
                    .foregroundStyle(DS.Color.textPrimary)
                Text("Keep going to earn more screen time")
                    .font(.dsCaption)
                    .foregroundStyle(DS.Color.textSecondary)
                    .padding(.top, 2)
            }
            Spacer()
        }
        .dsCard(padding: 22)
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
