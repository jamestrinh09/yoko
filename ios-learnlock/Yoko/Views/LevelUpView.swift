//
//  LevelUpView.swift
//  Yoko
//
//  Celebration screen shown when a child completes enough lessons to level up
//  in a subject. Uses the same orange gradient and animation style as
//  StreakCelebrationView.
//

import SwiftUI

struct LevelUpView: View {
    let subject: Subject
    let newLevel: Int
    let onDismiss: () -> Void

    @State private var appear: Bool = false

    var body: some View {
        ZStack {
            background
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                levelContent
                    .scaleEffect(appear ? 1 : 0.9)
                    .opacity(appear ? 1 : 0)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 24)
            .safeAreaInset(edge: .bottom) {
                continueButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
            }
        }
        .ignoresSafeArea()
        .onAppear(perform: animateIn)
    }

    // MARK: - Background

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 1.00, green: 0.58, blue: 0.15),
                    Color(red: 1.00, green: 0.42, blue: 0.00),
                    Color(red: 0.93, green: 0.30, blue: 0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(
                colors: [Color.white.opacity(0.28), .clear],
                center: .center,
                startRadius: 10,
                endRadius: 360
            )
        }
    }

    // MARK: - Level Content

    private var levelContent: some View {
        VStack(spacing: 20) {
            AnimatedGIFView(urlString: GIFAssets.excited)
                .frame(width: 160, height: 160)
                .frame(maxWidth: .infinity)

            levelBadge

            Text("Level \(newLevel) Unlocked! 🎉")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text("You completed Level \(newLevel - 1) of \(subject.title)")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)

            Text("New questions await in Level \(newLevel)!")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }

    private var levelBadge: some View {
        ZStack {
            Text("🛡️")
                .font(.system(size: 120))
                .opacity(0.25)
            Text("\(newLevel)")
                .font(.system(size: 96, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(width: 200, height: 200)
    }

    private var continueButton: some View {
        Button(action: onDismiss) {
            Text("Let's keep learning →")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(DS.Color.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color.white)
                .clipShape(.rect(cornerRadius: 20))
                .shadow(color: .black.opacity(0.15), radius: 16, y: 8)
        }
        .buttonStyle(.plain)
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 20)
    }

    private func animateIn() {
        withAnimation(.spring(duration: 0.55, bounce: 0.35)) { appear = true }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
