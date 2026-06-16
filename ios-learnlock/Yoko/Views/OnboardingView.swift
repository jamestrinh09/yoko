//
//  OnboardingView.swift
//  Yoko
//

import SwiftUI
import UserNotifications
import FamilyControls

struct OnboardingView: View {
    @Environment(AppStore.self) private var store
    @Environment(ScreenTimeService.self) private var screenTime
    @State private var step: Int = 1
    @State private var childName: String = ""
    @State private var grade: String = ""
    @State private var screenStruggle: String = ""
    @State private var dailyScreenTime: Double? = nil
    @State private var dailyLearningTime: String = ""
    @State private var unlockRule: String = "session"
    @State private var nameError: String = ""
    @State private var q1: String? = nil
    @State private var q2: String? = nil
    @State private var q3: String? = nil
    @State private var imageLoaded2 = false
    @State private var imageLoaded3 = false
    @State private var imageLoaded11 = false
    @State private var imageLoaded13 = false

    private let totalSteps = 24

    var body: some View {
        Group {
            if step == 24 {
                commitmentScreen
            } else if isDemoQuestionStep {
                demoQuestionScreen
            } else {
                standardScreen
            }
        }
        .animation(.spring(duration: 0.4), value: step)
        .onChange(of: step) {
            imageLoaded2 = false
            imageLoaded3 = false
            imageLoaded11 = false
            imageLoaded13 = false
        }
    }

    private var isDemoQuestionStep: Bool {
        step == 15 || step == 16 || step == 17
    }

    // MARK: - Commitment Screen

    private var commitmentScreen: some View {
        CommitmentScreen(
            childName: childName,
            onBack: {
                withAnimation(.spring(duration: 0.3)) { step = max(1, step - 1) }
            },
            onComplete: completeOnboarding
        )
    }

    // MARK: - Standard Screen

    private var standardScreen: some View {
        ZStack {
            stepBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar(tintWhite: isGradientStep)

                ScrollView(showsIndicators: false) {
                    currentStepContent
                        .frame(maxWidth: 520)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 24)
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
                footerView
                    .frame(maxWidth: 520)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 20)
            }
            .background(isGradientStep ? Color.clear : DS.Color.background)
        }
    }

    private func topBar(tintWhite: Bool) -> some View {
        HStack(spacing: 0) {
            if step > 1 {
                Button {
                    withAnimation(.spring(duration: 0.3)) {
                        step = max(1, step - 1)
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(tintWhite ? .white : DS.Color.textPrimary)
                        .frame(width: 44, height: 44)
                        .background(Color.clear)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            } else {
                Color.clear
                    .frame(width: 44, height: 44)
            }

            if step > 1 {
                ProgressView(value: Double(step), total: Double(totalSteps))
                    .tint(tintWhite ? .white : DS.Color.accent)
                    .frame(height: 4)
                    .frame(maxWidth: 280)
            }

            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
    }

    // MARK: - Background

    private var stepBackground: some View {
        Group {
            if step == 1 || step == 12 || step == 18 || step == 21 {
                LinearGradient(
                    colors: step == 12 || step == 21
                        ? [Color(red: 1.0, green: 0.69, blue: 0.0), DS.Color.accent, Color(red: 1.0, green: 0.54, blue: 0.12), DS.Color.accent]
                        : [Color(red: 1.0, green: 0.69, blue: 0.0), DS.Color.accent, Color(red: 1.0, green: 0.69, blue: 0.6), Color(red: 1.0, green: 0.94, blue: 0.9), .white],
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else {
                DS.Color.background
            }
        }
    }

    private var isGradientStep: Bool {
        step == 1 || step == 12 || step == 18 || step == 21
    }

    // MARK: - Step Content

    @ViewBuilder
    private var currentStepContent: some View {
        switch step {
        case 1: Step1()
        case 2: Step2()
        case 3: Step3()
        case 4: Step4()
        case 5: Step5()
        case 6: Step6()
        case 7: Step7()
        case 8: Step8()
        case 9: Step9()
        case 10: Step10()
        case 11: Step11()
        case 12: Step12()
        case 13: Step13()
        case 14: Step14()
        case 15: Step15()
        case 16: Step16()
        case 17: Step17()
        case 18: Step18()
        case 19: Step19()
        case 20: Step20()
        case 21: Step21()
        case 22: Step22()
        case 23: Step23()
        default: EmptyView()
        }
    }

    // MARK: - Footer / CTA

    @ViewBuilder
    private var footerView: some View {
        switch step {
        case 1:
            PrimaryButton(label: "Get started", action: nextStep)
        case 2:
            PrimaryButton(label: "That sounds familiar", action: nextStep)
        case 3:
            PrimaryButton(label: "Show me", action: nextStep)
        case 4:
            PrimaryButton(label: "Continue", action: validateAndNext4)
        case 5:
            PrimaryButton(label: "Continue", action: nextStep, disabled: grade.isEmpty)
        case 6:
            PrimaryButton(label: "Continue", action: nextStep, disabled: screenStruggle.isEmpty)
        case 7:
            PrimaryButton(label: "Continue", action: nextStep, disabled: dailyScreenTime == nil)
        case 8:
            PrimaryButton(label: "Continue", action: nextStep, disabled: dailyLearningTime.isEmpty)
        case 9:
            PrimaryButton(label: "Build a better routine", action: nextStep)
        case 10:
            PrimaryButton(label: "Continue", action: nextStep)
        case 11:
            PrimaryButton(label: "Continue", action: nextStep)
        case 12:
            PrimaryButton(label: "Continue", action: nextStep, variant: .white)
        case 14:
            PrimaryButton(label: "let's learn 🤩", action: nextStep)
        case 18:
            PrimaryButton(label: "Continue", action: nextStep)
        case 19:
            PrimaryButton(label: "Use this rule", action: nextStep)
        case 20:
            PrimaryButton(label: "Continue", action: nextStep)
        case 21:
            PrimaryButton(label: "Continue", action: nextStep, variant: .white)
        case 22:
            VStack(spacing: 12) {
                PrimaryButton(
                    label: screenTime.isAuthorized ? "Continue" : (screenTime.isRequesting ? "Requesting…" : "Enable Screen Time"),
                    action: requestScreenTimeThenNext,
                    disabled: screenTime.isRequesting
                )
                if !screenTime.isAuthorized {
                    Button("Maybe later", action: nextStep)
                        .font(.dsCallout)
                        .foregroundStyle(DS.Color.textSecondary)
                }
            }
        case 23:
            VStack(spacing: 12) {
                PrimaryButton(label: "Turn on notifications", action: requestNotificationsThenFinish)
                Button("Not now", action: nextStep)
                    .font(.dsCallout)
                    .foregroundStyle(DS.Color.textSecondary)
            }
        default:
            EmptyView()
        }
    }

    // MARK: - Actions

    private func nextStep() {
        let gen = UIImpactFeedbackGenerator(style: .light)
        gen.impactOccurred()
        withAnimation(.spring(duration: 0.35)) {
            step = min(step + 1, totalSteps)
        }
    }

    private func validateAndNext4() {
        if childName.trimmingCharacters(in: .whitespaces).isEmpty {
            nameError = "Please enter your child's name"
            let gen = UINotificationFeedbackGenerator()
            gen.notificationOccurred(.error)
        } else {
            nameError = ""
            nextStep()
        }
    }

    private func completeOnboarding() {
        let gen = UIImpactFeedbackGenerator(style: .medium)
        gen.impactOccurred()
        store.unlockRule = unlockRule
        store.onboardingComplete = true
    }

    private func requestScreenTimeThenNext() {
        if screenTime.isAuthorized {
            nextStep()
            return
        }
        Task {
            await screenTime.requestAuthorization()
            UINotificationFeedbackGenerator().notificationOccurred(screenTime.isAuthorized ? .success : .warning)
            nextStep()
        }
    }

    private func requestNotificationsThenFinish() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        Task {
            let granted = (try? await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])) ?? false
            store.notificationsEnabled = granted
            nextStep()
        }
    }

    // MARK: - Step 1

    private func Step1() -> some View {
        VStack(spacing: 0) {
            mascotBubble(text: "Hi I'm Yoko")
            MascotGIF(url: mascotGIF(.happy), size: min(261, UIScreen.main.bounds.width * 0.6))
                .padding(.top, 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
        .padding(.bottom, 40)
    }

    // MARK: - Step 2

    private func Step2() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            RoundedImageCard(url: onboardingImage(.lookingAtIpad)) {
                withAnimation(.easeIn(duration: 0.3)) { imageLoaded2 = true }
            }
            Group {
                Text("Kids are mastering games and videos before ")
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                    + Text("learning")
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundStyle(DS.Color.accent)
                Text("Yoko puts learning first to ")
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                + Text("unlock")
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundStyle(DS.Color.accent)
                + Text(" play")
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
            }
            .lineSpacing(6)
            .opacity(imageLoaded2 ? 1 : 0)
            .animation(.easeIn(duration: 0.3), value: imageLoaded2)
        }
        .foregroundStyle(DS.Color.textPrimary)
    }

    // MARK: - Step 3

    private func Step3() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            RoundedImageCard(url: onboardingImage(.behindPov)) {
                withAnimation(.easeIn(duration: 0.3)) { imageLoaded3 = true }
            }
            Group {
                Text("Make learning the ")
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                + Text("gateway")
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundStyle(DS.Color.accent)
                + Text(" to play and help build healthier learning habits")
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
            }
            .lineSpacing(6)
            .opacity(imageLoaded3 ? 1 : 0)
            .animation(.easeIn(duration: 0.3), value: imageLoaded3)
        }
        .foregroundStyle(DS.Color.textPrimary)
    }

    // MARK: - Step 4

    private func Step4() -> some View {
        VStack(alignment: .leading, spacing: 24) {
            MascotGIF(url: mascotGIF(.thinking), size: 175)
                .frame(maxWidth: .infinity)
            Text("Who are we helping?")
                .font(.dsTitle)
                .foregroundStyle(DS.Color.textPrimary)

            VStack(alignment: .leading, spacing: 8) {
                Text("Child's name")
                    .font(.dsHeadline)
                    .foregroundStyle(DS.Color.textPrimary)
                TextField("Enter name", text: $childName)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(DS.Color.surface)
                    .clipShape(.rect(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(nameError.isEmpty ? DS.Color.border : DS.Color.danger, lineWidth: 1.5)
                    )
                    .shadow(color: DS.Color.accent.opacity(0.28), radius: 16, y: 6)
                if !nameError.isEmpty {
                    Text(nameError)
                        .font(.dsCaption)
                        .foregroundStyle(DS.Color.danger)
                }
            }
        }
    }

    // MARK: - Step 5

    private func Step5() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("What grade is \(childName.isEmpty ? "your child" : childName) in?")
                .font(.dsTitle)
                .foregroundStyle(DS.Color.textPrimary)

            let grades: [(id: String, label: String, desc: String)] = [
                ("kindergarten", "Preschool / Kindergarten", "Counting, letters, sounds"),
                ("1st", "1st Grade", "Addition, subtraction, sight words"),
                ("2nd", "2nd Grade", "Place value, reading fluency"),
                ("3rd", "3rd Grade", "Multiplication, grammar"),
                ("4th", "4th Grade", "Fractions, writing"),
                ("5th", "5th Grade", "Decimals, comprehension")
            ]

            VStack(spacing: 14) {
                ForEach(grades, id: \.id) { g in
                    SelectableRow(
                        title: g.label,
                        subtitle: g.desc,
                        selected: grade == g.id
                    ) {
                        grade = g.id
                    }
                }
            }
        }
    }

    // MARK: - Step 6

    private func Step6() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("What causes the screen time battle?")
                .font(.dsTitle)
                .foregroundStyle(DS.Color.textPrimary)

            let options: [(id: String, label: String, icon: String)] = [
                ("youtube", "YouTube or videos", "📺"),
                ("roblox", "Roblox or games", "🎮"),
                ("tiktok", "TikTok or shorts", "🎵"),
                ("safari", "Safari or browsing", "🌐"),
                ("all", "All of the above", "📱")
            ]

            VStack(spacing: 14) {
                ForEach(options, id: \.id) { o in
                    HStack(spacing: 14) {
                        Text(o.icon)
                            .font(.system(size: 22))
                        Text(o.label)
                            .font(.dsHeadline)
                            .foregroundStyle(DS.Color.textPrimary)
                        Spacer()
                        if screenStruggle == o.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(DS.Color.accent)
                                .font(.system(size: 22))
                        }
                    }
                    .frame(minHeight: 28)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(DS.Color.surface)
                    .clipShape(.rect(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(screenStruggle == o.id ? DS.Color.accent : Color.clear, lineWidth: 2)
                    )
                    .shadow(
                        color: screenStruggle == o.id ? DS.Color.accent.opacity(0.18) : Color.black.opacity(0.08),
                        radius: screenStruggle == o.id ? 10 : 8,
                        y: screenStruggle == o.id ? 4 : 3
                    )
                    .onTapGesture {
                        screenStruggle = o.id
                    }
                }
            }
        }
    }

    // MARK: - Step 7

    private func Step7() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("How much entertainment screen time does \(childName.isEmpty ? "your child" : childName) get per day?")
                .font(.dsTitle)
                .foregroundStyle(DS.Color.textPrimary)

            let options: [(id: Double, label: String)] = [
                (0.5, "Less than 1 hour"),
                (1.5, "1–2 hours"),
                (2.5, "2–3 hours"),
                (3.5, "3–4 hours"),
                (4.5, "4+ hours")
            ]

            VStack(spacing: 14) {
                ForEach(options, id: \.id) { o in
                    SelectableRow(
                        title: o.label,
                        selected: dailyScreenTime == o.id
                    ) {
                        dailyScreenTime = o.id
                    }
                }
            }
        }
    }

    // MARK: - Step 8

    private func Step8() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("How much daily practice do they usually get?")
                .font(.dsTitle)
                .foregroundStyle(DS.Color.textPrimary)

            let options = ["Less than 10 minutes", "10–20 minutes", "20–30 minutes", "30+ minutes", "It depends on the day"]

            VStack(spacing: 14) {
                ForEach(options, id: \.self) { o in
                    SelectableRow(
                        title: o,
                        selected: dailyLearningTime == o
                    ) {
                        dailyLearningTime = o
                    }
                }
            }
        }
    }

    // MARK: - Step 9

    private func Step9() -> some View {
        VStack(alignment: .leading, spacing: 24) {
            MascotGIF(url: mascotGIF(.determined), size: 175)
                .frame(maxWidth: .infinity)
            Text("That adds up fast.")
                .font(.dsTitle)
                .foregroundStyle(DS.Color.textPrimary)

            let daily = dailyScreenTime ?? 2.0
            let yearlyHours = Int(daily * 365)
            let entertainmentDays = max(1, yearlyHours / 24)
            let learningHoursDaily = learningHoursPerDay(dailyLearningTime)
            let gapHoursYear = max(0.0, daily - learningHoursDaily) * 365.0
            let learningDays = max(0, Int(gapHoursYear / 24.0))
            let nameDisplay = childName.isEmpty ? "Your child" : childName

            VStack(alignment: .leading, spacing: 16) {
                StatLine(
                    text: "\(nameDisplay) may spend ",
                    highlight: "\(yearlyHours) hours",
                    suffix: " on entertainment screens this year",
                    delay: 0.1
                )
                StatLine(
                    text: "that is about ",
                    highlight: "\(entertainmentDays) days",
                    delay: 0.7
                )
                StatLine(
                    text: "and ",
                    highlight: "\(learningDays) of those days",
                    suffix: " could have been spent learning and growing",
                    delay: 1.3
                )
            }
        }
    }

    private func learningHoursPerDay(_ id: String) -> Double {
        switch id {
        case "Less than 10 minutes": return 5.0 / 60.0
        case "10–20 minutes": return 15.0 / 60.0
        case "20–30 minutes": return 25.0 / 60.0
        case "30+ minutes": return 35.0 / 60.0
        case "It depends on the day": return 10.0 / 60.0
        default: return 10.0 / 60.0
        }
    }

    // MARK: - Step 10

    private func Step10() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Color.clear.frame(height: 20)
            Text("This is not just happening in your house.")
                .font(.system(size: 26, weight: .semibold, design: .rounded))
                .foregroundStyle(DS.Color.textPrimary)
            Text("Kids ages 5–8 average ")
                .font(.system(size: 26, weight: .semibold, design: .rounded))
            + Text("3.5 hours a day")
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(DS.Color.accent)
            + Text(" of screen media.")
                .font(.system(size: 26, weight: .semibold, design: .rounded))

            HStack(spacing: 10) {
                StatPill(value: "3.5", label: "hours daily")
                StatPill(value: "24+", label: "hours weekly")
                StatPill(value: "1.2k+", label: "hours yearly")
            }
            .padding(.top, 28)

            Text("Common Sense Media, 2025")
                .font(.dsCaption)
                .foregroundStyle(DS.Color.textSecondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 4)
        }
    }

    // MARK: - Step 11

    private func Step11() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("The moment before play matters.")
                .font(.dsTitle)
                .foregroundStyle(DS.Color.textPrimary)
            Text("Quick questions help kids practice focus, recall, and follow-through before the reward")
                .font(.dsBody)
                .foregroundStyle(DS.Color.textSecondary)

            RoundedImageCard(url: "https://pyikafpvphzqdadjvktz.supabase.co/storage/v1/object/public/Yoko/ability%20to%20focus%20and%20recall.png") {
                withAnimation(.easeIn(duration: 0.3)) { imageLoaded11 = true }
            }

            Link(destination: URL(string: "https://pmc.ncbi.nlm.nih.gov/articles/PMC4786565/")!) {
                Text("Based on research on retrieval practice and executive function")
                    .font(.dsCaption)
                    .foregroundStyle(DS.Color.textSecondary)
                    .underline()
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .opacity(imageLoaded11 ? 1 : 0)
            .animation(.easeIn(duration: 0.3), value: imageLoaded11)
        }
    }

    // MARK: - Step 12

    private func Step12() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Color.clear.frame(height: 20)
            FadeInText(text: "It doesn't have to be a fight", delay: 0.2)
                .font(.system(size: 32, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
            FadeInText(text: "\(childName.isEmpty ? "Your child" : childName) can still enjoy screen time with learning as the first step.", delay: 1.0)
                .font(.system(size: 32, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Step 13

    private func Step13() -> some View {
        VStack(spacing: 20) {
            Color.clear.frame(height: 0)
            RoundedImageCard(url: onboardingImage(.appBlockDemo), showBorder: false) {
                withAnimation(.easeIn(duration: 0.3)) { imageLoaded13 = true }
            }
            .overlay(
                Text("Choose any app")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)
                    .padding(.top, 86)
                    .opacity(imageLoaded13 ? 1 : 0)
                    .animation(.easeIn(duration: 0.3), value: imageLoaded13)
                , alignment: .top
            )
            .onTapGesture {
                nextStep()
            }
        }
        .padding(.top, -50)
    }

    // MARK: - Step 14

    private func Step14() -> some View {
        VStack(spacing: 24) {
            MascotGIF(
                url: "https://pyikafpvphzqdadjvktz.supabase.co/storage/v1/object/public/Yoko/GlassesGIF.gif",
                size: 198
            )
                .frame(maxWidth: .infinity)

            VStack(spacing: 10) {
                Text("app locked")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundStyle(DS.Color.textPrimary)

                Text("Let's demo the unlock flow so you can see what learning for \(childName.isEmpty ? "your child" : childName) will be like!")
                    .font(.system(size: 22, weight: .medium, design: .rounded))
                    .foregroundStyle(DS.Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 24)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 55)
    }

    // MARK: - Step 15-17 (rendered via demoQuestionScreen)

    private func Step15() -> some View { EmptyView() }
    private func Step16() -> some View { EmptyView() }
    private func Step17() -> some View { EmptyView() }

    private func demoNormalizedQuestion(for step: Int) -> NormalizedQuestion {
        switch step {
        // Q1 — Kindergarten counting: 12 frogs in 3×4 array — count or multiply.
        case 15: return CurriculumSystem.sampleMathQuestions[25]

        // Q2 — Grade 1 Make Ten: ten-frame with 7 filled orange dots.
        //      The most visually distinctive math component — shows parents
        //      this is a real learning tool, not just text questions.
        case 16: return CurriculumSystem.sampleMathQuestions[6]

        // Q3 — Grade 2 unscramble "monkey" 🐒: scrambled letter chips into word slots.
        case 17: return CurriculumSystem.sampleEnglishQuestions[30]

        default: return CurriculumSystem.sampleMathQuestions[20]
        }
    }

    private func demoQuestionSelectionBinding() -> Binding<String?> {
        switch step {
        case 15: return $q1
        case 16: return $q2
        case 17: return $q3
        default: return .constant(nil)
        }
    }

    @ViewBuilder
    private var demoQuestionScreen: some View {
        let normalized = demoNormalizedQuestion(for: step)
        let questionNum = step - 14
        DemoQuestionScreen(
            normalized: normalized,
            questionNum: questionNum,
            totalQuestions: 3,
            selected: demoQuestionSelectionBinding(),
            topBar: AnyView(topBar(tintWhite: true)),
            onContinue: nextStep,
            ctaLabel: questionNum < 3 ? "Next question →" : "Unlock app 🔓"
        )
        .id(step)
    }

    // MARK: - Step 18 (Streak)

    private func Step18() -> some View {
        VStack(spacing: 18) {
            Color.clear.frame(height: 0)
            MascotGIF(url: mascotGIF(.excited), size: 178)
                .frame(maxWidth: .infinity)

            Text("1")
                .font(.system(size: 80, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .padding(.top, -16)
            Text("day streak!")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .padding(.top, -10)

            HStack {
                ForEach(["M", "T", "W", "T", "F", "S", "S"], id: \.self) { day in
                    VStack(spacing: 8) {
                        Text(day)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(DS.Color.textSecondary)
                        ZStack {
                            Circle()
                                .fill(day == "W" ? DS.Color.accent : Color.white.opacity(0.5))
                                .frame(width: 38, height: 38)
                            if day == "W" {
                                Text("🔥")
                                    .font(.system(size: 20))
                            } else {
                                Circle()
                                    .fill(Color(red: 0.85, green: 0.85, blue: 0.85))
                                    .frame(width: 8, height: 8)
                            }
                        }
                    }
                }
            }
            .padding(22)
            .background(.white.opacity(0.42))
            .clipShape(.rect(cornerRadius: 28))
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(.white.opacity(0.55), lineWidth: 1)
            )
        }
    }

    // MARK: - Step 19 (Unlock Rule)

    private func Step19() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            MascotGIF(url: mascotGIF(.proud), size: 158)
                .frame(maxWidth: .infinity)
            Text("Set the Unlock Rule")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(DS.Color.textPrimary)

            let rules: [(id: String, label: String, desc: String, icon: String)] = [
                ("session", "3 questions = unlock this session", "Answer each time they want access", "🔄"),
                ("time", "3 questions = 30 minutes", "Earn screen time by learning", "⏱️"),
                ("daily", "3 questions = unlock for the day", "Answer once, unlock for the day", "📅")
            ]

            VStack(spacing: 10) {
                ForEach(rules, id: \.id) { r in
                    SelectableRow(
                        icon: r.icon,
                        title: r.label,
                        subtitle: r.desc,
                        titleFont: .system(size: 19, weight: .semibold, design: .rounded),
                        subtitleFont: .system(size: 14, weight: .regular, design: .rounded),
                        selected: unlockRule == r.id
                    ) {
                        unlockRule = r.id
                    }
                }
            }
        }
    }

    // MARK: - Step 20 (Creating Plan)

    private func Step20() -> some View {
        PlanCreationView(
            childName: childName.isEmpty ? "Your child" : childName,
            gradeText: gradeLabel(grade),
            ruleText: ruleLabel(unlockRule)
        )
    }

    // MARK: - Step 21 (Pre-paywall)

    private func Step21() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("You know what would help \(childName.isEmpty ? "your child" : childName)")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .lineSpacing(4)

            let _ = childName // keep reference
            let sections: [(tag: String, body: String?)] = [
                ("where you want to go", "📚 Learning before play becomes the routine"),
                ("where you are now", "📱 Screens are winning more time than practice"),
            ]

            VStack(spacing: 16) {
                ForEach(sections, id: \.tag) { s in
                    VStack(alignment: .leading, spacing: 14) {
                        Text(s.tag)
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundStyle(DS.Color.accent)
                            .textCase(.lowercase)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 7)
                            .background(DS.Color.accentSoft)
                            .clipShape(.capsule)

                        if let body = s.body {
                            Text(body)
                                .font(.system(size: 20, weight: .heavy, design: .rounded))
                                .foregroundStyle(DS.Color.textPrimary)
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(DS.Color.surface)
                    .clipShape(.rect(cornerRadius: 24))
                    .shadow(color: .black.opacity(0.08), radius: 14, y: 6)
                }

                VStack(alignment: .leading, spacing: 14) {
                    Text("what Yoko will help with")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(DS.Color.accent)
                        .textCase(.lowercase)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 7)
                        .background(DS.Color.accentSoft)
                        .clipShape(.capsule)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("🎮 Games and videos require learning first")
                        Text("🧠 Quick questions build daily practice")
                        Text("🔓 Play unlocks after effort")
                    }
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(DS.Color.textPrimary)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DS.Color.surface)
                .clipShape(.rect(cornerRadius: 24))
                .shadow(color: .black.opacity(0.08), radius: 14, y: 6)
            }
        }
    }

    // MARK: - Step 22 (Screen Time permission)

    private func Step22() -> some View {
        let nameDisplay = childName.isEmpty ? "your child" : childName
        return VStack(spacing: 22) {
            MascotGIF(url: mascotGIF(.determined), size: 149)
                .frame(maxWidth: .infinity)

            VStack(spacing: 10) {
                Text("Connect Yoko to screen time")
                    .font(.dsTitle)
                    .foregroundStyle(DS.Color.textPrimary)
                    .multilineTextAlignment(.center)
                Text("Yoko uses Apple Screen Time to pause \(nameDisplay)'s games and videos until learning is done.")
                    .font(.dsBody)
                    .foregroundStyle(DS.Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 8)

            VStack(spacing: 0) {
                permissionRow(
                    icon: "lock.fill",
                    title: "Lock distracting apps",
                    subtitle: "Games, videos and social stay paused"
                )
                Divider().padding(.leading, 60)
                permissionRow(
                    icon: "key.fill",
                    title: "Unlock by learning",
                    subtitle: "Play returns after questions are answered"
                )
                Divider().padding(.leading, 60)
                permissionRow(
                    icon: "hand.raised.fill",
                    title: "Private & on-device",
                    subtitle: "Apple keeps app choices private to this iPhone"
                )
            }
            .padding(.vertical, 6)
            .background(DS.Color.surface)
            .clipShape(.rect(cornerRadius: DS.Radius.large))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.large)
                    .stroke(DS.Color.border, lineWidth: 1)
            )

            if screenTime.isAuthorized {
                statusBanner(text: "Screen Time connected", icon: "checkmark.seal.fill", good: true)
            } else if screenTime.authorizationStatus == .denied {
                statusBanner(text: "Enable Screen Time in Settings to lock apps", icon: "exclamationmark.triangle.fill", good: false)
            }
        }
        .padding(.top, 12)
    }

    // MARK: - Step 23 (Notifications permission)

    private func Step23() -> some View {
        let nameDisplay = childName.isEmpty ? "your child" : childName
        return VStack(spacing: 22) {
            MascotGIF(url: mascotGIF(.proud), size: 149)
                .frame(maxWidth: .infinity)

            VStack(spacing: 10) {
                Text("Allow Yoko to send notifications")
                    .font(.dsTitle)
                    .foregroundStyle(DS.Color.textPrimary)
                    .multilineTextAlignment(.center)
                Text("We use this to allow \(nameDisplay) to unblock their apps when they need to learn.")
                    .font(.dsBody)
                    .foregroundStyle(DS.Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 8)

            VStack(spacing: 0) {
                permissionRow(
                    icon: "flame.fill",
                    title: "Streak reminders",
                    subtitle: "A nudge before the daily streak resets"
                )
                Divider().padding(.leading, 60)
                permissionRow(
                    icon: "bell.badge.fill",
                    title: "Practice time",
                    subtitle: "Friendly reminders to learn before play"
                )
                Divider().padding(.leading, 60)
                permissionRow(
                    icon: "star.fill",
                    title: "Celebrate wins",
                    subtitle: "Cheers when lessons and goals are hit"
                )
            }
            .padding(.vertical, 6)
            .background(DS.Color.surface)
            .clipShape(.rect(cornerRadius: DS.Radius.large))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.large)
                    .stroke(DS.Color.border, lineWidth: 1)
            )
        }
        .padding(.top, 12)
    }

    private func permissionRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(DS.Color.accent)
                .frame(width: 40, height: 40)
                .background(DS.Color.accentSoft)
                .clipShape(.rect(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.dsHeadline).foregroundStyle(DS.Color.textPrimary)
                Text(subtitle).font(.dsCaption).foregroundStyle(DS.Color.textSecondary)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func statusBanner(text: String, icon: String, good: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))
            Text(text)
                .font(.dsCaption)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
        .foregroundStyle(good ? DS.Color.success : DS.Color.danger)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background((good ? DS.Color.success : DS.Color.danger).opacity(0.1))
        .clipShape(.rect(cornerRadius: 14))
    }

    // MARK: - Helpers

    private func gradeLabel(_ id: String) -> String {
        switch id {
        case "kindergarten": return "Kindergarten"
        case "1st": return "1st Grade"
        case "2nd": return "2nd Grade"
        case "3rd": return "3rd Grade"
        case "4th": return "4th Grade"
        case "5th": return "5th Grade"
        default: return "—"
        }
    }

    private func ruleLabel(_ id: String) -> String {
        switch id {
        case "session": return "3 questions per session"
        case "time": return "3 questions = 30 minutes"
        case "daily": return "3 questions = all day"
        default: return "—"
        }
    }
}

// MARK: - Demo Question Full-Screen

struct DemoQuestionScreen: View {
    let normalized: NormalizedQuestion
    let questionNum: Int
    let totalQuestions: Int
    @Binding var selected: String?
    let topBar: AnyView
    let onContinue: () -> Void
    let ctaLabel: String

    @State private var keyGlow: Bool = false
    @State private var screenHeight: CGFloat = 852
    @State private var mascotMood: DemoMascotMood = .happy
    @State private var bgLoaded: Bool = false
    @State private var gifReady: Bool = false
    @State private var feedback: LessonPlayerView.Feedback = .none
    @State private var advanceTask: Task<Void, Never>?
    @State private var unscramble = UnscrambleState()

    enum DemoMascotMood { case happy, thinking, determined, excited, sad }

    private var question: Question {
        if let idx = normalized.answerChoices.firstIndex(of: normalized.correctAnswer) {
            return Question(
                prompt: normalized.prompt,
                kind: .multipleChoice(options: normalized.answerChoices, correctIndex: idx),
                normalized: normalized
            )
        }
        return Question(
            prompt: normalized.prompt,
            kind: .fillInBlank(answer: normalized.correctAnswer),
            normalized: normalized
        )
    }

    private var isCorrectPick: Bool {
        guard let sel = selected else { return false }
        return sel.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            == normalized.correctAnswer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private var mascotURL: String {
        let base = "https://pyikafpvphzqdadjvktz.supabase.co/storage/v1/object/public/Yoko"
        switch mascotMood {
        case .happy: return "\(base)/HappyGIF.gif"
        case .thinking: return "\(base)/ThinkingGIF.gif"
        case .determined: return "\(base)/DeterminedGIF.gif"
        case .excited: return "\(base)/ExcitedGIF.gif"
        case .sad: return "\(base)/SadGIF.gif"
        }
    }

    private var isReady: Bool { bgLoaded && gifReady }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.white.ignoresSafeArea()

                ZStack(alignment: .top) {
                    splitBackground

                    VStack(spacing: 0) {
                        // Reserve the same top spacing the lesson player uses so
                        // the mascot + content land at an identical position and
                        // the progress bar never pushes the hero down.
                        Color.clear.frame(height: screenHeight * 0.06)

                        MascotGIF(url: mascotURL, size: 162)
                            .padding(.top, -9)
                            .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)

                        contentArea
                    }

                    // Progress bar floats over the hero without affecting layout.
                    topBar
                }
                .opacity(isReady ? 1 : 0)

                if !isReady {
                    ProgressView()
                        .tint(DS.Color.accent)
                }
            }
            .onAppear { screenHeight = geo.size.height }
            .onChange(of: geo.size.height) { _, newValue in
                if abs(newValue - screenHeight) > 1 {
                    screenHeight = newValue
                }
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onAppear {
            mascotMood = initialMood()
            selected = nil
            feedback = .none
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                gifReady = true
            }
        }
        .onChange(of: selected) { _, newValue in
            guard let newValue, feedback == .none else { return }
            // If the user is recovering from a wrong answer, bring the mascot
            // back to thinking until the next evaluation lands.
            if mascotMood == .sad { mascotMood = .thinking }
            let template = normalized.templateType.snakeKey
            let buildTemplates: Set<String> = [
                "unscramble_word", "missing_letter", "fill_missing_letters",
                "missing_number_equation", "sentence_building", "sequencing"
            ]
            if buildTemplates.contains(template) {
                if newValue.replacingOccurrences(of: " ", with: "").count
                    >= normalized.correctAnswer.replacingOccurrences(of: " ", with: "").count {
                    evaluate()
                }
            } else {
                evaluate()
            }
        }
        .onDisappear { advanceTask?.cancel() }
    }

    private func initialMood() -> DemoMascotMood {
        switch questionNum {
        case 1: return .happy
        case 2: return .thinking
        case 3: return .determined
        default: return .happy
        }
    }

    private var splitBackground: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                AsyncImage(url: URL(string: "https://pyikafpvphzqdadjvktz.supabase.co/storage/v1/object/public/Yoko/UnlockScreen.png")) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                            .scaleEffect(1.05)
                            .offset(y: -54)
                            .onAppear {
                                withAnimation(.easeIn(duration: 0.25)) { bgLoaded = true }
                            }
                    } else {
                        Color(red: 0.35, green: 0.55, blue: 0.30)
                    }
                }
                .clipped()

                LinearGradient(
                    colors: [.clear, .white.opacity(0.95)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 110)
            }
            .frame(height: screenHeight * 0.50)

            Color.white.frame(maxHeight: .infinity)
        }
        .ignoresSafeArea()
    }

    private var contentArea: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical, showsIndicators: false) {
                QuestionRenderer(
                    question: question,
                    selectedAnswer: $selected,
                    feedback: feedback,
                    unscramble: unscramble
                )
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 8)
            }

            keyProgressRow
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                .padding(.top, 8)

            Divider()
                .background(DS.Color.border)

            bottomButton
                .padding(.horizontal, 24)
                .padding(.vertical, 18)
        }
        .background(Color.white)
        .clipShape(
            .rect(
                topLeadingRadius: 30,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 30
            )
        )
        .shadow(color: Color.black.opacity(0.04), radius: 16, x: 0, y: -4)
        .padding(.top, -13)
    }

    private func evaluate() {
        let correct = isCorrectPick
        withAnimation(.spring(duration: 0.35)) {
            feedback = correct ? .correct : .incorrect
        }
        mascotMood = correct ? .excited : .sad
        if correct {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            withAnimation(.spring(duration: 0.45, bounce: 0.3)) {
                keyGlow = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.spring(duration: 0.4)) { keyGlow = false }
            }
            // No auto-advance — user taps Continue manually.
        } else {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            // Unlock interaction so the user can retry, but keep the selection,
            // border, and sad mascot until they change their answer.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(duration: 0.3)) {
                    feedback = .none
                }
            }
        }
    }

    private var keyProgressRow: some View {
        HStack(spacing: 0) {
            if unscramble.active {
                UnscrambleBackButton(state: unscramble)
                Spacer(minLength: 4)
            }
            HStack(spacing: 16) {
                ForEach(0..<totalQuestions, id: \.self) { keyIndex in
                    keyCircle(for: keyIndex)
                }
            }
            if unscramble.active {
                Spacer(minLength: 4)
                UnscrambleHintButton(state: unscramble)
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.spring(duration: 0.3), value: unscramble.active)
    }

    @ViewBuilder
    private func keyCircle(for keyIndex: Int) -> some View {
        let isCompleted = keyIndex < (questionNum - 1)
        let isCurrent = keyIndex == (questionNum - 1)
        let isCorrectNow = isCurrent && feedback == .correct
        let isGlowing = isCurrent && keyGlow

        ZStack {
            Circle()
                .fill(isCompleted || isCorrectNow ? Color.white : Color(red: 0.94, green: 0.94, blue: 0.94))
                .frame(width: 46, height: 46)
                .overlay(
                    Circle()
                        .stroke(isCompleted || isCorrectNow ? DS.Color.accent : Color.clear, lineWidth: 2)
                )
                .shadow(
                    color: isGlowing ? DS.Color.accent.opacity(0.35) : Color.black.opacity(0.04),
                    radius: isGlowing ? 10 : 4,
                    x: 0,
                    y: isGlowing ? 4 : 2
                )

            Image(systemName: isCompleted || isCorrectNow ? "key.fill" : "key")
                .font(.system(size: isGlowing ? 28 : 22, weight: .heavy))
                .foregroundStyle(
                    isCompleted || isCorrectNow
                        ? DS.Color.accent
                        : DS.Color.textTertiary.opacity(0.35)
                )
                .scaleEffect(isGlowing ? 1.3 : 1.0)
        }
        .animation(.spring(duration: 0.45, bounce: 0.3), value: keyGlow)
        .animation(.spring(duration: 0.3), value: selected)
    }

    private var bottomButton: some View {
        let canContinue = feedback == .correct
        return Button(action: {
            if canContinue { onContinue() }
        }) {
            Text(canContinue ? ctaLabel : "Select an answer")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(canContinue ? DS.Color.accent : DS.Color.accent.opacity(0.28))
                .clipShape(.rect(cornerRadius: 18))
                .shadow(color: canContinue ? DS.Color.accent.opacity(0.25) : Color.clear, radius: 10, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(!canContinue)
        .scaleEffect(canContinue ? 1.0 : 0.97)
        .animation(.spring(duration: 0.3), value: canContinue)
    }
}

// MARK: - Plan Creation (Step 20)

struct PlanCreationView: View {
    let childName: String
    let gradeText: String
    let ruleText: String

    @State private var overallProgress: Double = 0
    @State private var displayedPercent: Int = 0
    @State private var rowProgress: [Double] = [0, 0, 0, 0]
    @State private var planMascotURL: String = mascotGIF(.thinking)

    private var rows: [(label: String, value: String)] {
        [
            ("Child", childName),
            ("Grade", gradeText),
            ("Practice", "Math + English"),
            ("Rule", ruleText)
        ]
    }

    private var gradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 1.0, green: 0.69, blue: 0.0), DS.Color.accent, Color(red: 1.0, green: 0.42, blue: 0.10)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    var body: some View {
        VStack(spacing: 22) {
            MascotGIF(url: planMascotURL, size: 158)
                .frame(maxWidth: .infinity)

            VStack(spacing: 6) {
                Text("Creating \(childName)'s plan")
                    .font(.dsTitle)
                    .foregroundStyle(DS.Color.textPrimary)
                Text("\(displayedPercent)%")
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundStyle(DS.Color.accent)
                    .contentTransition(.numericText())
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(red: 0.94, green: 0.94, blue: 0.94))
                    Capsule()
                        .fill(gradient)
                        .frame(width: max(0, geo.size.width * overallProgress))
                        .shadow(color: DS.Color.accent.opacity(0.35), radius: 8, y: 2)
                }
            }
            .frame(height: 10)

            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { idx, row in
                    PlanProgressRow(
                        label: row.label,
                        value: row.value,
                        progress: rowProgress[idx],
                        gradient: gradient
                    )
                    if idx < rows.count - 1 {
                        Divider().padding(.leading, 16)
                    }
                }
            }
            .padding(.vertical, 8)
            .background(DS.Color.surface)
            .clipShape(.rect(cornerRadius: 24))
            .shadow(color: .black.opacity(0.06), radius: 14, y: 6)
        }
        .onAppear { runAnimation() }
    }

    private func runAnimation() {
        withAnimation(.easeInOut(duration: 3.0)) {
            overallProgress = 1.0
        }
        let total = 60
        for step in 0...total {
            DispatchQueue.main.asyncAfter(deadline: .now() + (3.0 * Double(step) / Double(total))) {
                displayedPercent = Int(Double(step) / Double(total) * 100)
            }
        }
        for idx in 0..<rowProgress.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3 + Double(idx) * 0.55) {
                withAnimation(.easeInOut(duration: 0.7)) {
                    rowProgress[idx] = 1.0
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            planMascotURL = mascotGIF(.happy)
        }
    }
}

struct PlanProgressRow: View {
    let label: String
    let value: String
    let progress: Double
    let gradient: LinearGradient

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label.uppercased())
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(DS.Color.textSecondary)
                    .tracking(0.4)
                Spacer()
                Text(value)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(DS.Color.textPrimary)
                    .opacity(progress >= 1 ? 1 : 0.35)
                    .animation(.easeIn(duration: 0.3), value: progress)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(red: 0.94, green: 0.94, blue: 0.94))
                    Capsule()
                        .fill(gradient)
                        .frame(width: max(0, geo.size.width * progress))
                }
            }
            .frame(height: 4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Onboarding Demo Question (legacy, unused)

struct OnboardingDemoQuestion: View {
    let questionNum: Int
    let question: String
    let answers: [String]
    let correctIndex: Int
    @Binding var selected: Int?

    @State private var mascotURL: String
    @State private var keyGlow: Bool = false

    init(questionNum: Int, question: String, answers: [String], correctIndex: Int, selected: Binding<Int?>) {
        self.questionNum = questionNum
        self.question = question
        self.answers = answers
        self.correctIndex = correctIndex
        self._selected = selected
        switch questionNum {
        case 1: self._mascotURL = State(initialValue: mascotGIF(.happy))
        case 2: self._mascotURL = State(initialValue: mascotGIF(.thinking))
        case 3: self._mascotURL = State(initialValue: mascotGIF(.determined))
        default: self._mascotURL = State(initialValue: mascotGIF(.happy))
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            MascotGIF(url: mascotURL, size: 119)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)

            VStack(spacing: 20) {
                Text(question)
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundStyle(DS.Color.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 16)

                VStack(spacing: 10) {
                    ForEach(Array(answers.enumerated()), id: \.offset) { i, answer in
                        answerButton(i: i, answer: answer)
                    }
                }
                .padding(.horizontal, 4)

                keyProgress
                    .padding(.top, 16)
                    .padding(.bottom, 8)
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 16)
            .background(Color.white)
            .clipShape(.rect(cornerRadius: 30))
            .shadow(color: Color.black.opacity(0.04), radius: 16, x: 0, y: -4)
            .padding(.horizontal, 8)
            .padding(.top, 12)
        }
        .onChange(of: selected) { _, newValue in
            if let newValue {
                let isCorrect = newValue == correctIndex
                mascotURL = isCorrect ? mascotGIF(.excited) : mascotGIF(.sad)
                if isCorrect {
                    withAnimation(.spring(duration: 0.45, bounce: 0.3)) {
                        keyGlow = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        withAnimation(.spring(duration: 0.4)) {
                            keyGlow = false
                        }
                    }
                }
            }
        }
    }

    private func answerButton(i: Int, answer: String) -> some View {
        let isSelected = selected == i
        let showResult = selected != nil
        let isCorrect = i == correctIndex

        return Button {
            if selected == nil || (selected != nil && i != correctIndex) {
                selected = i
            }
        } label: {
            HStack {
                Text(answer)
                    .font(.dsHeadline)
                    .foregroundStyle(
                        showResult
                            ? (isSelected && isCorrect ? DS.Color.textPrimary
                               : isSelected && !isCorrect ? DS.Color.danger
                               : DS.Color.textPrimary)
                            : DS.Color.textPrimary
                    )
                Spacer()
                if showResult && isSelected {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(isCorrect ? DS.Color.accent : DS.Color.danger)
                        .font(.system(size: 22))
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                showResult
                    ? (isSelected && isCorrect ? Color(red: 0.996, green: 0.994, blue: 0.992)
                       : isSelected && !isCorrect ? Color(red: 1, green: 0.94, blue: 0.93)
                       : Color(red: 0.996, green: 0.994, blue: 0.992))
                    : Color(red: 0.996, green: 0.994, blue: 0.992)
            )
            .clipShape(.rect(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isSelected ? DS.Color.accent : Color.clear,
                        lineWidth: isSelected ? 2.5 : 0
                    )
            )
            .shadow(
                color: isSelected ? DS.Color.accent.opacity(0.22) : Color.black.opacity(0.04),
                radius: isSelected ? 10 : 4,
                x: 0,
                y: isSelected ? 3 : 1
            )
        }
        .buttonStyle(.plain)
    }

    private var keyProgress: some View {
        HStack(spacing: 16) {
            ForEach(0..<3, id: \.self) { keyIndex in
                let isCompleted = keyIndex < questionNum - 1
                let isCurrent = keyIndex == questionNum - 1
                let isCorrectNow = isCurrent && selected == correctIndex

                ZStack {
                    Circle()
                        .fill(isCompleted || isCorrectNow ? Color.white : Color(red: 0.94, green: 0.94, blue: 0.94))
                        .frame(width: 46, height: 46)
                        .overlay(
                            Circle()
                                .stroke(isCompleted || isCorrectNow ? DS.Color.accent : Color.clear, lineWidth: 2)
                        )
                        .shadow(
                            color: isCurrent && keyGlow ? DS.Color.accent.opacity(0.35) : Color.black.opacity(0.04),
                            radius: isCurrent && keyGlow ? 10 : 4,
                            x: 0,
                            y: 2
                        )

                    Image(systemName: isCompleted || isCorrectNow ? "key.fill" : "key")
                        .font(.system(size: isCurrent && keyGlow ? 28 : 22, weight: .heavy))
                        .foregroundStyle(
                            isCompleted || isCorrectNow
                                ? DS.Color.accent
                                : DS.Color.textTertiary.opacity(0.35)
                        )
                        .scaleEffect(isCurrent && keyGlow ? 1.3 : 1.0)
                }
                .animation(.spring(duration: 0.45, bounce: 0.3), value: keyGlow)
                .animation(.spring(duration: 0.3), value: selected)
            }
        }
    }
}

// MARK: - Reusable UI Components

struct PrimaryButton: View {
    let label: String
    let action: () -> Void
    var disabled: Bool = false
    var variant: Variant = .primary

    enum Variant { case primary, white }

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(variant == .white ? DS.Color.accent : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    disabled
                        ? (variant == .white ? Color.white.opacity(0.6) : DS.Color.accent.opacity(0.3))
                        : (variant == .white ? .white : DS.Color.accent)
                )
                .clipShape(.rect(cornerRadius: 18))
                .shadow(
                    color: disabled
                        ? Color.clear
                        : (variant == .white ? Color.black.opacity(0.1) : DS.Color.accent.opacity(0.25)),
                    radius: 10,
                    y: 4
                )
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .scaleEffect(disabled ? 0.98 : 1)
        .animation(.spring(duration: 0.25), value: disabled)
    }
}

struct SelectableRow: View {
    var icon: String? = nil
    let title: String
    var subtitle: String? = nil
    var titleFont: Font = .dsHeadline
    var subtitleFont: Font = .dsCaption
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                if let icon {
                    Text(icon)
                        .font(.system(size: 22))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(titleFont)
                        .foregroundStyle(DS.Color.textPrimary)
                    if let subtitle {
                        Text(subtitle)
                            .font(subtitleFont)
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                }
                Spacer()
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(DS.Color.accent)
                }
            }
            .frame(minHeight: 28)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DS.Color.surface)
            .clipShape(.rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(selected ? DS.Color.accent : Color.clear, lineWidth: 2)
            )
            .shadow(
                color: selected ? DS.Color.accent.opacity(0.18) : Color.black.opacity(0.08),
                radius: selected ? 10 : 8,
                y: selected ? 4 : 3
            )
        }
        .buttonStyle(.plain)
    }
}

struct RoundedImageCard: View {
    let url: String
    var showBorder: Bool = true
    var onLoaded: (() -> Void)? = nil
    @State private var loaded = false

    var body: some View {
        AsyncImage(url: URL(string: url)) { phase in
            if let image = phase.image {
                image
                    .resizable()
                    .scaledToFit()
                    .clipShape(.rect(cornerRadius: 24))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(showBorder ? DS.Color.accent : Color.clear, lineWidth: 3)
                    )
                    .shadow(color: showBorder ? DS.Color.accent.opacity(0.2) : Color.black.opacity(0.08), radius: 14, x: 0, y: 6)
                    .onAppear {
                        withAnimation(.easeIn(duration: 0.3)) {
                            loaded = true
                            onLoaded?()
                        }
                    }
            } else {
                Color.clear.frame(height: 0)
            }
        }
        .frame(maxWidth: .infinity)
        .opacity(loaded ? 1 : 0)
    }
}

struct MascotGIF: View {
    let url: String
    let size: CGFloat

    var body: some View {
        AnimatedGIFView(urlString: url)
            .frame(width: size, height: size)
    }
}

struct mascotBubble: View {
    let text: String

    var body: some View {
        VStack(spacing: 0) {
            Text(text)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(DS.Color.textPrimary)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(.white)
                .clipShape(.rect(cornerRadius: 20))
                .shadow(color: .black.opacity(0.1), radius: 10, y: 4)

            Triangle()
                .fill(.white)
                .frame(width: 26, height: 18)
                .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

struct StatLine: View {
    let text: String
    let highlight: String
    var suffix: String? = nil
    var delay: Double = 0
    @State private var opacity: Double = 0

    var body: some View {
        (Text(text)
            .font(.system(size: 22, weight: .medium, design: .rounded))
        + Text(highlight)
            .font(.system(size: 22, weight: .heavy, design: .rounded))
            .foregroundStyle(DS.Color.accent)
        + Text(suffix ?? "")
            .font(.system(size: 22, weight: .medium, design: .rounded)))
        .foregroundStyle(DS.Color.textPrimary)
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeIn(duration: 0.6).delay(delay)) {
                opacity = 1
            }
        }
    }
}

struct StatPill: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(DS.Color.accent)
            Text(label)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(DS.Color.textPrimary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .background(DS.Color.accentSoft)
        .clipShape(.rect(cornerRadius: 18))
    }
}

struct PlanRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label.uppercased())
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(DS.Color.textSecondary)
                .tracking(0.4)
            Spacer()
            Text(value)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(DS.Color.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

struct FadeInText: View {
    let text: String
    var delay: Double = 0.3
    @State private var opacity: Double = 0

    var body: some View {
        Text(text)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeIn(duration: 0.8).delay(delay)) {
                    opacity = 1
                }
            }
    }
}

// MARK: - GIF Helpers

private func mascotGIF(_ mood: MascotMood) -> String {
    let base = "https://pyikafpvphzqdadjvktz.supabase.co/storage/v1/object/public/Yoko"
    switch mood {
    case .happy: return "\(base)/HappyGIF.gif"
    case .thinking: return "\(base)/ThinkingGIF.gif"
    case .determined: return "\(base)/DeterminedGIF.gif"
    case .sad: return "\(base)/SadGIF.gif"
    case .excited: return "\(base)/ExcitedGIF.gif"
    case .proud: return "\(base)/ProudGIF.gif"
    }
}

private func onboardingImage(_ name: OnboardingImage) -> String {
    let base = "https://pyikafpvphzqdadjvktz.supabase.co/storage/v1/object/public/Yoko"
    switch name {
    case .lookingAtIpad: return "\(base)/LookingatIPAD.png"
    case .behindPov: return "\(base)/BehindPOV.png"
    case .appBlockDemo: return "\(base)/AppBlockDemo.png"
    case .learningStatistic: return "\(base)/Learning%20statistic.png"
    }
}

private enum MascotMood { case happy, thinking, determined, sad, excited, proud }
private enum OnboardingImage { case lookingAtIpad, behindPov, appBlockDemo, learningStatistic }

// MARK: - Commitment Step

/// Final onboarding step: the parent signs a commitment and presses-and-holds a
/// fingerprint that expands into a screen-filling circle to confirm. The
/// expanding circle is the only CTA — there is no separate button.
struct CommitmentScreen: View {
    let childName: String
    let onBack: () -> Void
    let onComplete: () -> Void

    @State private var strokes: [[CGPoint]] = []
    @State private var currentStroke: [CGPoint] = []
    @State private var fillProgress: CGFloat = 0
    @State private var holdTask: Task<Void, Never>? = nil
    @State private var completed: Bool = false
    @State private var pulse: Bool = false

    private var hasSignature: Bool { !strokes.isEmpty || currentStroke.count > 2 }

    private var possessive: String {
        let name = childName.trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? "your child's" : "\(name)'s"
    }

    private var childDisplay: String {
        let name = childName.trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? "your child" : name
    }

    var body: some View {
        GeometryReader { geo in
            let thumbCenter = CGPoint(x: geo.size.width / 2, y: geo.size.height - 132)
            let coverScale = (2 * hypot(geo.size.width, geo.size.height)) / 96 + 1

            ZStack {
                DS.Color.background.ignoresSafeArea()

                // Warm glow behind the fingerprint that intensifies as the parent holds.
                RadialGradient(
                    colors: [DS.Color.accent.opacity(0.16 + fillProgress * 0.28), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 230
                )
                .frame(width: 460, height: 460)
                .position(thumbCenter)
                .allowsHitTesting(false)
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    topBar

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 18) {
                            MascotGIF(url: mascotGIF(.proud), size: 122)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 2)

                            Text("the parent promise")
                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                                .foregroundStyle(DS.Color.accent)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 7)
                                .background(DS.Color.accentSoft)
                                .clipShape(.capsule)

                            Text("Commit to putting \(possessive) education first")
                                .font(.system(size: 28, weight: .heavy, design: .rounded))
                                .foregroundStyle(DS.Color.textPrimary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(3)

                            Text("Sign below as your promise to help \(childDisplay) learn a little every day.")
                                .font(.dsBody)
                                .foregroundStyle(DS.Color.textSecondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                                .padding(.horizontal, 8)

                            signatureCard
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 4)
                        .padding(.bottom, 280)
                    }
                }

                // Hold-to-commit fingerprint, pinned above the bottom edge.
                thumbLabel
                    .position(x: thumbCenter.x, y: thumbCenter.y - 82)
                    .opacity(completed ? 0 : 1)

                thumbButton
                    .position(thumbCenter)

                // The expanding circle that fills the screen as the hold completes.
                Circle()
                    .fill(DS.Color.accent)
                    .frame(width: 96, height: 96)
                    .scaleEffect(max(0.001, fillProgress * coverScale), anchor: .center)
                    .position(thumbCenter)
                    .opacity(fillProgress > 0.001 ? 1 : 0)
                    .allowsHitTesting(false)

                if completed {
                    VStack(spacing: 18) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 72, weight: .bold))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
                        VStack(spacing: 6) {
                            Text("Promise made")
                                .font(.system(size: 28, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                            Text("Let's help \(childDisplay) learn every day")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.92))
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, 32)
                    .transition(.scale(scale: 0.7).combined(with: .opacity))
                    .allowsHitTesting(false)
                }
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
        .onDisappear { holdTask?.cancel() }
    }

    private var topBar: some View {
        HStack(spacing: 0) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(DS.Color.textPrimary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .opacity(completed ? 0 : 1)

            ProgressView(value: 1, total: 1)
                .tint(DS.Color.accent)
                .frame(height: 4)
                .frame(maxWidth: 280)

            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
    }

    private var signatureCard: some View {
        VStack(spacing: 12) {
            ZStack {
                Canvas { context, _ in
                    for stroke in strokes + [currentStroke] {
                        guard stroke.count > 1 else { continue }
                        var path = Path()
                        path.move(to: stroke[0])
                        for point in stroke.dropFirst() { path.addLine(to: point) }
                        context.stroke(
                            path,
                            with: .color(DS.Color.textPrimary),
                            style: StrokeStyle(lineWidth: 2.8, lineCap: .round, lineJoin: .round)
                        )
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in currentStroke.append(value.location) }
                        .onEnded { _ in
                            if currentStroke.count > 1 { strokes.append(currentStroke) }
                            currentStroke = []
                        }
                )

                if !hasSignature {
                    Text("Sign here")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(DS.Color.textTertiary)
                        .allowsHitTesting(false)
                }

                VStack {
                    Spacer()
                    HStack(spacing: 10) {
                        Text("✕")
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .foregroundStyle(DS.Color.textTertiary)
                        Rectangle()
                            .fill(DS.Color.border)
                            .frame(height: 1.5)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 34)
                    .allowsHitTesting(false)
                }
            }
            .frame(height: 200)
            .background(DS.Color.surface)
            .clipShape(.rect(cornerRadius: DS.Radius.large))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.large)
                    .stroke(DS.Color.border, lineWidth: 1)
            )

            HStack(spacing: 8) {
                Image(systemName: "signature")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DS.Color.textTertiary)
                Text("Parent signature")
                    .font(.dsCaption)
                    .foregroundStyle(DS.Color.textTertiary)
                Spacer()
                if hasSignature {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(duration: 0.3)) {
                            strokes = []
                            currentStroke = []
                        }
                    } label: {
                        Text("Clear")
                            .font(.dsCaption)
                            .foregroundStyle(DS.Color.accent)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private var thumbLabel: some View {
        VStack(spacing: 3) {
            Text(holdTask != nil ? "Keep holding…" : "Tap and hold")
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundStyle(hasSignature ? DS.Color.accent : DS.Color.textTertiary)
                .contentTransition(.opacity)
            if !hasSignature {
                Text("Sign first to confirm")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(DS.Color.textTertiary)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: holdTask != nil)
    }

    private var accentGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 1.0, green: 0.69, blue: 0.0), DS.Color.accent, Color(red: 1.0, green: 0.42, blue: 0.10)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var thumbButton: some View {
        ZStack {
            if hasSignature && !completed {
                Circle()
                    .stroke(DS.Color.accent.opacity(0.35), lineWidth: 2)
                    .frame(width: 104, height: 104)
                    .scaleEffect(pulse ? 1.2 : 1)
                    .opacity(pulse ? 0 : 0.8)
            }

            Circle()
                .fill(hasSignature ? DS.Color.accentSoft : DS.Color.surface)
                .frame(width: 92, height: 92)
                .overlay(
                    Circle().stroke(hasSignature ? DS.Color.accent.opacity(0.4) : DS.Color.border, lineWidth: 2)
                )
                .overlay(
                    Image(systemName: "touchid")
                        .font(.system(size: 42, weight: .regular))
                        .foregroundStyle(hasSignature ? DS.Color.accent : DS.Color.textTertiary)
                )
                .scaleEffect(holdTask != nil ? 0.9 : 1)
                .animation(.spring(duration: 0.3), value: holdTask != nil)

            // Progress ring fills around the fingerprint as the parent holds.
            Circle()
                .trim(from: 0, to: fillProgress)
                .stroke(accentGradient, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .frame(width: 96, height: 96)
                .rotationEffect(.degrees(-90))
                .opacity(holdTask != nil ? 1 : 0)
                .shadow(color: DS.Color.accent.opacity(0.4), radius: 6)
        }
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in startHold() }
                .onEnded { _ in cancelHold() }
        )
        .disabled(!hasSignature || completed)
    }

    private func startHold() {
        guard hasSignature, holdTask == nil, !completed else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        holdTask = Task { @MainActor in
            let total: Double = 1.5
            let tick: Double = 0.016
            let increment = CGFloat(tick / total)
            var lastHaptic: CGFloat = 0
            while fillProgress < 1 {
                if Task.isCancelled { return }
                fillProgress = min(1, fillProgress + increment)
                if fillProgress - lastHaptic >= 0.12 {
                    lastHaptic = fillProgress
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: fillProgress)
                }
                try? await Task.sleep(for: .seconds(tick))
            }
            if !Task.isCancelled { await complete() }
        }
    }

    private func cancelHold() {
        holdTask?.cancel()
        holdTask = nil
        if !completed {
            withAnimation(.spring(duration: 0.5)) { fillProgress = 0 }
        }
    }

    @MainActor
    private func complete() async {
        holdTask = nil
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.easeOut(duration: 0.3)) { completed = true }
        try? await Task.sleep(for: .seconds(0.85))
        onComplete()
    }
}

