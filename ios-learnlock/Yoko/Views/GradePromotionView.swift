//
//  GradePromotionView.swift
//  Yoko
//
//  Parent-facing approval screen for a pending grade promotion.
//

import SwiftUI

struct GradePromotionView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let promotion: GradePromotion

    @State private var celebrate: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                childHeader
                gradeTransition
                statsGrid
                buttons
                Spacer(minLength: 12)
            }
            .padding(.horizontal, 22)
            .padding(.top, 20)
        }
        .dsScreenBackground()
    }

    private var childHeader: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle().fill(DS.Color.accent).frame(width: 76, height: 76)
                Text(String(store.profile.name.prefix(1)))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .scaleEffect(celebrate ? 1.05 : 1)
            .animation(.spring(duration: 0.6, bounce: 0.4).repeatCount(3, autoreverses: true), value: celebrate)

            Text("\(store.profile.name) is ready to level up!")
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(DS.Color.textPrimary)
                .multilineTextAlignment(.center)
            Text("They've finished \(promotion.lessonsCompleted) lessons and earned a promotion.")
                .font(.dsCallout)
                .foregroundStyle(DS.Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
        .onAppear { celebrate = true }
    }

    private var gradeTransition: some View {
        HStack(spacing: 16) {
            gradePill(title: "Current", grade: promotion.fromGrade, accent: false)
            Image(systemName: "arrow.right")
                .font(.system(size: 20, weight: .heavy))
                .foregroundStyle(DS.Color.accent)
            gradePill(title: "Next", grade: promotion.toGrade, accent: true)
        }
        .frame(maxWidth: .infinity)
        .dsCard()
    }

    private func gradePill(title: String, grade: GradeBand, accent: Bool) -> some View {
        VStack(spacing: 6) {
            Text(title.uppercased())
                .font(.dsTiny)
                .foregroundStyle(DS.Color.textSecondary)
            Text(grade.rawValue)
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .foregroundStyle(accent ? .white : DS.Color.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(accent ? DS.Color.accent : DS.Color.surfaceWarm)
                .clipShape(.rect(cornerRadius: 14))
        }
        .frame(maxWidth: .infinity)
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            statCard(symbol: "checkmark.seal.fill", value: "\(store.profile.totalLessonsCompleted)", label: "Lessons")
            statCard(symbol: "sparkles", value: "\(store.profile.lifetimeXP)", label: "Lifetime XP")
            statCard(symbol: "target", value: "\(Int(store.profile.overallAccuracy * 100))%", label: "Accuracy")
            statCard(symbol: "rosette", value: "\(store.profile.achievements.count)", label: "Achievements")
        }
    }

    private func statCard(symbol: String, value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(DS.Color.accent)
            Text(value)
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundStyle(DS.Color.textPrimary)
            Text(label)
                .font(.dsCaption)
                .foregroundStyle(DS.Color.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 96)
        .dsCard(padding: 16)
    }

    private var buttons: some View {
        VStack(spacing: 12) {
            Button {
                store.approveGradePromotion()
                dismiss()
            } label: {
                Text("Approve Promotion 🎓")
            }
            .buttonStyle(DSPrimaryButtonStyle())

            Button {
                store.keepPractising()
                dismiss()
            } label: {
                Text("Keep Practising")
            }
            .buttonStyle(DSSecondaryButtonStyle())
        }
        .padding(.top, 4)
    }
}
