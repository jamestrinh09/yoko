//
//  PaywallView.swift
//  Yoko
//
//  Three-step subscription paywall shown at the end of onboarding (right after
//  the pre-paywall hype screen). `PaywallFlowView` is the container — it owns the
//  current step and slides horizontally between them, matching the spring style
//  used in OnboardingView. RevenueCat drives the pricing and purchase flow.
//

import SwiftUI
import RevenueCat

/// Which plan is highlighted on the Step 3 selector.
private enum PaywallPlan { case annual, monthly }

// MARK: - Flow container

struct PaywallFlowView: View {
    let childName: String
    /// Shared subscription state (created in YokoApp, passed in explicitly so the
    /// flow doesn't depend on environment inheritance through the cover).
    var store: StoreViewModel
    /// Fires once the user successfully subscribes or restores — the caller
    /// dismisses the paywall and continues onboarding.
    let onComplete: () -> Void

    @State private var currentStep: Int = 0
    @State private var slideForward: Bool = true
    @State private var selectedPlan: PaywallPlan = .annual

    var body: some View {
        ZStack {
            warmBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                stepContent
            }
        }
        .preferredColorScheme(.light)
        .tint(DS.Color.accent)
        .task { if !store.hasPackages { await store.loadOfferings() } }
        .alert(
            "Hmm, that didn't work",
            isPresented: Binding(
                get: { store.errorMessage != nil },
                set: { if !$0 { store.errorMessage = nil } }
            )
        ) {
            Button("Try again") {
                store.errorMessage = nil
                // If prices never loaded, retry the fetch so the user isn't stuck.
                if !store.hasPackages { Task { await store.loadOfferings() } }
            }
        } message: {
            Text(store.errorMessage ?? "Please try again.")
        }
    }

    // MARK: Background

    /// Warm cream → light-orange wash for Steps 1 & 2; Step 3 keeps it but adds a
    /// clean surface behind the conversion content.
    private var warmBackground: some View {
        LinearGradient(
            colors: [
                DS.Color.background,
                DS.Color.accentSoft,
                Color(red: 1.0, green: 0.92, blue: 0.82)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: Top bar (back caret on Steps 2 & 3)

    private var topBar: some View {
        HStack {
            if currentStep > 0 {
                Button(action: back) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(DS.Color.textPrimary)
                        .frame(width: 44, height: 44)
                        .background(.white.opacity(0.6), in: Circle())
                }
                .buttonStyle(.plain)
                .transition(.opacity)
            } else {
                Color.clear.frame(width: 44, height: 44)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: Step switcher with horizontal slide

    @ViewBuilder
    private var stepContent: some View {
        ZStack {
            switch currentStep {
            case 0:
                PaywallTrialIntroStep(childName: displayName, onContinue: advance)
                    .transition(slide)
            case 1:
                PaywallReminderStep(onContinue: advance)
                    .transition(slide)
            default:
                PaywallPlanStep(
                    store: store,
                    selectedPlan: $selectedPlan,
                    onPurchase: purchaseSelected,
                    onRestore: restore
                )
                .transition(slide)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var slide: AnyTransition {
        .asymmetric(
            insertion: .move(edge: slideForward ? .trailing : .leading).combined(with: .opacity),
            removal: .move(edge: slideForward ? .leading : .trailing).combined(with: .opacity)
        )
    }

    // MARK: Navigation

    private var displayName: String {
        let trimmed = childName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "your child" : trimmed
    }

    private func advance() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        slideForward = true
        withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
            currentStep = min(currentStep + 1, 2)
        }
    }

    private func back() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        slideForward = false
        withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
            currentStep = max(currentStep - 1, 0)
        }
    }

    private func purchaseSelected() {
        guard let package = selectedPlan == .annual ? store.annualPackage : store.monthlyPackage else {
            Task { await store.loadOfferings() }
            return
        }
        Task {
            let success = await store.purchase(package)
            if success {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                onComplete()
            }
        }
    }

    private func restore() {
        Task {
            let success = await store.restore()
            if success { onComplete() }
        }
    }
}

// MARK: - Step 1: Trial intro

private struct PaywallTrialIntroStep: View {
    let childName: String
    let onContinue: () -> Void
    @State private var bob = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    Text("I'd love for \(childName) to enjoy Yoko")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundStyle(DS.Color.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .padding(.top, 12)

                    Text("7 days free")
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .foregroundStyle(DS.Color.success)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .background(DS.Color.success.opacity(0.12), in: Capsule())

                    // Custom Step 1 mascot: Yoko hugging a heart.
                    Image("PaywallHeartHero")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 280)
                        .offset(y: bob ? -6 : 6)
                        .shadow(color: .black.opacity(0.08), radius: 16, y: 10)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 28)
            }

            PaywallBottomBar(
                trustText: "No payment due now",
                ctaTitle: "Try for $0.00",
                isLoading: false,
                onTap: onContinue
            )
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) { bob = true }
        }
    }
}

// MARK: - Step 2: Reminder

private struct PaywallReminderStep: View {
    let onContinue: () -> Void
    @State private var swing = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    Text("We'll send you a reminder before your free trial ends")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundStyle(DS.Color.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .padding(.top, 18)

                    // Custom Step 2 mascot: Yoko ringing a bell (10% larger).
                    Image("PaywallBellHero")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 330)
                        .rotationEffect(.degrees(swing ? 3 : -3), anchor: .top)
                        .shadow(color: .black.opacity(0.08), radius: 16, y: 10)
                }
                .padding(.horizontal, 28)
            }

            PaywallBottomBar(
                trustText: "No payment due now",
                ctaTitle: "Try for $0.00",
                isLoading: false,
                onTap: onContinue
            )
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) { swing = true }
        }
    }
}

// MARK: - Step 3: Plan selection

private struct PaywallPlanStep: View {
    var store: StoreViewModel
    @Binding var selectedPlan: PaywallPlan
    let onPurchase: () -> Void
    let onRestore: () -> Void

    // Apple's standard EULA satisfies the Terms requirement; swap the privacy URL
    // for Yoko's hosted policy when available.
    private let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    private let privacyURL = URL(string: "https://rork.app/privacy")!

    private var trialActive: Bool { store.annualTrialEligible }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    Text(headline)
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundStyle(DS.Color.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .padding(.top, 4)

                    timeline

                    if store.hasPackages {
                        planCards
                    } else {
                        loadingPlans
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
            }

            bottomBar
        }
    }

    private var headline: String {
        trialActive ? "Start your 7-day FREE trial to continue" : "Subscribe to continue"
    }

    // MARK: Timeline

    private var timeline: some View {
        VStack(spacing: 0) {
            timelineRow(
                icon: "lock.open.fill",
                title: "Today – Full access",
                subtitle: "Get free content for a week",
                isLast: false
            )
            timelineRow(
                icon: "bell.fill",
                title: "In 5 days – Reminder",
                subtitle: "We'll remind you before it ends",
                isLast: false
            )
            timelineRow(
                icon: "star.fill",
                title: "In 7 days – Trial ends",
                subtitle: "You'll be charged \(store.annualPriceString) on \(chargeDateString). Cancel anytime",
                isLast: true
            )
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.large))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.large).stroke(DS.Color.border, lineWidth: 1)
        )
    }

    private func timelineRow(icon: String, title: String, subtitle: String, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 4) {
                ZStack {
                    Circle().fill(DS.Color.accentSoft).frame(width: 38, height: 38)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(DS.Color.accent)
                }
                if !isLast {
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(DS.Color.accentMid)
                        .frame(width: 3)
                        .frame(maxHeight: .infinity)
                }
            }
            .fixedSize(horizontal: true, vertical: false)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(DS.Color.textPrimary)
                Text(subtitle)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(DS.Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.bottom, isLast ? 0 : 18)

            Spacer(minLength: 0)
        }
    }

    private var chargeDateString: String {
        let date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: date)
    }

    // MARK: Plan cards

    private var planCards: some View {
        HStack(spacing: 12) {
            planCard(
                plan: .annual,
                duration: "1 Year",
                price: "\(store.annualPriceString)/year",
                badge: trialActive ? "FREE TRIAL" : nil,
                saveTag: "SAVE \(store.annualSavingsPercent)%"
            )
            planCard(
                plan: .monthly,
                duration: "1 Month",
                price: "\(store.monthlyPriceString)/month",
                badge: nil,
                saveTag: nil
            )
        }
        .padding(.top, 4)
    }

    private func planCard(plan: PaywallPlan, duration: String, price: String, badge: String?, saveTag: String?) -> some View {
        let selected = selectedPlan == plan
        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { selectedPlan = plan }
        } label: {
            VStack(spacing: 6) {
                Text(duration)
                    .font(.system(size: 19, weight: .heavy, design: .rounded))
                    .foregroundStyle(DS.Color.textPrimary)
                Text(price)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(DS.Color.textSecondary)
                    .multilineTextAlignment(.center)
                if let saveTag {
                    Text(saveTag)
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(DS.Color.success, in: Capsule())
                        .padding(.top, 2)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 118)
            .padding(.vertical, 18)
            .background(selected ? DS.Color.accentSoft : DS.Color.surface, in: RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(selected ? DS.Color.accent : DS.Color.border, lineWidth: selected ? 2.5 : 1)
            )
            .overlay(alignment: .top) {
                if let badge {
                    Text(badge)
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(DS.Color.accent, in: Capsule())
                        .offset(y: -11)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var loadingPlans: some View {
        VStack(spacing: 12) {
            ProgressView().tint(DS.Color.accent)
            Text("Loading plans…")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(DS.Color.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 132)
    }

    // MARK: Bottom bar (dynamic by plan)

    private var bottomBar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 7) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(DS.Color.success)
                Text(trustText)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(DS.Color.textSecondary)
            }

            PaywallCTAButton(title: ctaTitle, isLoading: store.isPurchasing, onTap: onPurchase)
                .disabled(!store.hasPackages || store.isPurchasing)
                .opacity(store.hasPackages ? 1 : 0.6)

            Text(finePrint)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(DS.Color.textTertiary)
                .multilineTextAlignment(.center)

            footerLinks
                .padding(.top, 2)
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 18)
        .background(.ultraThinMaterial)
    }

    private var footerLinks: some View {
        HStack(spacing: 18) {
            Link("Terms", destination: termsURL)
            dividerDot
            Link("Privacy", destination: privacyURL)
            dividerDot
            Button("Restore", action: onRestore)
        }
        .font(.system(size: 12, weight: .semibold, design: .rounded))
        .foregroundStyle(DS.Color.textTertiary)
    }

    private var dividerDot: some View {
        Circle().fill(DS.Color.textTertiary).frame(width: 3, height: 3)
    }

    // MARK: Dynamic copy

    private var ctaTitle: String {
        switch selectedPlan {
        case .annual:
            return trialActive ? "Try for $0.00" : "Subscribe — \(store.annualPriceString)/year"
        case .monthly:
            return "Subscribe — \(store.monthlyPriceString)/month"
        }
    }

    private var trustText: String {
        switch selectedPlan {
        case .annual:
            return trialActive ? "No payment due now" : "You'll be charged \(store.annualPriceString) today"
        case .monthly:
            return "You'll be charged \(store.monthlyPriceString) today"
        }
    }

    private var finePrint: String {
        switch selectedPlan {
        case .annual:
            return trialActive
                ? "7 days free, then \(store.annualPriceString) per year"
                : "\(store.annualPriceString) billed yearly, cancel anytime"
        case .monthly:
            return "\(store.monthlyPriceString) billed monthly, cancel anytime"
        }
    }
}

// MARK: - Shared bottom bar (Steps 1 & 2)

private struct PaywallBottomBar: View {
    let trustText: String
    let ctaTitle: String
    let isLoading: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 7) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(DS.Color.success)
                Text(trustText)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(DS.Color.textSecondary)
            }
            PaywallCTAButton(title: ctaTitle, isLoading: isLoading, onTap: onTap)
        }
        .padding(.horizontal, 24)
        .padding(.top, 10)
        .padding(.bottom, 20)
    }
}

// MARK: - CTA button (Lesson Complete "Done" button shadow style)

private struct PaywallCTAButton: View {
    let title: String
    let isLoading: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                Text(title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .opacity(isLoading ? 0 : 1)
                if isLoading {
                    ProgressView().tint(.white)
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(DS.Color.accent)
            .clipShape(.rect(cornerRadius: 20))
            .shadow(color: DS.Color.accent.opacity(0.35), radius: 16, y: 8)
        }
        .buttonStyle(.plain)
        .scaleEffect(isLoading ? 0.99 : 1)
        .animation(.spring(duration: 0.25), value: isLoading)
    }
}
