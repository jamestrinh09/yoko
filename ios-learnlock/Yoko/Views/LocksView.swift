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
    @State private var showAppPicker: Bool = false
    @State private var toast: String? = nil
    @State private var toastSeq: Int = 0

    // Rule editing sheet (single app, multi-select, and post-picker bulk all share it).
    @State private var ruleSheet: RuleSheetContext? = nil

    // Multi-select bulk-apply state.
    @State private var selectionMode: Bool = false
    @State private var selectedAppIds: Set<UUID> = []

    // Post-picker bulk-apply detection.
    @State private var pickerBaselineCount: Int = 0

    // MARK: - Parent passcode gate
    //
    // Every lock-changing action routes through `requireParentPasscode`. Once a
    // correct passcode is entered, the whole Locks tab unlocks for the current
    // visit (`locksUnlocked`). Because RootTabView swaps tabs via a `switch`,
    // LocksView is destroyed when you leave the tab, so `locksUnlocked` resets to
    // false automatically on the next visit (and after backgrounding).
    //
    // The EIGHT gated entry points (keep this list in sync — see GateChecklist):
    //   1. Tap a single app's rule tag           → LockRow onEditRule
    //   2. Confirm a rule ("Set Rule")           → RuleSheetContext.apply
    //   3. Post-picker bulk-apply prompt         → presentBulkPickerRule
    //   4. Multi-select "Apply Rule"             → applyRuleToSelected
    //   5. Toggle an app's on/off master switch  → LockRow onToggleEnabled
    //   6. Toggle Bedtime / School Hours         → scheduleRow onToggle
    //   7. Remove all locked apps                → clearShields button
    //   8. Open the app/category picker          → openAppPicker
    @State private var locksUnlocked: Bool = false
    @State private var showPasscodeEntry: Bool = false
    @State private var pendingGatedAction: (() -> Void)? = nil

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
            .onAppear {
                screenTime.refreshStatus()
                // Re-lock on each visit to the Locks tab.
                locksUnlocked = false
            }
            .familyActivityPicker(isPresented: $showAppPicker, selection: screenTimeSelectionBinding)
            .onChange(of: screenTime.selection) { _, _ in
                screenTime.applyShields()
            }
            .onChange(of: showAppPicker) { wasShown, isShown in
                // Picker just closed: if new apps were added, offer to bulk-apply a rule.
                if wasShown && !isShown && screenTime.selectedItemCount > pickerBaselineCount {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                        presentBulkPickerRule()
                    }
                }
            }
            .sheet(item: $ruleSheet) { ctx in
                SetUnlockRuleSheet(context: ctx)
            }
            .sheet(isPresented: $showPasscodeEntry, onDismiss: runPendingGatedAction) {
                ParentPasscodeSheet(
                    mode: .verify,
                    existing: store.parentPasscode,
                    onSuccess: { _ in locksUnlocked = true },
                    onCancel: { pendingGatedAction = nil }
                )
            }
            .overlay(alignment: .bottom) { bottomBars }
        }
    }

    // MARK: - Passcode gate

    /// Runs `action` immediately when the gate is open (passcode disabled, unset,
    /// or already unlocked this visit); otherwise presents the passcode prompt and
    /// only runs `action` after a correct entry.
    private func requireParentPasscode(_ action: @escaping () -> Void) {
        guard store.passcodeGateActive, !locksUnlocked else {
            action()
            return
        }
        pendingGatedAction = action
        showPasscodeEntry = true
    }

    /// Called after the passcode sheet dismisses. Runs the pending action only if
    /// the parent unlocked successfully; otherwise the action is silently dropped.
    private func runPendingGatedAction() {
        let action = pendingGatedAction
        pendingGatedAction = nil
        if locksUnlocked { action?() }
    }

    // MARK: - Rule editing

    private func presentSingleRule(for lock: AppLock) {
        requireParentPasscode {
            ruleSheet = RuleSheetContext(
                headerTitle: "Set Unlock Rule",
                headerSubtitle: "for \(lock.name)",
                initialType: lock.type.normalized,
                initialRule: lock.rewardRule,
                showSkip: false,
                apply: { type, rule in
                    store.setLockRule(lock, type: type, rewardRule: rule)
                    presentToast(ruleToastMessage(name: lock.name, type: type, rewardRule: rule))
                }
            )
        }
    }

    private func applyRuleToSelected() {
        let ids = selectedAppIds
        guard !ids.isEmpty else { return }
        requireParentPasscode {
            ruleSheet = RuleSheetContext(
                headerTitle: "Apply Rule",
                headerSubtitle: "to \(ids.count) selected app\(ids.count == 1 ? "" : "s")",
                initialType: .reward,
                initialRule: "session",
                showSkip: false,
                apply: { type, rule in
                    store.setLockRule(forIds: ids, type: type, rewardRule: rule)
                    presentToast(bulkToastMessage(count: ids.count, type: type, rewardRule: rule))
                    withAnimation(.spring(duration: 0.3)) {
                        selectionMode = false
                        selectedAppIds.removeAll()
                    }
                }
            )
        }
    }

    /// Part 1 — after the Screen Time picker adds new apps, offer to apply one rule
    /// to all of them. Skipping leaves everything as-is.
    private func presentBulkPickerRule() {
        let count = screenTime.selectedItemCount
        requireParentPasscode {
            ruleSheet = RuleSheetContext(
                headerTitle: "Apply a Rule",
                headerSubtitle: "to all \(count) selected app\(count == 1 ? "" : "s")",
                initialType: .reward,
                initialRule: "session",
                showSkip: true,
                skipRewardDetail: true,
                apply: { type, rule in
                    store.setLockRuleForAll(type: type, rewardRule: rule)
                    presentToast(bulkToastMessage(count: store.locks.count, type: type, rewardRule: rule))
                }
            )
        }
    }

    private func openAppPicker() {
        requireParentPasscode {
            pickerBaselineCount = screenTime.selectedItemCount
            showAppPicker = true
        }
    }

    private func ruleToastMessage(name: String, type: LockType, rewardRule: String) -> String {
        switch type.normalized {
        case .timed: return "\(name) set to Timed Lock"
        case .full: return "\(name) set to Full Lock"
        default: return "\(name) set to Reward Unlock · \(UnlockRuleOption.shortLabel(rewardRule))"
        }
    }

    private func bulkToastMessage(count: Int, type: LockType, rewardRule: String) -> String {
        let suffix = count == 1 ? "app" : "apps"
        switch type.normalized {
        case .timed: return "\(count) \(suffix) set to Timed Lock"
        case .full: return "\(count) \(suffix) set to Full Lock"
        default: return "\(count) \(suffix) set to Reward Unlock · \(UnlockRuleOption.shortLabel(rewardRule))"
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

    // MARK: - Bottom overlays (toast + multi-select action bar)

    @ViewBuilder
    private var bottomBars: some View {
        VStack(spacing: 10) {
            if let toast {
                LockToast(message: toast)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            if selectionMode && !selectedAppIds.isEmpty {
                bulkActionBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.bottom, 96)
    }

    private var bulkActionBar: some View {
        Button(action: applyRuleToSelected) {
            HStack(spacing: 10) {
                Text("\(selectedAppIds.count) selected")
                    .font(.dsHeadline)
                    .foregroundStyle(.white)
                Spacer()
                Text("Apply Rule")
                    .font(.dsHeadline)
                    .foregroundStyle(.white)
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(DS.Color.accent)
            .clipShape(.rect(cornerRadius: DS.Radius.large))
            .shadow(color: DS.Color.accent.opacity(0.4), radius: 16, y: 8)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 24)
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
                    openAppPicker()
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
                        requireParentPasscode {
                            withAnimation(.spring(duration: 0.3)) { screenTime.clearShields() }
                        }
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
        VStack(spacing: 0) {
            scheduleRow(symbol: "moon.stars.fill", title: "Bedtime Lock", subtitle: "9:00 PM – 7:00 AM", isOn: store.bedtimeLockEnabled) {
                requireParentPasscode { store.bedtimeLockEnabled.toggle() }
            }
            Divider().padding(.leading, 56)
            scheduleRow(symbol: "backpack.fill", title: "School Hours", subtitle: "8:00 AM – 3:00 PM, Mon–Fri", isOn: store.schoolHoursLockEnabled) {
                requireParentPasscode { store.schoolHoursLockEnabled.toggle() }
            }
        }
        .background(DS.Color.surface)
        .clipShape(.rect(cornerRadius: DS.Radius.large))
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.large).stroke(DS.Color.border, lineWidth: 1))
    }

    private func scheduleRow(symbol: String, title: String, subtitle: String, isOn: Bool, onToggle: @escaping () -> Void) -> some View {
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
            Toggle("", isOn: Binding(get: { isOn }, set: { _ in onToggle() }))
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
            HStack {
                SectionHeader(title: "Apps")
                Spacer()
                Button(selectionMode ? "Done" : "Select") {
                    withAnimation(.spring(duration: 0.3)) {
                        selectionMode.toggle()
                        if !selectionMode { selectedAppIds.removeAll() }
                    }
                }
                .font(.dsHeadline)
                .foregroundStyle(DS.Color.accent)
            }
            ForEach(filtered) { lock in
                LockRow(
                    lock: lock,
                    selectionMode: selectionMode,
                    isSelected: selectedAppIds.contains(lock.id),
                    onEditRule: { presentSingleRule(for: lock) },
                    onToggleEnabled: { requireParentPasscode { store.toggleLock(lock) } },
                    onToggleSelect: { toggleSelect(lock) }
                )
            }
        }
    }

    private func toggleSelect(_ lock: AppLock) {
        withAnimation(.spring(duration: 0.25)) {
            if selectedAppIds.contains(lock.id) {
                selectedAppIds.remove(lock.id)
            } else {
                selectedAppIds.insert(lock.id)
            }
        }
    }
}

struct LockRow: View {
    let lock: AppLock
    let selectionMode: Bool
    let isSelected: Bool
    /// Opens the "Set Unlock Rule" sheet for this app.
    let onEditRule: () -> Void
    /// Flips the app's on/off master switch.
    let onToggleEnabled: () -> Void
    /// Toggles this app's checkbox while in multi-select mode.
    let onToggleSelect: () -> Void

    var body: some View {
        rowContent
            .padding(14)
            .background(DS.Color.surface)
            .clipShape(.rect(cornerRadius: DS.Radius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.medium)
                    .stroke(isSelected ? DS.Color.accent : DS.Color.border, lineWidth: isSelected ? 2 : 1)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                if selectionMode { onToggleSelect() }
            }
    }

    private var rowContent: some View {
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
            if selectionMode {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(isSelected ? DS.Color.accent : DS.Color.textTertiary)
            } else {
                VStack(alignment: .trailing, spacing: 6) {
                    Toggle("", isOn: Binding(
                        get: { lock.enabled },
                        set: { _ in onToggleEnabled() }
                    ))
                    .labelsHidden()
                    .tint(DS.Color.accent)
                    statusText
                }
            }
        }
    }

    /// Tappable rule pill — the affordance to change this app's unlock rule.
    /// Disabled during multi-select so the row tap toggles the checkbox instead.
    private var ruleTag: some View {
        Button(action: onEditRule) {
            HStack(spacing: 6) {
                Image(systemName: lock.type.normalized.symbol)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(DS.Color.accent)
                Text(lock.type.normalized.title)
                    .font(.dsCaption)
                    .foregroundStyle(DS.Color.textPrimary)
                if !selectionMode {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(DS.Color.textTertiary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(DS.Color.accentSoft)
            .clipShape(.capsule)
        }
        .buttonStyle(.plain)
        .disabled(selectionMode)
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

/// Context describing one invocation of the rule-picker sheet. Reused for the
/// single-app, multi-select, and post-picker bulk flows.
struct RuleSheetContext: Identifiable {
    let id = UUID()
    let headerTitle: String
    let headerSubtitle: String
    let initialType: LockType
    let initialRule: String
    /// When true, shows a "Skip — I'll set these individually" option.
    let showSkip: Bool
    /// When true, choosing Reward Unlock confirms immediately instead of pushing
    /// the second "Reward Unlock" detail page (used by the post-picker prompt).
    var skipRewardDetail: Bool = false
    /// Applies the chosen rule. Called on confirm; never on skip/cancel.
    let apply: (LockType, String) -> Void
}

/// Bottom sheet for choosing an unlock rule. Page one picks the rule type
/// (Reward / Timed / Full); choosing Reward pushes forward to the same three
/// rule cards used in onboarding, with a back arrow to return.
struct SetUnlockRuleSheet: View {
    @Environment(\.dismiss) private var dismiss
    let context: RuleSheetContext

    @State private var selectedType: LockType
    @State private var rewardRule: String
    @State private var showRewardDetail: Bool = false

    init(context: RuleSheetContext) {
        self.context = context
        _selectedType = State(initialValue: context.initialType.normalized)
        _rewardRule = State(initialValue: context.initialRule)
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
                    Text(context.headerTitle)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(DS.Color.textPrimary)
                    Text(context.headerSubtitle)
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
                    if selectedType == .reward && !context.skipRewardDetail {
                        showRewardDetail = true
                    } else {
                        confirm()
                    }
                } label: {
                    Text(selectedType == .reward && !context.skipRewardDetail ? "Next" : "Set Rule")
                }
                .buttonStyle(DSPrimaryButtonStyle())

                if context.showSkip {
                    Button("Skip — I'll set these individually") { dismiss() }
                        .font(.dsCallout)
                        .foregroundStyle(DS.Color.textSecondary)
                        .frame(maxWidth: .infinity)
                }
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
        context.apply(selectedType, rewardRule)
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
