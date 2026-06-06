//
//  SettingsView.swift
//  LearnLock
//

import SwiftUI
import FamilyControls

struct SettingsView: View {
    @Environment(AppStore.self) private var store
    @Environment(ScreenTimeService.self) private var screenTime
    @Environment(ParentAccountService.self) private var account
    @Environment(\.openURL) private var openURL
    @State private var showGradePicker: Bool = false
    @State private var showPromotion: Bool = false
    @State private var showEditProfile: Bool = false
    @State private var showDailyGoal: Bool = false
    @State private var showSubjects: Bool = false
    @State private var showFamilySharing: Bool = false
    @State private var showContactSupport: Bool = false
    @State private var showParentAccount: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                header
                if store.pendingPromotion != nil {
                    promotionBanner
                }
                profileCard
                parentAccountSection
                curriculumSection
                togglesSection
                permissionsSection
                supportSection
                resetOnboardingButton
                
                Text("LearnLock 1.0")
                    .font(.dsCaption)
                    .foregroundStyle(DS.Color.textTertiary)
                    .padding(.top, 8)
                Spacer(minLength: 110)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
        .dsScreenBackground()
        .sheet(isPresented: $showPromotion) {
            if let promo = store.pendingPromotion {
                NavigationStack {
                    GradePromotionView(promotion: promo)
                        .navigationTitle("Grade Promotion")
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
        .sheet(isPresented: $showGradePicker) {
            GradeLevelPickerSheet(currentGrade: store.profile.grade) { newGrade in
                store.setGrade(newGrade)
                showGradePicker = false
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileSheet(
                name: store.profile.name,
                grade: store.profile.grade,
                onSave: { newName, newGrade in
                    store.updateProfileName(newName)
                    if newGrade != store.profile.grade { store.setGrade(newGrade) }
                }
            )
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showDailyGoal) {
            DailyGoalSheet(current: store.profile.dailyMinuteGoal) { minutes in
                store.setDailyGoal(minutes)
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showSubjects) {
            SubjectsOverviewSheet(subjects: store.subjects)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showFamilySharing) {
            FamilySharingSheet(childName: store.profile.name)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showContactSupport) {
            ContactSupportSheet()
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showParentAccount) {
            ParentAccountSheet()
                .presentationDetents([.large])
        }
        .onAppear { screenTime.refreshStatus() }
    }

    private var promotionBanner: some View {
        Button { showPromotion = true } label: {
            HStack(spacing: 14) {
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(DS.Color.accent)
                    .clipShape(.rect(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(store.profile.name) is ready for the next grade!")
                        .font(.dsHeadline)
                        .foregroundStyle(DS.Color.textPrimary)
                        .multilineTextAlignment(.leading)
                    Text("Tap to review and approve")
                        .font(.dsCaption)
                        .foregroundStyle(DS.Color.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DS.Color.textTertiary)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(DS.Color.accentSoft)
            .clipShape(.rect(cornerRadius: DS.Radius.large))
            .overlay(RoundedRectangle(cornerRadius: DS.Radius.large).stroke(DS.Color.accent, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }

    private var parentAccountSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Account & Device Sync")
            Button { showParentAccount = true } label: {
                HStack(spacing: 14) {
                    Image(systemName: account.isLinked ? "checkmark.icloud.fill" : "person.crop.circle.badge.plus")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(account.isLinked ? DS.Color.success : DS.Color.accent)
                        .clipShape(.rect(cornerRadius: 12))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(account.isLinked ? "Parent Account" : "Create Parent Account")
                            .font(.dsHeadline)
                            .foregroundStyle(DS.Color.textPrimary)
                        Text(account.isLinked
                             ? (account.email ?? "Synced across your devices")
                             : "Sync progress between phone & iPad")
                            .font(.dsCaption)
                            .foregroundStyle(DS.Color.textSecondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(DS.Color.textTertiary)
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(DS.Color.surface)
                .clipShape(.rect(cornerRadius: DS.Radius.large))
                .overlay(RoundedRectangle(cornerRadius: DS.Radius.large).stroke(DS.Color.border, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    private var curriculumSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Curriculum")
            VStack(spacing: 0) {
                Button { showGradePicker = true } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "graduationcap.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(DS.Color.accent)
                            .frame(width: 36, height: 36)
                            .background(DS.Color.accentSoft)
                            .clipShape(.rect(cornerRadius: 10))
                        Text("Grade Level").font(.dsHeadline).foregroundStyle(DS.Color.textPrimary)
                        Spacer()
                        Text(gradeLabel(store.profile.grade))
                            .font(.dsCallout)
                            .foregroundStyle(DS.Color.textSecondary)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(DS.Color.textTertiary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Divider().padding(.leading, 56)
                navRow(symbol: "book.closed.fill", title: "Subjects", value: "\(store.subjects.count)") { showSubjects = true }
                Divider().padding(.leading, 56)
                navRow(symbol: "target", title: "Daily Goal", value: "\(store.profile.dailyMinuteGoal) min") { showDailyGoal = true }
            }
            .background(DS.Color.surface)
            .clipShape(.rect(cornerRadius: DS.Radius.large))
            .overlay(RoundedRectangle(cornerRadius: DS.Radius.large).stroke(DS.Color.border, lineWidth: 1))
        }
    }

    private func gradeLabel(_ g: Int) -> String {
        GradeLevelOption(rawValue: g)?.displayName ?? "Grade \(g)"
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Settings")
                .font(.dsDisplay)
                .foregroundStyle(DS.Color.textPrimary)
            Text("Manage profiles, locks, and permissions")
                .font(.dsCallout)
                .foregroundStyle(DS.Color.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private var profileCard: some View {
        Button { showEditProfile = true } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(DS.Color.accent).frame(width: 56, height: 56)
                    Text(String(store.profile.name.prefix(1)))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(store.profile.name).font(.dsTitle2).foregroundStyle(DS.Color.textPrimary)
                    Text("Child profile • \(gradeLabel(store.profile.grade))")
                        .font(.dsCaption)
                        .foregroundStyle(DS.Color.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DS.Color.textTertiary)
            }
            .dsCard()
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var togglesSection: some View {
        @Bindable var store = store
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Notifications & Security")
            VStack(spacing: 0) {
                toggleRow(symbol: "bell.badge.fill", title: "Notifications", isOn: $store.notificationsEnabled)
                Divider().padding(.leading, 56)
                toggleRow(symbol: "moon.stars.fill", title: "Bedtime Lock", isOn: $store.bedtimeLockEnabled)
                Divider().padding(.leading, 56)
                toggleRow(symbol: "lock.shield.fill", title: "Parent Passcode", isOn: $store.parentPasscodeEnabled)
            }
            .background(DS.Color.surface)
            .clipShape(.rect(cornerRadius: DS.Radius.large))
            .overlay(RoundedRectangle(cornerRadius: DS.Radius.large).stroke(DS.Color.border, lineWidth: 1))
        }
    }

    private func toggleRow(symbol: String, title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(DS.Color.accent)
                .frame(width: 36, height: 36)
                .background(DS.Color.accentSoft)
                .clipShape(.rect(cornerRadius: 10))
            Text(title).font(.dsHeadline).foregroundStyle(DS.Color.textPrimary)
            Spacer()
            Toggle("", isOn: isOn).labelsHidden().tint(DS.Color.accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Permissions & Sync

    private var screenTimeValue: String {
        switch screenTime.authorizationStatus {
        case .approved: return "Granted"
        case .denied: return "Denied"
        case .notDetermined: return "Set up"
        @unknown default: return "—"
        }
    }

    @ViewBuilder
    private var permissionsSection: some View {
        @Bindable var store = store
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Permissions & Sync")
            VStack(spacing: 0) {
                navRow(symbol: "hourglass", title: "Screen Time Permission", value: screenTimeValue) {
                    handleScreenTimeTap()
                }
                Divider().padding(.leading, 56)
                toggleRow(symbol: "icloud.fill", title: "iCloud Sync", isOn: $store.iCloudSyncEnabled)
                Divider().padding(.leading, 56)
                navRow(symbol: "person.2.fill", title: "Family Sharing", value: "1 child") {
                    showFamilySharing = true
                }
            }
            .background(DS.Color.surface)
            .clipShape(.rect(cornerRadius: DS.Radius.large))
            .overlay(RoundedRectangle(cornerRadius: DS.Radius.large).stroke(DS.Color.border, lineWidth: 1))
        }
    }

    private func handleScreenTimeTap() {
        switch screenTime.authorizationStatus {
        case .notDetermined:
            Task { await screenTime.requestAuthorization() }
        case .denied, .approved:
            if let url = URL(string: UIApplication.openSettingsURLString) {
                openURL(url)
            }
        @unknown default:
            break
        }
    }

    // MARK: - Support

    private var supportSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Support")
            VStack(spacing: 0) {
                navRow(symbol: "questionmark.circle.fill", title: "Help Center", value: nil) {
                    if let url = URL(string: "https://rork.app") { openURL(url) }
                }
                Divider().padding(.leading, 56)
                navRow(symbol: "envelope.fill", title: "Contact Support", value: nil) {
                    showContactSupport = true
                }
                Divider().padding(.leading, 56)
                navRow(symbol: "doc.text.fill", title: "Privacy Policy", value: nil) {
                    if let url = URL(string: "https://rork.app/privacy") { openURL(url) }
                }
            }
            .background(DS.Color.surface)
            .clipShape(.rect(cornerRadius: DS.Radius.large))
            .overlay(RoundedRectangle(cornerRadius: DS.Radius.large).stroke(DS.Color.border, lineWidth: 1))
        }
    }

    private func navRow(symbol: String, title: String, value: String?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: symbol)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(DS.Color.accent)
                    .frame(width: 36, height: 36)
                    .background(DS.Color.accentSoft)
                    .clipShape(.rect(cornerRadius: 10))
                Text(title).font(.dsHeadline).foregroundStyle(DS.Color.textPrimary)
                Spacer()
                if let value {
                    Text(value).font(.dsCallout).foregroundStyle(DS.Color.textSecondary)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DS.Color.textTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var resetOnboardingButton: some View {
        Button {
            store.resetOnboarding()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(DS.Color.accent)
                    .clipShape(.rect(cornerRadius: 10))
                Text("Reset Onboarding")
                    .font(.dsHeadline)
                    .foregroundStyle(.white)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(DS.Color.accent)
            .clipShape(.rect(cornerRadius: DS.Radius.large))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Grade Level Picker Sheet

struct GradeLevelPickerSheet: View {
    let currentGrade: Int
    let onSelect: (Int) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    Text("Changing the grade rebuilds the lesson queue at the new difficulty. Completed lessons stay in history.")
                        .font(.dsCaption)
                        .foregroundStyle(DS.Color.textSecondary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 6)

                    ForEach(GradeLevelOption.allCases) { option in
                        Button {
                            onSelect(option.rawValue)
                            dismiss()
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(option.rawValue == currentGrade ? DS.Color.accent : DS.Color.accentSoft)
                                        .frame(width: 36, height: 36)
                                    Image(systemName: "graduationcap.fill")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(option.rawValue == currentGrade ? .white : DS.Color.accent)
                                }
                                Text(option.displayName)
                                    .font(.dsHeadline)
                                    .foregroundStyle(DS.Color.textPrimary)
                                Spacer()
                                if option.rawValue == currentGrade {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(DS.Color.accent)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(DS.Color.surface)
                            .clipShape(.rect(cornerRadius: DS.Radius.large))
                            .overlay(
                                RoundedRectangle(cornerRadius: DS.Radius.large)
                                    .stroke(option.rawValue == currentGrade ? DS.Color.accent : DS.Color.border,
                                            lineWidth: option.rawValue == currentGrade ? 2 : 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }
            .dsScreenBackground()
            .navigationTitle("Grade Level")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Edit Profile Sheet

struct EditProfileSheet: View {
    @State private var name: String
    @State private var grade: Int
    let onSave: (String, Int) -> Void
    @Environment(\.dismiss) private var dismiss

    init(name: String, grade: Int, onSave: @escaping (String, Int) -> Void) {
        self._name = State(initialValue: name)
        self._grade = State(initialValue: grade)
        self.onSave = onSave
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Child's Name")
                            .font(.dsCaption)
                            .foregroundStyle(DS.Color.textSecondary)
                        TextField("Name", text: $name)
                            .font(.dsHeadline)
                            .foregroundStyle(DS.Color.textPrimary)
                            .textInputAutocapitalization(.words)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(DS.Color.surface)
                            .clipShape(.rect(cornerRadius: DS.Radius.medium))
                            .overlay(RoundedRectangle(cornerRadius: DS.Radius.medium).stroke(DS.Color.border, lineWidth: 1))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Grade Level")
                            .font(.dsCaption)
                            .foregroundStyle(DS.Color.textSecondary)
                        Picker("Grade", selection: $grade) {
                            ForEach(GradeLevelOption.allCases) { option in
                                Text(option.displayName).tag(option.rawValue)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(DS.Color.accent)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(DS.Color.surface)
                        .clipShape(.rect(cornerRadius: DS.Radius.medium))
                        .overlay(RoundedRectangle(cornerRadius: DS.Radius.medium).stroke(DS.Color.border, lineWidth: 1))
                    }

                    Text("Changing the grade rebuilds the lesson queue at the new difficulty. Completed lessons stay in history.")
                        .font(.dsCaption)
                        .foregroundStyle(DS.Color.textTertiary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            .dsScreenBackground()
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(trimmedName, grade)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(trimmedName.isEmpty)
                }
            }
        }
    }
}

// MARK: - Daily Goal Sheet

struct DailyGoalSheet: View {
    @State private var minutes: Int
    let onSave: (Int) -> Void
    @Environment(\.dismiss) private var dismiss

    private let options: [Int] = [10, 15, 20, 30, 45, 60]

    init(current: Int, onSave: @escaping (Int) -> Void) {
        self._minutes = State(initialValue: current)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    Text("How many minutes should your child aim to learn each day?")
                        .font(.dsCaption)
                        .foregroundStyle(DS.Color.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 6)

                    ForEach(options, id: \.self) { value in
                        Button {
                            minutes = value
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(value == minutes ? DS.Color.accent : DS.Color.accentSoft)
                                        .frame(width: 36, height: 36)
                                    Image(systemName: "target")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(value == minutes ? .white : DS.Color.accent)
                                }
                                Text("\(value) minutes")
                                    .font(.dsHeadline)
                                    .foregroundStyle(DS.Color.textPrimary)
                                Spacer()
                                if value == minutes {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(DS.Color.accent)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(DS.Color.surface)
                            .clipShape(.rect(cornerRadius: DS.Radius.large))
                            .overlay(
                                RoundedRectangle(cornerRadius: DS.Radius.large)
                                    .stroke(value == minutes ? DS.Color.accent : DS.Color.border,
                                            lineWidth: value == minutes ? 2 : 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }
            .dsScreenBackground()
            .navigationTitle("Daily Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(minutes)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Subjects Overview Sheet

struct SubjectsOverviewSheet: View {
    let subjects: [SubjectProgress]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    ForEach(subjects) { sp in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(sp.subject.tint.opacity(0.15))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: sp.subject.symbol)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(sp.subject.tint)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(sp.subject.title)
                                        .font(.dsHeadline)
                                        .foregroundStyle(DS.Color.textPrimary)
                                    Text("\(sp.lessonsCompleted) lessons completed • \(sp.xp) XP")
                                        .font(.dsCaption)
                                        .foregroundStyle(DS.Color.textSecondary)
                                }
                                Spacer()
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Mastery")
                                        .font(.dsCaption)
                                        .foregroundStyle(DS.Color.textSecondary)
                                    Spacer()
                                    Text("\(Int(sp.masteryProgress * 100))%")
                                        .font(.dsCaption)
                                        .foregroundStyle(DS.Color.accent)
                                }
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule().fill(DS.Color.border).frame(height: 8)
                                        Capsule().fill(sp.subject.tint)
                                            .frame(width: max(8, geo.size.width * sp.masteryProgress), height: 8)
                                    }
                                }
                                .frame(height: 8)
                            }
                        }
                        .dsCard()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }
            .dsScreenBackground()
            .navigationTitle("Subjects")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Family Sharing Sheet

struct FamilySharingSheet: View {
    let childName: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    VStack(spacing: 10) {
                        ZStack {
                            Circle().fill(DS.Color.accentSoft).frame(width: 72, height: 72)
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundStyle(DS.Color.accent)
                        }
                        Text("Family Sharing")
                            .font(.dsTitle2)
                            .foregroundStyle(DS.Color.textPrimary)
                        Text("Manage the children connected to this account.")
                            .font(.dsCallout)
                            .foregroundStyle(DS.Color.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 8)

                    VStack(spacing: 0) {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle().fill(DS.Color.accent).frame(width: 40, height: 40)
                                Text(String(childName.prefix(1)))
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(childName).font(.dsHeadline).foregroundStyle(DS.Color.textPrimary)
                                Text("Child profile").font(.dsCaption).foregroundStyle(DS.Color.textSecondary)
                            }
                            Spacer()
                            Text("Active")
                                .font(.dsTiny)
                                .foregroundStyle(DS.Color.success)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(DS.Color.success.opacity(0.12))
                                .clipShape(.capsule)
                        }
                        .padding(16)
                    }
                    .background(DS.Color.surface)
                    .clipShape(.rect(cornerRadius: DS.Radius.large))
                    .overlay(RoundedRectangle(cornerRadius: DS.Radius.large).stroke(DS.Color.border, lineWidth: 1))

                    Text("Adding more children is coming soon.")
                        .font(.dsCaption)
                        .foregroundStyle(DS.Color.textTertiary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }
            .dsScreenBackground()
            .navigationTitle("Family Sharing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Contact Support Sheet

struct ContactSupportSheet: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss

    private let supportEmail = "support@rork.app"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    VStack(spacing: 10) {
                        ZStack {
                            Circle().fill(DS.Color.accentSoft).frame(width: 72, height: 72)
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(DS.Color.accent)
                        }
                        Text("We're here to help")
                            .font(.dsTitle2)
                            .foregroundStyle(DS.Color.textPrimary)
                        Text("Reach our team and we'll get back to you within one business day.")
                            .font(.dsCallout)
                            .foregroundStyle(DS.Color.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 8)

                    Button {
                        if let url = URL(string: "mailto:\(supportEmail)?subject=LearnLock%20Support") {
                            openURL(url)
                        }
                    } label: {
                        Text("Email \(supportEmail)")
                    }
                    .buttonStyle(DSPrimaryButtonStyle())
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }
            .dsScreenBackground()
            .navigationTitle("Contact Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Parent Account & Sync Sheet

struct ParentAccountSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(ParentAccountService.self) private var account
    @Environment(\.dismiss) private var dismiss

    private enum Mode { case create, signIn, link }
    @State private var mode: Mode = .create
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var code: String = ""
    @State private var working: Bool = false
    @State private var justSynced: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    if account.isLinked {
                        linkedContent
                    } else {
                        authContent
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 40)
            }
            .dsScreenBackground()
            .navigationTitle(account.isLinked ? "Device Sync" : "Parent Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: Linked (signed-in) state

    private var linkedContent: some View {
        VStack(spacing: 18) {
            VStack(spacing: 10) {
                ZStack {
                    Circle().fill(DS.Color.success.opacity(0.15)).frame(width: 72, height: 72)
                    Image(systemName: "checkmark.icloud.fill")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(DS.Color.success)
                }
                Text(account.role == .child ? "This is the child's device" : "This is the parent's device")
                    .font(.dsTitle2)
                    .foregroundStyle(DS.Color.textPrimary)
                    .multilineTextAlignment(.center)
                if let email = account.email {
                    Text(email).font(.dsCallout).foregroundStyle(DS.Color.textSecondary)
                }
            }
            .padding(.top, 4)

            // Sync code card — share with the other device
            if let codeValue = account.syncCode {
                VStack(spacing: 10) {
                    Text("SYNC CODE")
                        .font(.dsTiny)
                        .foregroundStyle(DS.Color.textSecondary)
                        .tracking(1.5)
                    Text(codeValue)
                        .font(.system(size: 38, weight: .heavy, design: .rounded))
                        .foregroundStyle(DS.Color.accent)
                        .tracking(6)
                    Text("Enter this code on your child's device to link it.")
                        .font(.dsCaption)
                        .foregroundStyle(DS.Color.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(DS.Color.accentSoft)
                .clipShape(.rect(cornerRadius: DS.Radius.large))
            }

            if let last = account.lastSyncedAt {
                Text("Last synced \(last.formatted(date: .abbreviated, time: .shortened))")
                    .font(.dsCaption)
                    .foregroundStyle(DS.Color.textTertiary)
            }

            Button {
                Task { await syncNow() }
            } label: {
                HStack(spacing: 8) {
                    if account.isSyncing || justSynced {
                        Image(systemName: justSynced ? "checkmark" : "arrow.triangle.2.circlepath")
                    }
                    Text(account.isSyncing ? "Syncing…" : (justSynced ? "Synced" : "Sync Now"))
                }
            }
            .buttonStyle(DSPrimaryButtonStyle())
            .disabled(account.isSyncing)

            if let error = account.errorMessage {
                errorLabel(error)
            }

            Button(role: .destructive) {
                account.signOut()
            } label: {
                Text("Sign Out on This Device")
                    .font(.dsHeadline)
                    .foregroundStyle(DS.Color.danger)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
        }
    }

    // MARK: Auth (signed-out) state

    private var authContent: some View {
        VStack(spacing: 18) {
            VStack(spacing: 10) {
                ZStack {
                    Circle().fill(DS.Color.accentSoft).frame(width: 72, height: 72)
                    Image(systemName: "person.2.badge.gearshape.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(DS.Color.accent)
                }
                Text("Sync across devices")
                    .font(.dsTitle2)
                    .foregroundStyle(DS.Color.textPrimary)
                Text("Create a parent account to watch progress and manage locks from your phone while your child learns on their iPad.")
                    .font(.dsCallout)
                    .foregroundStyle(DS.Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 4)

            Picker("Mode", selection: $mode) {
                Text("Create").tag(Mode.create)
                Text("Sign In").tag(Mode.signIn)
                Text("Link").tag(Mode.link)
            }
            .pickerStyle(.segmented)

            if mode == .link {
                fieldLabel("6-Character Sync Code")
                TextField("e.g. ABC123", text: $code)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .modifier(FieldStyle())
                Text("Ask the parent for the sync code shown on their device.")
                    .font(.dsCaption)
                    .foregroundStyle(DS.Color.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                fieldLabel("Email")
                TextField("you@example.com", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .modifier(FieldStyle())
                fieldLabel("Password")
                SecureField("At least 6 characters", text: $password)
                    .modifier(FieldStyle())
            }

            if let error = account.errorMessage {
                errorLabel(error)
            }

            Button {
                Task { await submit() }
            } label: {
                Text(working ? "Please wait…" : primaryTitle)
            }
            .buttonStyle(DSPrimaryButtonStyle())
            .disabled(working || !canSubmit)
        }
    }

    private var primaryTitle: String {
        switch mode {
        case .create: return "Create Account"
        case .signIn: return "Sign In"
        case .link: return "Link This Device"
        }
    }

    private var canSubmit: Bool {
        switch mode {
        case .create, .signIn:
            return email.contains("@") && password.count >= 6
        case .link:
            return code.trimmingCharacters(in: .whitespaces).count >= 6
        }
    }

    private func submit() async {
        working = true
        defer { working = false }
        let ok: Bool
        switch mode {
        case .create: ok = await account.signUp(email: email, password: password)
        case .signIn: ok = await account.signIn(email: email, password: password)
        case .link: ok = await account.linkDevice(code: code)
        }
        guard ok else { return }
        if mode == .create {
            await account.push(store.exportSnapshot())
        } else if let remote = await account.pull() {
            store.applySnapshot(remote)
        }
    }

    private func syncNow() async {
        if let remote = await account.pull() {
            store.applySnapshot(remote)
        }
        let ok = await account.push(store.exportSnapshot())
        if ok {
            justSynced = true
            try? await Task.sleep(for: .seconds(1.5))
            justSynced = false
        }
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.dsCaption)
            .foregroundStyle(DS.Color.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func errorLabel(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(text)
        }
        .font(.dsCaption)
        .foregroundStyle(DS.Color.danger)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct FieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.dsHeadline)
            .foregroundStyle(DS.Color.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(DS.Color.surface)
            .clipShape(.rect(cornerRadius: DS.Radius.medium))
            .overlay(RoundedRectangle(cornerRadius: DS.Radius.medium).stroke(DS.Color.border, lineWidth: 1))
    }
}
