//
//  AppLockedView.swift
//  Yoko
//
//  Full-screen popup shown when the child opens an app that Yoko has locked.
//  Centers the blocked-app hero image with a clear "app locked" message. Tapping
//  the call-to-action fires the "your apps are blocked!" notification that opens
//  Yoko, and guides the child to tap it (with a fallback if it never arrives).
//

import SwiftUI
import UserNotifications

struct AppLockedView: View {
    /// Invoked when the child taps the "let's learn" call-to-action.
    let onLearn: () -> Void

    /// The stages of the unlock prompt the child walks through.
    private enum Stage {
        case initial        // "let's learn 🤩!"
        case tapNotification // notification sent, waiting for the tap
        case checkSettings  // notification re-sent, point them to settings
    }

    @State private var stage: Stage = .initial
    @State private var appear: Bool = false

    /// Title and subtext share this size per the design request.
    private let textSize: CGFloat = 28

    private var subtext: String {
        switch stage {
        case .initial:
            return "learn to unlock your apps (you'll get a notification that will open Yoko)"
        case .tapNotification:
            return "⬆️ tap the notification ⬆️"
        case .checkSettings:
            return "head over to the Yoko app (notification settings might be turned off)"
        }
    }

    private var ctaTitle: String {
        switch stage {
        case .initial:
            return "let's learn 🤩!"
        case .tapNotification, .checkSettings:
            return "didn't receive a notification?"
        }
    }

    var body: some View {
        ZStack {
            DS.Color.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                VStack(spacing: 18) {
                    Image("AppLockedHero")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 220, height: 220)
                        .frame(maxWidth: .infinity)

                    Text("app locked by Yoko")
                        .font(.system(size: textSize, weight: .heavy, design: .rounded))
                        .foregroundStyle(DS.Color.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(subtext)
                        .font(.system(size: textSize, weight: .regular, design: .rounded))
                        .foregroundStyle(DS.Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                        .padding(.horizontal, 28)
                        .transition(.opacity)
                        .id(subtext)
                }
                .scaleEffect(appear ? 1 : 0.92)
                .opacity(appear ? 1 : 0)

                Spacer(minLength: 0)

                Button(action: handleCTA) {
                    Text(ctaTitle)
                }
                .buttonStyle(DSPrimaryButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 20)
        }
        }
        .onAppear {
            withAnimation(.spring(duration: 0.55, bounce: 0.3)) { appear = true }
        }
    }

    private func handleCTA() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        switch stage {
        case .initial:
            sendBlockedNotification()
            withAnimation(.spring(duration: 0.4, bounce: 0.25)) { stage = .tapNotification }
            onLearn()
        case .tapNotification:
            sendBlockedNotification()
            withAnimation(.spring(duration: 0.4, bounce: 0.25)) { stage = .checkSettings }
        case .checkSettings:
            sendBlockedNotification()
        }
    }

    /// Fires the "your apps are blocked!" local notification that opens Yoko.
    private func sendBlockedNotification() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "your apps are blocked!"
            content.body = "let's learn"
            content.sound = .default
            let request = UNNotificationRequest(
                identifier: "apps_blocked",
                content: content,
                trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            )
            center.add(request)
        }
    }
}

#Preview {
    AppLockedView(onLearn: {})
}
