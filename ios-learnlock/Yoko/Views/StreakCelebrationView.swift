//
//  StreakCelebrationView.swift
//  Yoko
//
//  Shown after a lesson is completed. Celebrates the child's learning streak on
//  a warm orange gradient with a mascot GIF inside a floating streak card.
//

import SwiftUI

struct StreakCelebrationView: View {
    let streak: Int
    let childName: String
    let onContinue: () -> Void

    @State private var appear: Bool = false
    @State private var flameScale: CGFloat = 0.4



    private var streakUnit: String { streak == 1 ? "day" : "days" }

    var body: some View {
        ZStack {
            background
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                streakCard
                    .scaleEffect(appear ? 1 : 0.85)
                    .opacity(appear ? 1 : 0)
                Spacer(minLength: 0)
                continueButton
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
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
            // Soft radial glow behind the card for depth.
            RadialGradient(
                colors: [Color.white.opacity(0.28), .clear],
                center: .center,
                startRadius: 10,
                endRadius: 360
            )
        }
    }

    // MARK: - Streak Card

    private var streakCard: some View {
        VStack(spacing: 18) {
            SequencedStreakGIFView(firstURL: GIFAssets.streak1, loopURL: GIFAssets.streak2)
                .frame(width: 150, height: 150)
                .shadow(color: .black.opacity(0.08), radius: 12, y: 6)

            HStack(spacing: 10) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 40, weight: .heavy))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 1.0, green: 0.72, blue: 0.20), DS.Color.accent],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .scaleEffect(flameScale)
                Text("\(streak)")
                    .font(.system(size: 64, weight: .heavy, design: .rounded))
                    .foregroundStyle(DS.Color.textPrimary)
                    .contentTransition(.numericText())
            }

            Text("\(streak)-\(streakUnit) streak!")
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(DS.Color.accent)

            Text(message)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(DS.Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
        .padding(.vertical, 32)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(.rect(cornerRadius: 32))
        .shadow(color: .black.opacity(0.18), radius: 28, y: 14)
    }

    private var message: String {
        switch streak {
        case 1: return "Great start, \(childName)! Come back tomorrow to keep it going."
        case 2...4: return "\(childName) is building a habit. Keep the flame alive!"
        default: return "\(childName) is on fire! Learning every day pays off."
        }
    }

    private var continueButton: some View {
        Button(action: onContinue) {
            Text("Continue")
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
        withAnimation(.spring(duration: 0.7, bounce: 0.5).delay(0.15)) { flameScale = 1.0 }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

// MARK: - Sequenced Streak GIF

/// Plays the intro streak GIF once, then transitions into a second GIF that
/// loops forever. ImageIO-backed so transparency and frame timing are exact.
private struct SequencedStreakGIFView: UIViewRepresentable {
    let firstURL: String
    let loopURL: String

    func makeUIView(context: Context) -> SequencedGIFImageView {
        let view = SequencedGIFImageView()
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        view.backgroundColor = .clear
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        view.setContentHuggingPriority(.defaultLow, for: .vertical)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        view.start(firstURL: firstURL, loopURL: loopURL)
        return view
    }

    func updateUIView(_ uiView: SequencedGIFImageView, context: Context) {}

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: SequencedGIFImageView, context: Context) -> CGSize? {
        proposal.replacingUnspecifiedDimensions()
    }
}

final class SequencedGIFImageView: UIImageView {
    override var intrinsicContentSize: CGSize { .zero }
    private var didStart = false

    func start(firstURL: String, loopURL: String) {
        guard !didStart else { return }
        didStart = true
        loadFrames(firstURL) { [weak self] first in
            guard let self, let first else { return }
            self.playOnce(first) {
                self.loadFrames(loopURL) { [weak self] loop in
                    guard let self, let loop else { return }
                    self.playLoop(loop)
                }
            }
        }
    }

    private func playOnce(_ gif: DecodedGIF, completion: @escaping () -> Void) {
        animationImages = gif.frames
        animationDuration = gif.duration
        animationRepeatCount = 1
        image = gif.frames.last
        startAnimating()
        DispatchQueue.main.asyncAfter(deadline: .now() + gif.duration, execute: completion)
    }

    private func playLoop(_ gif: DecodedGIF) {
        UIView.transition(with: self, duration: 0.22, options: [.transitionCrossDissolve, .allowUserInteraction]) {
            self.animationImages = gif.frames
            self.animationDuration = gif.duration
            self.animationRepeatCount = 0
            self.image = gif.frames.first
            self.startAnimating()
        }
    }

    private func loadFrames(_ urlString: String, completion: @escaping (DecodedGIF?) -> Void) {
        if let data = GIFCache.shared.data(for: urlString) {
            completion(UIImage.decodeGIFFrames(data: data))
            return
        }
        guard let url = URL(string: urlString) else { completion(nil); return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data else { Task { @MainActor in completion(nil) }; return }
            GIFCache.shared.set(data, for: urlString)
            Task { @MainActor in completion(UIImage.decodeGIFFrames(data: data)) }
        }.resume()
    }
}
