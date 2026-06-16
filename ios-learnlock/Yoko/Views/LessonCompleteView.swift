//
//  LessonCompleteView.swift
//  Yoko
//
//  Celebration screen shown after a lesson. Animates the XP earned and
//  surfaces any milestone rewards (bonus free time, achievements, grade
//  promotion) on a clean white card over the nature hero.
//

import SwiftUI
import WebKit

struct LessonCompleteView: View {
    let result: LessonResult
    let rewards: [MilestoneReward]
    let childName: String
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

    private var baseScreenTime: Int { result.totalQuestions / 2 + 5 }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            ZStack {
                background
                VStack(spacing: 0) {
                    Spacer(minLength: geo.size.height * 0.05)
                    MascotGIFView(urlString: mascotURL)
                        .frame(width: 132, height: 132)
                        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
                    card
                }
            }
            .onAppear { screenHeight = geo.size.height }
        }
        .ignoresSafeArea()
        .onAppear(perform: runAnimations)
    }

    private var background: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                Image("HeroBackground")
                    .resizable().scaledToFill().scaleEffect(1.05).offset(y: -29)
                    .clipped()
                LinearGradient(colors: [.clear, .white.opacity(0.95)], startPoint: .top, endPoint: .bottom)
                    .frame(height: 110)
            }
            .frame(height: screenHeight * 0.40)
            Color.white.frame(maxHeight: .infinity)
        }
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
        .shadow(color: .black.opacity(0.05), radius: 16, x: 0, y: -4)
        .padding(.top, 7)
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
            infoRow(symbol: "clock.fill", tint: DS.Color.accent,
                    text: "+\(baseScreenTime)m screen time earned", highlighted: false)

            if bonusMinutes > 0 {
                infoRow(symbol: "party.popper.fill", tint: DS.Color.accent,
                        text: "🎉 +\(bonusMinutes) min bonus free time earned!", highlighted: true)
                    .opacity(revealRewards ? 1 : 0)
                    .scaleEffect(revealRewards ? 1 : 0.85)
            }

            ForEach(Array(unlockedAchievements.enumerated()), id: \.offset) { _, a in
                infoRow(symbol: a.symbol, tint: DS.Color.accent,
                        text: "🏅 Achievement unlocked: \(a.title)", highlighted: true)
                    .opacity(revealRewards ? 1 : 0)
                    .scaleEffect(revealRewards ? 1 : 0.85)
            }

            if let promo = promotion {
                promotionBanner(promo)
                    .opacity(revealRewards ? 1 : 0)
                    .scaleEffect(revealRewards ? 1 : 0.9)
            }
        }
    }

    private func infoRow(symbol: String, tint: Color, text: String, highlighted: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(DS.Color.accentSoft)
                .clipShape(.rect(cornerRadius: 10))
            Text(text)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(DS.Color.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(highlighted ? DS.Color.accentSoft : DS.Color.surfaceWarm)
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(highlighted ? DS.Color.accent.opacity(0.5) : DS.Color.border, lineWidth: highlighted ? 1.5 : 1)
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

// MARK: - Mascot GIF

private struct MascotGIFView: UIViewRepresentable {
    let urlString: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard context.coordinator.loadedURL != urlString else { return }
        context.coordinator.loadedURL = urlString
        let css = "<style>html,body{margin:0;background:transparent;width:100%;height:100%;overflow:hidden;}img{width:100%;height:100%;object-fit:contain;display:block;}</style>"
        if let data = GIFCache.shared.data(for: urlString) {
            let b64 = data.base64EncodedString()
            let html = "<html><head><meta name='viewport' content='width=device-width, initial-scale=1.0'>\(css)</head><body><img src='data:image/gif;base64,\(b64)' /></body></html>"
            webView.loadHTMLString(html, baseURL: nil)
        } else if let url = URL(string: urlString) {
            let html = "<html><head><meta name='viewport' content='width=device-width, initial-scale=1.0'>\(css)</head><body><img src='\(url.absoluteString)' /></body></html>"
            webView.loadHTMLString(html, baseURL: url.deletingLastPathComponent())
            URLSession.shared.dataTask(with: url) { data, _, _ in
                guard let data else { return }
                GIFCache.shared.set(data, for: urlString)
            }.resume()
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }
    final class Coordinator { var loadedURL: String? }
}
