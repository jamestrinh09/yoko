//
//  LocksView.swift
//  Yoko
//

import SwiftUI
import FamilyControls

struct LocksView: View {
    @Environment(AppStore.self) private var store
    @Environment(ScreenTimeService.self) private var screenTime
    @State private var filter: LockType? = nil
    @State private var ruleEditLock: AppLock? = nil
    @State private var showAppPicker: Bool = false
    @State private var toast: String? = nil
    @State private var toastSeq: Int = 0

    /// The rule types a parent can choose between (Educational is collapsed into
    /// Reward Unlock, so it never appears as a separate option).
    private let selectableTypes: [LockType] = [.reward, .timed, .full]

    var filtered: [AppLock] {
        if let filter { return store.locks.filter { $0.type.normalized == filter } }
        return store.locks
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    header
                    screenTimeCard
                    schedulesCard
                    filterChips
                    lockList
                    Spacer(minLength: 110)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }
            .dsScreenBackground()
            .onAppear { screenTime.refreshStatus() }
            .familyActivityPicker(isPresented: $showAppPicker, selection: screenTimeSelectionBinding)
            .onChange(of: screenTime.selection) { _, _ in
                screenTime.applyShields()
            }
            .sheet(item: $ruleEditLock) { lock in
                SetUnlockRuleSheet(lock: lock) { type, rewardRule in
                    applyRule(to: lock, type: type, rewardRule: rewardRule)
                }
            }
            .overlay(alignment: .bottom) {
                if let toast {
                    LockToast(message: toast)
                        .padding(.bottom, 90)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }

    // MARK: - Rule editing

    private func applyRule(to lock: AppLock, type: LockType, rewardRule: String) {
        store.setLockRule(lock, type: type, rewardRule: rewardRule)
        presentToast(ruleToastMessage(name: lock.name, type: type, rewardRule: rewardRule))
    }

    private func ruleToastMessage(name: String, type: LockType, rewardRule: String) -> String {
        switch type.normalized {
        case .timed: return "\(name) set to Timed Lock"
        case .full: return "\(name) set to Full Lock"
        default: return "\(name) set to Reward Unlock · \(UnlockRuleOption.shortLabel(rewardRule))"
        }
    }

    private func presentToast(_ message: String) {
        toastSeq += 1
        let seq = toastSeq
        withAnimation(.spring(duration: 0.32)) { toast = message }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.6))
            if seq == toastSeq {
                withAnimation(.easeOut(duration: 0.3)) { toast = nil }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Locks")
                .font(.dsDisplay)
                .foregroundStyle(DS.Color.textPrimary)
            Text("Control which apps need to be earned")
                .font(.dsCallout)
                .foregroundStyle(DS.Color.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private var screenTimeSelectionBinding: Binding<FamilyActivitySelection> {
        Binding(
            get: { screenTime.selection },
            set: { screenTime.selection = $0 }
        )
    }

    @ViewBuilder
    private var screenTimeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                Image(systemName: "hourglass")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(DS.Color.accent)
                    .clipShape(.rect(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Apple Screen Time")
                        .font(.dsHeadline)
                        .foregroundStyle(DS.Color.textPrimary)
                    Text(screenTime.statusText)
                        .font(.dsCaption)
                        .foregroundStyle(screenTime.isAuthorized ? DS.Color.success : DS.Color.textSecondary)
                }
                Spacer()
                Image(systemName: screenTime.isAuthorized ? "checkmark.seal.fill" : "exclamationmark.circle")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(screenTime.isAuthorized ? DS.Color.success : DS.Color.textTertiary)
            }

            if screenTime.isAuthorized {
                Button {
                    showAppPicker = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "square.grid.2x2.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(DS.Color.accent)
                        Text(screenTime.selectedItemCount == 0
                             ? "Choose apps to lock"
                             : "\(screenTime.selectedItemCount) app\(screenTime.selectedItemCount == 1 ? "" : "s") & categories locked")
                            .font(.dsCallout)
                            .foregroundStyle(DS.Color.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(DS.Color.textTertiary)
                    }
                    .padding(14)
                    .background(DS.Color.background)
                    .clipShape(.rect(cornerRadius: DS.Radius.medium))
                }
                .buttonStyle(.plain)

                if screenTime.selectedItemCount > 0 {
                    Button(role: .destructive) {
                        withAnimation(.spring(duration: 0.3)) { screenTime.clearShields() }
                    } label: {
                        Text("Remove all locked apps")
                            .font(.dsCaption)
                            .foregroundStyle(DS.Color.danger)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Text("Connect Screen Time to choose real apps on this device to lock until learning is complete.")
                    .font(.dsCaption)
                    .foregroundStyle(DS.Color.textSecondary)
                Button {
                    Task {
                        await screenTime.requestAuthorization()
                        screenTime.applyShields()
                    }
                } label: {
                    Text(screenTime.isRequesting ? "Requesting…" : "Enable Screen Time")
                }
                .buttonStyle(DSPrimaryButtonStyle())
                .disabled(screenTime.isRequesting)

                if let error = screenTime.lastError {
                    Text(error)
                        .font(.dsTiny)
                        .foregroundStyle(DS.Color.danger)
                }
            }
        }
        .dsCard()
    }

    @ViewBuilder
    private var schedulesCard: some View {
        @Bindable var store = store
        VStack(spacing: 0) {
            scheduleRow(symbol: "moon.stars.fill", title: "Bedtime Lock", subtitle: "9:00 PM – 7:00 AM", isOn: $store.bedtimeLockEnabled)
            Divider().padding(.leading, 56)
            scheduleRow(symbol: "backpack.fill", title: "School Hours", subtitle: "8:00 AM – 3:00 PM, Mon–Fri", isOn: $store.schoolHoursLockEnabled)
        }
        .background(DS.Color.surface)
        .clipShape(.rect(cornerRadius: DS.Radius.large))
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.large).stroke(DS.Color.border, lineWidth: 1))
    }

    private func scheduleRow(symbol: String, title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(DS.Color.accent)
                .frame(width: 36, height: 36)
                .background(DS.Color.accentSoft)
                .clipShape(.rect(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.dsHeadline).foregroundStyle(DS.Color.textPrimary)
                Text(subtitle).font(.dsCaption).foregroundStyle(DS.Color.textSecondary)
            }
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(DS.Color.accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button("All") { filter = nil }
                    .buttonStyle(DSChipStyle(selected: filter == nil))
                ForEach(selectableTypes, id: \.self) { t in
                    Button(t.title) { filter = t }
                        .buttonStyle(DSChipStyle(selected: filter == t))
                }
            }
        }
        .contentMargins(.horizontal, 0)
    }

    private var lockList: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Apps")
            ForEach(filtered) { lock in
                LockRow(lock: lock) {
                    ruleEditLock = lock
                }
            }
        }
    }
}

struct LockRow: View {
    @Environment(AppStore.self) private var store
    let lock: AppLock
    /// Opens the "Set Unlock Rule" sheet for this app.
    let onEditRule: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(lock.iconColor.opacity(0.14))
                    .frame(width: 48, height: 48)
                Image(systemName: lock.symbol)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(lock.iconColor)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(lock.name).font(.dsHeadline).foregroundStyle(DS.Color.textPrimary)
                ruleTag
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Toggle("", isOn: Binding(
                    get: { lock.enabled },
                    set: { _ in store.toggleLock(lock) }
                ))
                .labelsHidden()
                .tint(DS.Color.accent)
                statusText
            }
        }
        .padding(14)
        .background(DS.Color.surface)
        .clipShape(.rect(cornerRadius: DS.Radius.medium))
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.medium).stroke(DS.Color.border, lineWidth: 1))
    }

    /// Tappable rule pill — the affordance to change this app's unlock rule.
    private var ruleTag: some View {
        Button(action: onEditRule) {
            HStack(spacing: 6) {
                Image(systemName: lock.type.normalized.symbol)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(DS.Color.accent)
                Text(lock.type.normalized.title)
                    .font(.dsCaption)
                    .foregroundStyle(DS.Color.textPrimary)
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(DS.Color.textTertiary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(DS.Color.accentSoft)
            .clipShape(.capsule)
        }
        .buttonStyle(.plain)
    }

    /// Full Lock has no unlock path, so a countdown would be misleading.
    @ViewBuilder
    private var statusText: some View {
        if lock.type.normalized == .full {
            Text("Always blocked")
                .font(.dsTiny)
                .foregroundStyle(DS.Color.textTertiary)
        } else {
            Text("\(lock.earnedMinutesAvailable)m left")
                .font(.dsTiny)
                .foregroundStyle(DS.Color.textTertiary)
        }
    }
}

// MARK: - Set Unlock Rule Sheet

/// Bottom sheet for changing a single app's unlock rule. Page one lets the parent
/// pick the rule type (Reward / Timed / Full); choosing Reward pushes forward to
/// the same three rule cards used in onboarding, with a back arrow to return.
struct SetUnlockRuleSheet: View {
    @Environment(\.dismiss) private var dismiss
    let lock: AppLock
    /// Called with the chosen type and, for reward locks, the unlock rule mode.
    let onConfirm: (LockType, String) -> Void

    @State private var selectedType: LockType
    @State private var rewardRule: String
    @State private var showRewardDetail: Bool = false

    init(lock: AppLock, onConfirm: @escaping (LockType, String) -> Void) {
        self.lock = lock
        self.onConfirm = onConfirm
        _selectedType = State(initialValue: lock.type.normalized)
        _rewardRule = State(initialValue: lock.rewardRule)
    }

    var body: some View {
        NavigationStack {
            typePage
                .navigationDestination(isPresented: $showRewardDetail) {
                    rewardDetailPage
                }
        }
        .tint(DS.Color.accent)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationContentInteraction(.scrolls)
    }

    // MARK: Page 1 — pick the rule type

    private var typePage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Set Unlock Rule")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(DS.Color.textPrimary)
                    Text("for \(lock.name)")
                        .font(.dsCallout)
                        .foregroundStyle(DS.Color.textSecondary)
                }
                .padding(.top, 12)

                VStack(spacing: 12) {
                    typeCard(.reward, icon: "🎁", subtitle: "Answer questions to earn access")
                    typeCard(.timed, icon: "⏱️", subtitle: "Allowed only during set hours")
                    typeCard(.full, icon: "🔒", subtitle: "Always blocked, no unlock path")
                }

                Button {
                    if selectedType == .reward {
                        showRewardDetail = true
                    } else {
                        confirm()
                    }
                } label: {
                    Text(selectedType == .reward ? "Next" : "Set Rule")
                }
                .buttonStyle(DSPrimaryButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .background(DS.Color.background)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Cancel") { dismiss() }
                    .foregroundStyle(DS.Color.textSecondary)
            }
        }
    }

    private func typeCard(_ type: LockType, icon: String, subtitle: String) -> some View {
        SelectableRow(
            icon: icon,
            title: type.title,
            subtitle: subtitle,
            titleFont: .system(size: 18, weight: .semibold, design: .rounded),
            subtitleFont: .system(size: 14, weight: .regular, design: .rounded),
            selected: selectedType == type
        ) {
            selectedType = type
        }
    }

    // MARK: Page 2 — reward unlock detail (reuses the onboarding cards)

    private var rewardDetailPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                MascotGIF(url: GIFAssets.lockStanding, size: 130)
                    .frame(maxWidth: .infinity)
                Text("Set the Unlock Rule")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(DS.Color.textPrimary)
                UnlockRuleCards(selection: $rewardRule)
                Button { confirm() } label: { Text("Set Rule") }
                    .buttonStyle(DSPrimaryButtonStyle())
                    .padding(.top, 4)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .background(DS.Color.background)
        .navigationTitle("Reward Unlock")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func confirm() {
        onConfirm(selectedType, rewardRule)
        dismiss()
    }
}

// MARK: - Toast

/// Brief confirmation pill shown after a rule change.
struct LockToast: View {
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(DS.Color.accent)
            Text(message)
                .font(.dsCaption)
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(DS.Color.textPrimary)
        .clipShape(.capsule)
        .shadow(color: .black.opacity(0.22), radius: 16, y: 8)
        .padding(.horizontal, 24)
    }
}
