//
//  RewardsView.swift
//  LearnLock
//

import SwiftUI

struct RewardsView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                header
                bankCard
                weeklyChart
                goalsCard
                achievementsGrid
                Spacer(minLength: 110)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
        .dsScreenBackground()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Rewards")
                .font(.dsDisplay)
                .foregroundStyle(DS.Color.textPrimary)
            Text("Time earned through learning")
                .font(.dsCallout)
                .foregroundStyle(DS.Color.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private var bankCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Screen Time Bank")
                        .font(.dsCaption)
                        .foregroundStyle(DS.Color.textSecondary)
                    HStack(alignment: .lastTextBaseline, spacing: 6) {
                        Text("\(store.profile.earnedScreenTimeMinutes)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(DS.Color.accent)
                        Text("min")
                            .font(.dsTitle2)
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                }
                Spacer()
                ZStack {
                    Circle().fill(DS.Color.accentSoft).frame(width: 76, height: 76)
                    Image(systemName: "gift.fill")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(DS.Color.accent)
                }
            }
            HStack(spacing: 12) {
                miniStat(symbol: "sparkles", value: "\(store.profile.totalXP)", label: "Total XP")
                miniStat(symbol: "flame.fill", value: "\(store.profile.streak)d", label: "Streak")
                miniStat(symbol: "checkmark.seal.fill", value: "\(store.profile.lessonsCompletedToday)", label: "Today")
            }
        }
        .dsCard(padding: 22)
    }

    private func miniStat(symbol: String, value: String, label: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(DS.Color.accent)
            VStack(alignment: .leading, spacing: 1) {
                Text(value).font(.dsHeadline).foregroundStyle(DS.Color.textPrimary)
                Text(label).font(.dsTiny).foregroundStyle(DS.Color.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(DS.Color.background)
        .clipShape(.rect(cornerRadius: 12))
    }

    private var weeklyChart: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("This Week")
                    .font(.dsTitle2)
                    .foregroundStyle(DS.Color.textPrimary)
                Spacer()
                Text("\(store.weeklyMinutes.reduce(0, +)) min")
                    .font(.dsCallout)
                    .foregroundStyle(DS.Color.textSecondary)
            }
            let maxV = max(store.weeklyMinutes.max() ?? 1, 1)
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(Array(store.weeklyMinutes.enumerated()), id: \.offset) { i, v in
                    VStack(spacing: 8) {
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(DS.Color.accentSoft)
                                .frame(width: 28, height: 110)
                            RoundedRectangle(cornerRadius: 8)
                                .fill(DS.Color.accent)
                                .frame(width: 28, height: max(8, CGFloat(v) / CGFloat(maxV) * 110))
                        }
                        Text(["M", "T", "W", "T", "F", "S", "S"][i])
                            .font(.dsTiny)
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .dsCard()
    }

    private var goalsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Daily Goals")
            VStack(spacing: 12) {
                goalRow(title: "Learn 30 minutes", progress: store.dailyProgress, value: "\(store.profile.minutesLearnedToday)/\(store.profile.dailyMinuteGoal) min")
                goalRow(title: "Complete 5 lessons", progress: min(1, Double(store.profile.lessonsCompletedToday) / 5), value: "\(store.profile.lessonsCompletedToday)/5")
                goalRow(title: "Keep your streak", progress: 1, value: "\(store.profile.streak)-day")
            }
            .dsCard()
        }
    }

    private func goalRow(title: String, progress: Double, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title).font(.dsHeadline).foregroundStyle(DS.Color.textPrimary)
                Spacer()
                Text(value).font(.dsCaption).foregroundStyle(DS.Color.textSecondary)
            }
            ProgressBar(progress: progress, height: 8)
        }
    }

    private var achievementsGrid: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Achievements", trailing: "\(store.achievements.filter(\.unlocked).count)/\(store.achievements.count)")
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(store.achievements) { a in
                    AchievementCard(achievement: a)
                }
            }
        }
    }
}

private struct AchievementCard: View {
    let achievement: Achievement

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(achievement.unlocked ? DS.Color.accentSoft : DS.Color.background)
                    .frame(width: 44, height: 44)
                Image(systemName: achievement.symbol)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(achievement.unlocked ? DS.Color.accent : DS.Color.textTertiary)
            }
            Text(achievement.title)
                .font(.dsHeadline)
                .foregroundStyle(achievement.unlocked ? DS.Color.textPrimary : DS.Color.textSecondary)
            Text(achievement.detail)
                .font(.dsCaption)
                .foregroundStyle(DS.Color.textSecondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsCard(padding: 16)
        .opacity(achievement.unlocked ? 1 : 0.7)
    }
}
