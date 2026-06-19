//
//  AppLockedView.swift
//  Yoko
//
//  Full-screen popup shown when the child opens an app that Yoko has locked.
//  Centers the armored mascot with a clear "app locked" message and a single
//  orange call-to-action that launches a learning session to earn unlock time.
//

import SwiftUI

struct AppLockedView: View {
    /// Invoked when the child taps the "let's learn" call-to-action.
    let onLearn: () -> Void

    @State private var appear: Bool = false

    var body: some View {
        ZStack {
            DS.Color.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                VStack(spacing: 18) {
                    MascotGIF(url: GIFAssets.armor, size: 220)
                        .frame(maxWidth: .infinity)

                    Text("app locked by Yoko")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundStyle(DS.Color.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("learn to unlock your apps (you'll get a notification that will open Yoko)")
                        .font(.system(size: 18, weight: .regular, design: .rounded))
                        .foregroundStyle(DS.Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                        .padding(.horizontal, 28)
                }
                .scaleEffect(appear ? 1 : 0.92)
                .opacity(appear ? 1 : 0)

                Spacer(minLength: 0)

                Button(action: onLearn) {
                    Text("let's learn 🤩!")
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
}

#Preview {
    AppLockedView(onLearn: {})
}
