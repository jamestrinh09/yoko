//
//  ScreenTimeService.swift
//  Yoko
//
//  Wraps Apple's Screen Time stack (FamilyControls + ManagedSettings) behind a
//  small, observable boundary so the UI can drive authorization, app selection,
//  and shielding without touching the frameworks directly.
//
//  NOTE: Real OS-level app blocking requires the `com.apple.developer.family-controls`
//  entitlement in the signed provisioning profile. On the simulator and on builds
//  without an approved entitlement, authorization will not succeed — the UI degrades
//  gracefully and surfaces the status instead of blocking the user.
//

import SwiftUI
import Observation
import FamilyControls
import ManagedSettings

@Observable
final class ScreenTimeService {
    /// Current Family Controls authorization status.
    var authorizationStatus: AuthorizationStatus = .notDetermined
    /// Apps / categories / web domains the parent has chosen to lock.
    var selection = FamilyActivitySelection() {
        didSet { persistSelection() }
    }
    /// True while an authorization request is in flight.
    var isRequesting: Bool = false
    /// User-friendly description of the last authorization failure, if any.
    var lastError: String?

    private let store = ManagedSettingsStore()
    private let selectionKey = "learnlock.screentime.selection"

    init() {
        authorizationStatus = AuthorizationCenter.shared.authorizationStatus
        loadSelection()
    }

    // MARK: - Derived

    var isAuthorized: Bool { authorizationStatus == .approved }

    /// Number of distinct things currently selected to lock.
    var selectedItemCount: Int {
        selection.applicationTokens.count
            + selection.categoryTokens.count
            + selection.webDomainTokens.count
    }

    var statusText: String {
        switch authorizationStatus {
        case .approved: return "Connected"
        case .denied: return "Access denied"
        case .notDetermined: return "Not set up"
        default: return "Unknown"
        }
    }

    // MARK: - Authorization

    /// Requests Screen Time authorization for the individual using the device.
    /// Safe to call repeatedly; once approved it returns immediately.
    func requestAuthorization() async {
        isRequesting = true
        defer { isRequesting = false }
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            authorizationStatus = AuthorizationCenter.shared.authorizationStatus
            lastError = nil
        } catch {
            authorizationStatus = AuthorizationCenter.shared.authorizationStatus
            lastError = error.localizedDescription
        }
    }

    /// Re-reads the latest authorization status (e.g. on view appear).
    func refreshStatus() {
        authorizationStatus = AuthorizationCenter.shared.authorizationStatus
    }

    // MARK: - Shielding

    /// Applies shields for the current selection. Takes effect immediately and
    /// persists across launches until cleared.
    func applyShields() {
        guard isAuthorized else { return }
        let apps = selection.applicationTokens
        let categories = selection.categoryTokens
        let domains = selection.webDomainTokens

        store.shield.applications = apps.isEmpty ? nil : apps
        store.shield.applicationCategories = categories.isEmpty
            ? nil
            : .specific(categories)
        store.shield.webDomains = domains.isEmpty ? nil : domains
    }

    /// Removes all shields and clears the local selection.
    func clearShields() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        selection = FamilyActivitySelection()
    }

    // MARK: - Persistence

    private func persistSelection() {
        guard let data = try? JSONEncoder().encode(selection) else { return }
        UserDefaults.standard.set(data, forKey: selectionKey)
    }

    private func loadSelection() {
        guard let data = UserDefaults.standard.data(forKey: selectionKey),
              let decoded = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
        else { return }
        selection = decoded
    }
}
