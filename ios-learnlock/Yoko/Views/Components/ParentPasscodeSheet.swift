//
//  ParentPasscodeSheet.swift
//  Yoko
//
//  A reusable 4-digit passcode sheet used both to SET a new parent passcode
//  (Settings) and to VERIFY it before any lock-changing action (Locks tab).
//

import SwiftUI

enum PasscodeMode {
    /// Create a new passcode (enter twice to confirm).
    case set
    /// Verify against an existing passcode.
    case verify
}

struct ParentPasscodeSheet: View {
    @Environment(\.dismiss) private var dismiss

    let mode: PasscodeMode
    /// The stored passcode to check against in `.verify` mode.
    var existing: String? = nil
    /// Called with the verified / newly created passcode on success.
    let onSuccess: (String) -> Void
    /// Called when the parent cancels without succeeding.
    var onCancel: (() -> Void)? = nil

    private let length = 4

    @State private var entry: String = ""
    @State private var firstEntry: String? = nil
    @State private var error: String = ""
    @State private var shake: Bool = false
    @State private var didSucceed: Bool = false

    var body: some View {
        VStack(spacing: 28) {
            grabber

            VStack(spacing: 10) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(DS.Color.accent)
                Text(title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(DS.Color.textPrimary)
                Text(subtitle)
                    .font(.dsCallout)
                    .foregroundStyle(DS.Color.textSecondary)
                    .multilineTextAlignment(.center)
            }

            dots
                .offset(x: shake ? -10 : 0)

            if !error.isEmpty {
                Text(error)
                    .font(.dsCaption)
                    .foregroundStyle(DS.Color.danger)
                    .transition(.opacity)
            }

            keypad

            Button("Cancel") {
                onCancel?()
                dismiss()
            }
            .font(.dsHeadline)
            .foregroundStyle(DS.Color.textSecondary)
        }
        .padding(.horizontal, 28)
        .padding(.top, 14)
        .padding(.bottom, 28)
        .presentationDetents([.height(560)])
        .presentationDragIndicator(.hidden)
        .interactiveDismissDisabled(false)
        .onDisappear {
            if !didSucceed { onCancel?() }
        }
    }

    private var grabber: some View {
        Capsule()
            .fill(DS.Color.border)
            .frame(width: 40, height: 5)
    }

    private var title: String {
        switch mode {
        case .verify: return "Enter Passcode"
        case .set: return firstEntry == nil ? "Create a Passcode" : "Confirm Passcode"
        }
    }

    private var subtitle: String {
        switch mode {
        case .verify: return "Enter your passcode to change lock settings."
        case .set: return firstEntry == nil
            ? "Set a 4-digit passcode to protect lock settings."
            : "Re-enter your passcode to confirm."
        }
    }

    private var dots: some View {
        HStack(spacing: 22) {
            ForEach(0..<length, id: \.self) { i in
                Circle()
                    .strokeBorder(DS.Color.accent, lineWidth: 2)
                    .background(
                        Circle().fill(i < entry.count ? DS.Color.accent : Color.clear)
                    )
                    .frame(width: 18, height: 18)
            }
        }
    }

    private var keypad: some View {
        VStack(spacing: 16) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 26) {
                    ForEach(1..<4, id: \.self) { col in
                        let digit = row * 3 + col
                        digitButton("\(digit)")
                    }
                }
            }
            HStack(spacing: 26) {
                Color.clear.frame(width: 72, height: 72)
                digitButton("0")
                deleteButton
            }
        }
    }

    private func digitButton(_ d: String) -> some View {
        Button {
            append(d)
        } label: {
            Text(d)
                .font(.system(size: 30, weight: .medium, design: .rounded))
                .foregroundStyle(DS.Color.textPrimary)
                .frame(width: 72, height: 72)
                .background(DS.Color.surface)
                .clipShape(Circle())
                .overlay(Circle().stroke(DS.Color.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var deleteButton: some View {
        Button {
            if !entry.isEmpty {
                entry.removeLast()
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        } label: {
            Image(systemName: "delete.left")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(DS.Color.textSecondary)
                .frame(width: 72, height: 72)
        }
        .buttonStyle(.plain)
    }

    private func append(_ d: String) {
        guard entry.count < length else { return }
        error = ""
        entry.append(d)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if entry.count == length {
            submit()
        }
    }

    private func submit() {
        switch mode {
        case .verify:
            if entry == existing {
                succeed(with: entry)
            } else {
                fail("Incorrect passcode")
            }
        case .set:
            if let first = firstEntry {
                if entry == first {
                    succeed(with: entry)
                } else {
                    firstEntry = nil
                    fail("Passcodes didn't match")
                }
            } else {
                firstEntry = entry
                withAnimation(.easeIn(duration: 0.15)) { entry = "" }
            }
        }
    }

    private func succeed(with code: String) {
        didSucceed = true
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        onSuccess(code)
        dismiss()
    }

    private func fail(_ message: String) {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        withAnimation(.easeInOut(duration: 0.08).repeatCount(3, autoreverses: true)) {
            shake = true
        }
        withAnimation(.default) { error = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            shake = false
            entry = ""
        }
    }
}
