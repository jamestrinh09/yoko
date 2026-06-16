//
//  StreakCelebrationView.swift
//  Yoko
//
//  Shown after a lesson is completed. Celebrates the child's learning streak on
//  a warm orange gradient with a mascot GIF inside a floating streak card.
//

import SwiftUI
import WebKit

struct StreakCelebrationView: View {
    let streak: Int
    let childName: String
    let onContinue: () -> Void

    @State private var appear: Bool = false
    @State private var flameScale: CGFloat = 0.4

    private let mascotURL = "https://pyikafpvphzqdadjvktz.supabase.co/storage/v1/object/public/Yoko/ExcitedGIF.gif"

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
            StreakMascotGIFView(urlString: mascotURL)
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

// MARK: - Mascot GIF (transparent WebKit-backed)

private struct StreakMascotGIFView: UIViewRepresentable {
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
