//
//  LearnView.swift
//  Yoko
//

import SwiftUI

struct LearnView: View {
    @Environment(AppStore.self) private var store
    @Binding var hideDock: Bool
    @Binding var autoStartLesson: Lesson?
    @State private var path = NavigationPath()

    var body: some View {
        @Bindable var store = store
        NavigationStack(path: $path) {
            let _ = hideDock = !path.isEmpty
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 22) {
                        header
                        overviewCard
                        subjectsList
                        Spacer(minLength: 180)
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 12)
                }
                startLearningButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 101)
            }
            .dsScreenBackground()
            .navigationDestination(for: Subject.self) { subject in
                SubjectDetailView(subject: subject)
            }
            .navigationDestination(for: Lesson.self) { lesson in
                LessonPlayerView(lesson: lesson)
            }
        }
        .onChange(of: path.isEmpty) { _, empty in
            hideDock = !empty
        }
        .onChange(of: autoStartLesson) { _, lesson in
            if let lesson {
                path.append(lesson)
                autoStartLesson = nil
            }
        }
        .fullScreenCover(item: $store.pendingLevelUp) { info in
            LevelUpView(
                subject: info.subject,
                newLevel: info.newLevel,
                onDismiss: { store.pendingLevelUp = nil }
            )
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Learn")
                .font(.dsDisplay)
                .foregroundStyle(DS.Color.textPrimary)
            Text("Pick a subject and start a lesson")
                .font(.dsCallout)
                .foregroundStyle(DS.Color.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private var overviewCard: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Total XP")
                    .font(.dsCaption)
                    .foregroundStyle(DS.Color.textSecondary)
                Text("\(store.profile.totalXP)")
                    .font(.dsTitle)
                    .foregroundStyle(DS.Color.textPrimary)
            }
            Spacer()
            Divider().frame(height: 36)
            VStack(alignment: .leading, spacing: 4) {
                Text("Streak")
                    .font(.dsCaption)
                    .foregroundStyle(DS.Color.textSecondary)
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill").foregroundStyle(DS.Color.accent)
                    Text("\(store.profile.streak) days")
                        .font(.dsTitle2)
                        .foregroundStyle(DS.Color.textPrimary)
                }
            }
            Spacer()
            Divider().frame(height: 36)
            VStack(alignment: .leading, spacing: 4) {
                Text("Grade")
                    .font(.dsCaption)
                    .foregroundStyle(DS.Color.textSecondary)
                Text(gradeBadge(store.profile.grade))
                    .font(.dsTitle)
                    .foregroundStyle(DS.Color.textPrimary)
            }
        }
        .dsCard()
    }

    private var startLearningButton: some View {
        Button {
            if let lesson = nextLesson {
                path.append(lesson)
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "play.fill")
                Text("Start Learning")
            }
        }
        .buttonStyle(DSPrimaryButtonStyle())
        .shadow(color: DS.Color.accent.opacity(0.24), radius: 16, y: 8)
        .disabled(nextLesson == nil)
        .opacity(nextLesson == nil ? 0.55 : 1)
    }

    /// Short grade badge shown in the overview: Preschool → "P", Kindergarten →
    /// "K", and numeric grades show their number.
    private func gradeBadge(_ grade: Int) -> String {
        switch grade {
        case ...(-1): return "P"
        case 0: return "K"
        default: return "\(grade)"
        }
    }

    private var nextLesson: Lesson? {
        // Honors the parent's focus subject (Settings → Subjects) when set.
        store.focusedNextLesson
    }

    private var subjectsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Subjects")
            ForEach(store.subjects) { sp in
                NavigationLink(value: sp.subject) {
                    SubjectRow(progress: sp)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct SubjectRow: View {
    let progress: SubjectProgress

    private var levelEmoji: String {
        progress.currentLevel == 2 ? "🔥" : "👑"
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(progress.subject.tint.opacity(0.14))
                    .frame(width: 52, height: 52)
                Image(systemName: progress.subject.symbol)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(progress.subject.tint)
            }
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(progress.subject.title)
                        .font(.dsHeadline)
                        .foregroundStyle(DS.Color.textPrimary)
                    Spacer()
                    Text("\(progress.lessonsCompleted)/\(progress.lessons.count)")
                        .font(.dsCaption)
                        .foregroundStyle(DS.Color.textSecondary)
                }
                ProgressBar(progress: progress.progress, height: 6, tint: progress.subject.tint)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(DS.Color.textTertiary)
        }
        .dsCard(padding: 16)
        .overlay(alignment: .topTrailing) {
            if progress.currentLevel >= 2 {
                Text("Level \(progress.currentLevel) \(levelEmoji)")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(DS.Color.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(DS.Color.accentSoft)
                    .clipShape(.capsule)
                    .offset(x: -8, y: 8)
            }
        }
    }
}

// MARK: - Subject Detail

struct SubjectDetailView: View {
    @Environment(AppStore.self) private var store
    let subject: Subject

    var progress: SubjectProgress { store.subject(subject) ?? SubjectProgress(subject: subject, lessons: []) }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                heroCard
                lessonsList
                Spacer(minLength: 110)
            }
            .padding(.horizontal, 20)
            .padding(.top, 6)
        }
        .dsScreenBackground()
        .navigationTitle(subject.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(subject.tint.opacity(0.14))
                        .frame(width: 64, height: 64)
                    Image(systemName: subject.symbol)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(subject.tint)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(subject.title)
                        .font(.dsTitle)
                        .foregroundStyle(DS.Color.textPrimary)
                    Text("\(progress.lessonsCompleted) completed • \(progress.xp) XP")
                        .font(.dsCallout)
                        .foregroundStyle(DS.Color.textSecondary)
                }
                Spacer()
            }
            ProgressBar(progress: progress.masteryProgress, height: 10, tint: subject.tint)
            HStack {
                Text("\(Int(progress.masteryProgress * 100))% mastered")
                    .font(.dsCaption)
                    .foregroundStyle(DS.Color.textSecondary)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill").font(.system(size: 12)).foregroundStyle(DS.Color.accent)
                    Text("\(progress.streak)-day streak")
                        .font(.dsCaption)
                        .foregroundStyle(DS.Color.textSecondary)
                }
            }
        }
        .dsCard()
    }

    private var lessonsList: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Lessons")
            ForEach(Array(progress.lessons.enumerated()), id: \.element.id) { idx, lesson in
                NavigationLink(value: lesson) {
                    LessonRow(index: idx + 1, lesson: lesson, tint: subject.tint)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct LessonRow: View {
    let index: Int
    let lesson: Lesson
    let tint: Color

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(lesson.completed ? tint : DS.Color.accentSoft)
                    .frame(width: 38, height: 38)
                if lesson.completed {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    Text("\(index)")
                        .font(.dsHeadline)
                        .foregroundStyle(tint)
                }
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(lesson.title)
                    .font(.dsHeadline)
                    .foregroundStyle(DS.Color.textPrimary)
                Text("Level \(lesson.level) • \(lesson.questions.count) questions • \(lesson.totalXP) XP")
                    .font(.dsCaption)
                    .foregroundStyle(DS.Color.textSecondary)
            }
            Spacer()
            if lesson.completed {
                Text("\(lesson.bestScore)%")
                    .font(.dsCaption)
                    .foregroundStyle(DS.Color.textSecondary)
            } else {
                Image(systemName: "play.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(DS.Color.accent)
                    .clipShape(.circle)
            }
        }
        .dsCard(padding: 14)
    }
}
