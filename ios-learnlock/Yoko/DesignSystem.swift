//
//  DesignSystem.swift
//  Yoko
//

import SwiftUI

enum DS {
    enum Color {
        static let background = SwiftUI.Color(red: 0.980, green: 0.980, blue: 0.972)   // #FAFAF8
        static let surface = SwiftUI.Color.white                                        // #FFFFFF
        static let surfaceWarm = SwiftUI.Color(red: 0.976, green: 0.969, blue: 0.957)   // soft warm card
        static let accent = SwiftUI.Color(red: 1.000, green: 0.478, blue: 0.000)        // #FF7A00
        static let accentSoft = SwiftUI.Color(red: 1.000, green: 0.957, blue: 0.910)    // accent 8%
        static let accentMid  = SwiftUI.Color(red: 1.000, green: 0.871, blue: 0.733)    // accent 25%
        // Warm orange → cream brand gradient (used by the App Usage card & segmented control).
        static let brandGradientStart = SwiftUI.Color(red: 1.000, green: 0.478, blue: 0.000) // warm orange #FF7A00
        static let brandGradientEnd   = SwiftUI.Color(red: 1.000, green: 0.925, blue: 0.831) // cream #FFECD4
        static let textPrimary = SwiftUI.Color(red: 0.122, green: 0.122, blue: 0.122)   // #1F1F1F
        static let textSecondary = SwiftUI.Color(red: 0.420, green: 0.420, blue: 0.420) // #6B6B6B
        static let textTertiary = SwiftUI.Color(red: 0.620, green: 0.620, blue: 0.620)
        static let border = SwiftUI.Color(red: 0.925, green: 0.925, blue: 0.925)        // #ECECEC
        static let success = SwiftUI.Color(red: 0.149, green: 0.659, blue: 0.420)
        static let danger = SwiftUI.Color(red: 0.886, green: 0.302, blue: 0.227)
    }

    enum Radius {
        static let small: CGFloat = 10
        static let medium: CGFloat = 16
        static let large: CGFloat = 22
        static let xlarge: CGFloat = 28
    }

    enum Spacing {
        static let xs: CGFloat = 6
        static let s: CGFloat = 10
        static let m: CGFloat = 16
        static let l: CGFloat = 22
        static let xl: CGFloat = 32
    }
}

// MARK: - Typography

extension Font {
    static let dsDisplay = Font.system(size: 34, weight: .bold, design: .rounded)
    static let dsTitle = Font.system(size: 26, weight: .bold, design: .rounded)
    static let dsTitle2 = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let dsHeadline = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let dsBody = Font.system(size: 16, weight: .regular, design: .rounded)
    static let dsCallout = Font.system(size: 15, weight: .medium, design: .rounded)
    static let dsCaption = Font.system(size: 13, weight: .medium, design: .rounded)
    static let dsTiny = Font.system(size: 11, weight: .semibold, design: .rounded)
}

// MARK: - Card modifier

struct DSCard: ViewModifier {
    var padding: CGFloat = 18
    var radius: CGFloat = DS.Radius.large
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(DS.Color.surface)
            .clipShape(.rect(cornerRadius: radius))
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(DS.Color.border, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 6)
    }
}

extension View {
    func dsCard(padding: CGFloat = 18, radius: CGFloat = DS.Radius.large) -> some View {
        modifier(DSCard(padding: padding, radius: radius))
    }

    func dsScreenBackground() -> some View {
        background(DS.Color.background.ignoresSafeArea())
    }
}

// MARK: - iPad layout scaling

/// Scales and centers a screen's content on iPad so text, GIFs, cards and other
/// content read larger and sit in a comfortable centered column — while leaving
/// iPhone layouts completely untouched (the modifier is a no-op on iPhone).
///
/// The existing iPhone layout is rendered at `baseWidth` (a typical large-phone
/// width) and then uniformly scaled up, so every proportion matches the phone
/// exactly. `background` fills the side margins; pass a view matching the
/// screen's own backdrop so the margins blend seamlessly (vertical gradients and
/// solid colors extend perfectly).
struct IPadScaledLayout<Background: View>: ViewModifier {
    var baseWidth: CGFloat
    var maxScale: CGFloat
    @ViewBuilder var background: () -> Background

    func body(content: Content) -> some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            ZStack {
                background().ignoresSafeArea()
                GeometryReader { proxy in
                    let scale = min(maxScale, max(1, proxy.size.width / baseWidth))
                    content
                        .frame(width: baseWidth, height: proxy.size.height / scale)
                        .scaleEffect(scale)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                }
            }
        } else {
            content
        }
    }
}

extension View {
    /// iPad scaling with an explicit margin background — pass the screen's own
    /// backdrop so the centered column blends into the side margins.
    func iPadScaled<Background: View>(
        baseWidth: CGFloat = 430,
        maxScale: CGFloat = 1.6,
        @ViewBuilder background: @escaping () -> Background
    ) -> some View {
        modifier(IPadScaledLayout(baseWidth: baseWidth, maxScale: maxScale, background: background))
    }

    /// iPad scaling that relies on a full-bleed background already sitting behind
    /// the content (margins show whatever is already there).
    func iPadScaled(baseWidth: CGFloat = 430, maxScale: CGFloat = 1.6) -> some View {
        modifier(IPadScaledLayout(baseWidth: baseWidth, maxScale: maxScale) { Color.clear })
    }
}

// MARK: - Buttons

struct DSPrimaryButtonStyle: ButtonStyle {
    var fullWidth: Bool = true
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.dsHeadline)
            .foregroundStyle(.white)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.vertical, 16)
            .padding(.horizontal, 22)
            .background(DS.Color.accent)
            .clipShape(.rect(cornerRadius: 16))
            .shadow(color: DS.Color.accent.opacity(0.25), radius: 14, y: 8)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(duration: 0.25), value: configuration.isPressed)
    }
}

struct DSSecondaryButtonStyle: ButtonStyle {
    var fullWidth: Bool = true
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.dsHeadline)
            .foregroundStyle(DS.Color.textPrimary)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.vertical, 16)
            .padding(.horizontal, 22)
            .background(DS.Color.surface)
            .clipShape(.rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(DS.Color.border, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(duration: 0.25), value: configuration.isPressed)
    }
}

struct DSChipStyle: ButtonStyle {
    var selected: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.dsCaption)
            .foregroundStyle(selected ? .white : DS.Color.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(selected ? DS.Color.accent : DS.Color.surface)
            .clipShape(.capsule)
            .overlay(
                Capsule().stroke(selected ? Color.clear : DS.Color.border, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}
