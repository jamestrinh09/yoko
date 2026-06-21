//
//  StoreViewModel.swift
//  Yoko
//
//  RevenueCat-backed subscription state. A single shared instance is created in
//  YokoApp and injected through the environment, so the paywall today (and any
//  premium gating later) reads the same source of truth.
//

import Foundation
import Observation
import RevenueCat
import UserNotifications

@Observable
@MainActor
final class StoreViewModel {
    /// Package identifiers configured in the RevenueCat "default" offering.
    static let annualIdentifier = "yoko_annual_trial"
    static let monthlyIdentifier = "yoko_monthly"
    /// Entitlement that grants full access.
    static let entitlementId = "premium"

    /// Fetched offerings (nil until the first load completes).
    private(set) var offerings: Offerings?
    /// True once the `premium` entitlement is active.
    private(set) var isPremium: Bool = false
    /// True while offerings are loading (drives the Step 3 loading state).
    private(set) var isLoadingOfferings: Bool = false
    /// True while a purchase / restore call is in flight (drives the CTA spinner).
    private(set) var isPurchasing: Bool = false
    /// Set when a non-cancellation error occurs; drives the retry alert.
    var errorMessage: String?

    /// Whether the user can still redeem the annual free trial. Defaults to true
    /// so the trial framing shows unless RevenueCat is certain the user already
    /// used a trial (`.ineligible`).
    private(set) var annualTrialEligible: Bool = true

    init() {
        Task { await listenForUpdates() }
        Task { await loadOfferings() }
    }

    // MARK: - Derived

    /// The "default" offering, falling back to whatever is marked current.
    var offering: Offering? {
        offerings?.offering(identifier: "default") ?? offerings?.current
    }

    var annualPackage: Package? { offering?.package(identifier: Self.annualIdentifier) }
    var monthlyPackage: Package? { offering?.package(identifier: Self.monthlyIdentifier) }

    /// True once both plan packages are available to display.
    var hasPackages: Bool { annualPackage != nil && monthlyPackage != nil }

    var annualPriceString: String { annualPackage?.storeProduct.localizedPriceString ?? "$29.99" }
    var monthlyPriceString: String { monthlyPackage?.storeProduct.localizedPriceString ?? "$4.99" }

    /// Percentage saved by choosing annual over twelve monthly charges. Computed
    /// from live prices so it localizes; falls back to 50% before prices load.
    var annualSavingsPercent: Int {
        guard
            let annual = annualPackage?.storeProduct.price,
            let monthly = monthlyPackage?.storeProduct.price
        else { return 50 }
        let annualValue = NSDecimalNumber(decimal: annual).doubleValue
        let monthlyYear = NSDecimalNumber(decimal: monthly).doubleValue * 12
        guard monthlyYear > 0, annualValue > 0, annualValue < monthlyYear else { return 50 }
        return Int(((1 - annualValue / monthlyYear) * 100).rounded())
    }

    // MARK: - Loading

    private func listenForUpdates() async {
        guard Purchases.isConfigured else { return }
        for await info in Purchases.shared.customerInfoStream {
            isPremium = info.entitlements[Self.entitlementId]?.isActive == true
        }
    }

    func loadOfferings() async {
        guard Purchases.isConfigured, !isLoadingOfferings else { return }
        isLoadingOfferings = true
        defer { isLoadingOfferings = false }
        do {
            offerings = try await Purchases.shared.offerings()
            await refreshTrialEligibility()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Only flips the trial framing off when RevenueCat is certain the user is
    /// ineligible (already redeemed a trial). Unknown / no-offer keep the trial
    /// framing, matching the Step 3 design intent.
    private func refreshTrialEligibility() async {
        guard Purchases.isConfigured, let product = annualPackage?.storeProduct else { return }
        let status = await Purchases.shared.checkTrialOrIntroDiscountEligibility(product: product)
        annualTrialEligible = (status != .ineligible)
    }

    // MARK: - Purchasing

    /// Attempts a purchase. Returns true only when the premium entitlement is
    /// active afterwards. Cancellation returns false with no error surfaced.
    func purchase(_ package: Package) async -> Bool {
        guard Purchases.isConfigured, !isPurchasing else { return false }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let result = try await Purchases.shared.purchase(package: package)
            if result.userCancelled { return false }

            var active = result.customerInfo.entitlements[Self.entitlementId]?.isActive == true
            let startedTrial = result.customerInfo.entitlements[Self.entitlementId]?.periodType == .trial

            // Entitlement validation can lag a beat right after a fresh purchase
            // (especially trial/sandbox purchases) — re-check once before giving up.
            if !active {
                if let refreshed = try? await Purchases.shared.customerInfo() {
                    active = refreshed.entitlements[Self.entitlementId]?.isActive == true
                }
            }
            isPremium = active

            if startedTrial {
                scheduleTrialReminder()
            }

            // A clean (non-cancelled, non-error) purchase result means the
            // transaction succeeded with Apple — treat it as success so onboarding
            // isn't blocked by entitlement-flag lag. `isPremium` will self-correct
            // moments later via the customerInfoStream listener if needed.
            return true
        } catch ErrorCode.purchaseCancelledError {
            return false
        } catch ErrorCode.paymentPendingError {
            return false
        } catch {
            errorMessage = "Something went wrong. Please try again."
            return false
        }
    }

    /// Schedules a local reminder 5 days after a free trial starts, so the
    /// 7-day annual trial timeline ("In 5 days – Reminder") shown on the paywall
    /// is backed by an actual notification, firing 2 days before the charge.
    private func scheduleTrialReminder() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "Your free trial ends in 2 days"
            content.body = "Open Yoko to manage your subscription before you're charged."
            content.sound = .default
            let request = UNNotificationRequest(
                identifier: "trial_reminder",
                content: content,
                trigger: UNTimeIntervalNotificationTrigger(timeInterval: 5 * 24 * 60 * 60, repeats: false)
            )
            center.add(request)
        }
    }

    /// Restores prior purchases (App Store review requirement).
    func restore() async -> Bool {
        guard Purchases.isConfigured, !isPurchasing else { return false }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let info = try await Purchases.shared.restorePurchases()
            isPremium = info.entitlements[Self.entitlementId]?.isActive == true
            return isPremium
        } catch {
            errorMessage = "We couldn't restore your purchases. Please try again."
            return false
        }
    }
}
