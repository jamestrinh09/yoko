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
    @State private var selectedLock: AppLock? = nil
    @State private var showAppPicker: Bool = false

    var filtered: [AppLock] {
        if let filter { return store.locks.filter { $0.type == filter } }
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
            .sheet(item: $selectedLock) { lock in
                LockDetailSheet(lock: lock)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
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
                ForEach(LockType.allCases, id: \.self) { t in
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
                Button {
                    selectedLock = lock
                } label: {
                    LockRow(lock: lock)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct LockRow: View {
    @Environment(AppStore.self) private var store
    let lock: AppLock

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
            VStack(alignment: .leading, spacing: 4) {
                Text(lock.name).font(.dsHeadline).foregroundStyle(DS.Color.textPrimary)
                HStack(spacing: 6) {
                    Image(systemName: lock.type.symbol)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(DS.Color.accent)
                    Text(lock.type.title)
                        .font(.dsCaption)
                        .foregroundStyle(DS.Color.textSecondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Toggle("", isOn: Binding(
                    get: { lock.enabled },
                    set: { _ in store.toggleLock(lock) }
                ))
                .labelsHidden()
                .tint(DS.Color.accent)
                Text("\(lock.earnedMinutesAvailable)m left")
                    .font(.dsTiny)
                    .foregroundStyle(DS.Color.textTertiary)
            }
        }
        .padding(14)
        .background(DS.Color.surface)
        .clipShape(.rect(cornerRadius: DS.Radius.medium))
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.medium).stroke(DS.Color.border, lineWidth: 1))
    }
}

// MARK: - Lock Detail Sheet

struct LockDetailSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State var lock: AppLock

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    headerCard
                    typePicker
                    requirementsCard
                    schedulingCard
                    Button {
                        store.updateLock(lock)
                        dismiss()
                    } label: {
                        Text("Save Changes")
                    }
                    .buttonStyle(DSPrimaryButtonStyle())
                    .padding(.top, 8)
                    Spacer(minLength: 30)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .background(DS.Color.background)
            .navigationTitle(lock.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(DS.Color.accent)
                }
            }
        }
    }

    private var headerCard: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(lock.iconColor.opacity(0.14))
                    .frame(width: 64, height: 64)
                Image(systemName: lock.symbol)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(lock.iconColor)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(lock.name).font(.dsTitle2).foregroundStyle(DS.Color.textPrimary)
                Text(lock.category).font(.dsCaption).foregroundStyle(DS.Color.textSecondary)
            }
            Spacer()
            Toggle("", isOn: $lock.enabled).labelsHidden().tint(DS.Color.accent)
        }
        .dsCard()
    }

    private var typePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Lock Type")
            VStack(spacing: 10) {
                ForEach(LockType.allCases, id: \.self) { t in
                    Button {
                        lock.type = t
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: t.symbol)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(lock.type == t ? .white : DS.Color.accent)
                                .frame(width: 36, height: 36)
                                .background(lock.type == t ? DS.Color.accent : DS.Color.accentSoft)
                                .clipShape(.rect(cornerRadius: 10))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(t.title).font(.dsHeadline).foregroundStyle(DS.Color.textPrimary)
                                Text(t.subtitle).font(.dsCaption).foregroundStyle(DS.Color.textSecondary)
                            }
                            Spacer()
                            if lock.type == t {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(DS.Color.accent)
                            }
                        }
                        .padding(14)
                        .background(DS.Color.surface)
                        .clipShape(.rect(cornerRadius: DS.Radius.medium))
                        .overlay(RoundedRectangle(cornerRadius: DS.Radius.medium)
                            .stroke(lock.type == t ? DS.Color.accent : DS.Color.border, lineWidth: lock.type == t ? 2 : 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private var requirementsCard: some View {
        if lock.type == .reward || lock.type == .educational {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Unlock Requirements")
                VStack(spacing: 14) {
                    if lock.type == .reward {
                        stepperRow(title: "Required minutes", value: $lock.requiredMinutes, range: 5...90, step: 5, suffix: "min")
                    } else {
                        stepperRow(title: "Required questions", value: $lock.requiredQuestions, range: 5...50, step: 5, suffix: "q")
                        subjectPicker
                    }
                }
                .dsCard()
            }
        }
    }

    private var subjectPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Subject")
                .font(.dsCaption)
                .foregroundStyle(DS.Color.textSecondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Subject.allCases) { s in
                        Button(s.title) { lock.requiredSubject = s }
                            .buttonStyle(DSChipStyle(selected: lock.requiredSubject == s))
                    }
                }
            }
        }
    }

    private func stepperRow(title: String, value: Binding<Int>, range: ClosedRange<Int>, step: Int, suffix: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.dsHeadline).foregroundStyle(DS.Color.textPrimary)
                Text("\(value.wrappedValue) \(suffix)").font(.dsCaption).foregroundStyle(DS.Color.textSecondary)
            }
            Spacer()
            HStack(spacing: 0) {
                stepperButton(symbol: "minus") {
                    value.wrappedValue = max(range.lowerBound, value.wrappedValue - step)
                }
                Text("\(value.wrappedValue)")
                    .font(.dsHeadline)
                    .foregroundStyle(DS.Color.textPrimary)
                    .frame(minWidth: 38)
                stepperButton(symbol: "plus") {
                    value.wrappedValue = min(range.upperBound, value.wrappedValue + step)
                }
            }
            .background(DS.Color.background)
            .clipShape(.capsule)
        }
    }

    private func stepperButton(symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(DS.Color.accent)
                .frame(width: 36, height: 36)
        }
    }

    @ViewBuilder
    private var schedulingCard: some View {
        if lock.type == .timed {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Schedule")
                VStack(spacing: 14) {
                    stepperRow(title: "Start hour", value: $lock.scheduleStart, range: 0...23, step: 1, suffix: ":00")
                    stepperRow(title: "End hour", value: $lock.scheduleEnd, range: 0...23, step: 1, suffix: ":00")
                }
                .dsCard()
            }
        }
    }
}
