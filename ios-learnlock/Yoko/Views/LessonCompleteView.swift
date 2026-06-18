//
//  LessonCompleteView.swift
//  Yoko
//
//  Celebration screen shown after a lesson. Animates the XP earned and
//  surfaces any milestone rewards (bonus free time, achievements, grade
//  promotion) on a clean white card over the nature hero.
//

import SwiftUI

struct LessonCompleteView: View {
    let result: LessonResult
    let rewards: [MilestoneReward]
    let childName: String
    /// The unlock rule chosen in onboarding ("session", "time", or "daily").
    /// Drives which primary reward is shown — screen-time minutes only appear
    /// for the "time" rule.
    let unlockRule: String
    let onDone: () -> Void
    let onTellParent: () -> Void

    @State private var displayXP: Int = 0
    @State private var showPerfect: Bool = false
    @State private var revealRewards: Bool = false
    @State private var screenHeight: CGFloat = 852

    private var mascotURL: String {
        result.isPerfect ? GIFAssets.excited : GIFAssets.proud
    }

    // MARK: - Derived rewards

    private var bonusMinutes: Int {
        rewards.reduce(0) { acc, r in
            if case let .freeScreenTime(minutes) = r { return acc + minutes }
            return acc
        }
    }

    private var unlockedAchievements: [Achievement] {
        rewards.compactMap { if case let .achievementUnlocked(a) = $0 { return a } else { return nil } }
    }

    private var promotion: GradePromotion? {
        for r in rewards { if case let .gradePromotionReady(p) = r { return p } }
        return nil
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            ZStack {
                splitBackground
                VStack(spacing: 0) {
                    // Reserve the same hero spacing the question page uses (its
                    // close-button row) so the mascot + card land in an identical
                    // position — the card no longer looks taller than the lesson.
                    Color.clear.frame(height: screenHeight * 0.06 + 36)
                    // Same GIF renderer + offset as the question page so the
                    // mascot and card land at an identical level.
                    AnimatedGIFView(urlString: mascotURL)
                        .frame(width: 162, height: 162)
                        .padding(.top, -9)
                        .offset(y: -40)
                        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
                    card
                }
            }
            .onAppear { screenHeight = geo.size.height }
            .onChange(of: geo.size.height) { _, newValue in
                if abs(newValue - screenHeight) > 1 { screenHeight = newValue }
            }
        }
        .ignoresSafeArea()
        .onAppear(perform: runAnimations)
    }

    private var splitBackground: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                Image("HeroBackground")
                    .resizable().scaledToFill().scaleEffect(1.05).offset(y: -72)
                    .clipped()
                LinearGradient(colors: [.clear, .white.opacity(0.95)], startPoint: .top, endPoint: .bottom)
                    .frame(height: 110)
            }
            .frame(height: screenHeight * 0.50)
            Color.white.frame(maxHeight: .infinity)
        }
        .ignoresSafeArea()
    }

    // MARK: - Card

    private var card: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    headline
                    xpCounter
                    if result.isPerfect { perfectBadge }
                    rewardRows
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 12)
            }
            doneButton
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(.rect(topLeadingRadius: 30, topTrailingRadius: 30))
        .shadow(color: .black.opacity(0.04), radius: 16, x: 0, y: -4)
        .padding(.top, -31)
    }

    private var headline: some View {
        VStack(spacing: 6) {
            Text("Lesson Complete!")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(DS.Color.textPrimary)
            Text("\(result.correctCount) of \(result.totalQuestions) correct")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(DS.Color.textSecondary)
        }
    }

    private var xpCounter: some View {
        Text("+\(displayXP) XP ✨")
            .font(.system(size: 34, weight: .heavy, design: .rounded))
            .foregroundStyle(DS.Color.accent)
            .contentTransition(.numericText())
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
    }

    private var perfectBadge: some View {
        Text("Perfect! ⭐")
            .font(.system(size: 16, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 22)
            .padding(.vertical, 10)
            .background(DS.Color.accent)
            .clipShape(.capsule)
            .shadow(color: DS.Color.accent.opacity(0.4), radius: 12, y: 6)
            .scaleEffect(showPerfect ? 1 : 0.2)
            .opacity(showPerfect ? 1 : 0)
    }

    @ViewBuilder
    private var rewardRows: some View {
        VStack(spacing: 12) {
            // The primary reward reflects the unlock rule the parent chose during
            // onboarding — screen-time minutes are only "earned" for the time
            // rule, not for the session/daily unlock rules.
            primaryRewardCard

            if bonusMinutes > 0 {
                rewardCard(symbol: "party.popper.fill", text: "🎉 +\(bonusMinutes) min bonus free time earned!")
                    .opacity(revealRewards ? 1 : 0)
                    .scaleEffect(revealRewards ? 1 : 0.85)
            }

            ForEach(Array(unlockedAchievements.enumerated()), id: \.offset) { _, a in
                rewardCard(symbol: a.symbol, text: "🏅 Achievement unlocked: \(a.title)")
                    .opacity(revealRewards ? 1 : 0)
                    .scaleEffect(revealRewards ? 1 : 0.85)
            }

            if let promo = promotion {
                promotionBanner(promo)
                    .opacity(revealRewards ? 1 : 0)
                    .scaleEffect(revealRewards ? 1 : 0.9)
            }
        }
        .padding(.top, 10)
    }

    /// The headline reward, matched to the onboarding unlock rule so it never
    /// claims screen time was earned when the rule doesn't grant minutes.
    @ViewBuilder
    private var primaryRewardCard: some View {
        switch unlockRule {
        case "time":
            rewardCard(symbol: "clock.fill", text: "+30m screen time earned")
        case "daily":
            rewardCard(symbol: "sun.max.fill", text: "Play unlocked for the rest of today!")
        default:
            rewardCard(symbol: "lock.open.fill", text: "Play unlocked for this session!")
        }
    }

    /// Gradient-orange reward row used for earned time, bonuses and achievements.
    private func rewardCard(symbol: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(.white.opacity(0.22))
                .clipShape(.rect(cornerRadius: 10))
            Text(text)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(rewardGradient)
        .clipShape(.rect(cornerRadius: 16))
        .shadow(color: DS.Color.accent.opacity(0.28), radius: 10, y: 5)
    }

    private var rewardGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 1.0, green: 0.58, blue: 0.15), Color(red: 1.0, green: 0.42, blue: 0.0)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func promotionBanner(_ promo: GradePromotion) -> some View {
        VStack(spacing: 12) {
            Text("🎓 \(childName) is ready for the next grade!")
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundStyle(DS.Color.accent)
                .multilineTextAlignment(.center)
            Button(action: onTellParent) {
                Text("Tell a parent →")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(DS.Color.accent)
                    .clipShape(.rect(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(DS.Color.accentSoft)
        .clipShape(.rect(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(DS.Color.accent, lineWidth: 1.5))
    }

    private var doneButton: some View {
        Button(action: onDone) {
            Text("Done")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(DS.Color.accent)
                .clipShape(.rect(cornerRadius: 20))
                .shadow(color: DS.Color.accent.opacity(0.35), radius: 16, y: 8)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 32)
    }

    // MARK: - Animations

    private func runAnimations() {
        let target = result.xpEarned
        let steps = 20
        Task {
            for i in 1...steps {
                try? await Task.sleep(for: .seconds(0.8 / Double(steps)))
                await MainActor.run {
                    withAnimation(.easeOut(duration: 0.05)) { displayXP = target * i / steps }
                }
            }
            await MainActor.run { displayXP = target }
        }
        if result.isPerfect {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(duration: 0.5, bounce: 0.4)) { showPerfect = true }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.spring(duration: 0.5, bounce: 0.3)) { revealRewards = true }
        }
    }
}
