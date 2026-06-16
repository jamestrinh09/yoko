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
        VStack(spacing: 14) {
            SequencedStreakGIFView(firstURL: GIFAssets.streak1, loopURL: GIFAssets.streak2)
                .frame(width: 180, height: 180)
                .shadow(color: .black.opacity(0.08), radius: 12, y: 6)

            StreakRevealText(text: "\(streak) \(streakUnit) streak!", size: 24, color: DS.Color.accent)
                .padding(.top, -10)

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
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

// MARK: - Left-to-Right Reveal Text

/// Animates a string in character-by-character from left to right with a soft
/// fade + slide, so the streak label reads in like a sweep when the view opens.
struct StreakRevealText: View {
    let text: String
    var size: CGFloat = 24
    var color: Color = .white
    @State private var appeared = false

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(text.enumerated()), id: \.offset) { idx, ch in
                Text(String(ch))
                    .font(.system(size: size, weight: .heavy, design: .rounded))
                    .foregroundStyle(color)
                    .opacity(appeared ? 1 : 0)
                    .offset(x: appeared ? 0 : -10)
                    .animation(.easeOut(duration: 0.35).delay(Double(idx) * 0.045), value: appeared)
            }
        }
        .onAppear { appeared = true }
    }
}

// MARK: - Sequenced Streak GIF

/// Plays the intro streak GIF once, then transitions into a second GIF that
/// loops forever. ImageIO-backed so transparency and frame timing are exact.
struct SequencedStreakGIFView: UIViewRepresentable {
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
