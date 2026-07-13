//
//  AppUsageCard.swift
//  Yoko
//
//  Read-only "App Usage" card for the Home tab. The card chrome (title +
//  Today/This Week segmented control) lives here in the app; the actual usage
//  rows are rendered by the AppUsageReportExtension via `DeviceActivityReport`.
//
//  This is purely visual: no usage numbers are persisted, logged, sent to a
//  server, or used in any locking logic. The segmented control drives the
//  report's filter (the extension is sandboxed and only renders the data the
//  system hands it for the chosen filter).
//

import SwiftUI
import FamilyControls
import ManagedSettings
import DeviceActivity

struct AppUsageCard: View {
    @Environment(AppStore.self) private var store
    @Environment(ScreenTimeService.self) private var screenTime

    /// Timeframe options for the segmented control.
    enum Timeframe: String, CaseIterable, Identifiable {
        case today = "Today"
        case thisWeek = "This Week"
        var id: String { rawValue }
    }

    @State private var selectedTimeframe: Timeframe = .today

    /// Must match the context implemented by the report extension's scene.
    private let context = DeviceActivityReport.Context(rawValue: "TopAppsUsage")

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            segmentedControl
            content
        }
        .padding(18)
        .background(DS.Color.surface)
        .clipShape(.rect(cornerRadius: DS.Radius.large))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.large)
                .stroke(DS.Color.border, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 6)
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "hourglass")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(DS.Color.accent)
            Text("App Usage")
                .font(.dsTitle2)
                .foregroundStyle(DS.Color.textPrimary)
            Spacer()
        }
    }

    // MARK: Segmented control

    private var segmentedControl: some View {
        HStack(spacing: 6) {
            ForEach(Timeframe.allCases) { tf in
                let selected = selectedTimeframe == tf
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                        selectedTimeframe = tf
                    }
                } label: {
                    Text(tf.rawValue)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(selected ? .white : DS.Color.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(selected ? DS.Color.accent : DS.Color.surface)
                        .clipShape(.capsule)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(DS.Color.surface)
        .clipShape(.capsule)
        .overlay(
            Capsule().stroke(DS.Color.border, lineWidth: 1)
        )
    }

    // MARK: Content

    @ViewBuilder
    private var content: some View {
        if screenTime.isAuthorized {
            if store.demoDataActive {
                MockUsageRows(selectedTimeframe: selectedTimeframe)
            } else {
                DeviceActivityReport(context, filter: filter)
                    .frame(height: 196)
            }
        } else if store.demoDataActive {
            MockUsageRows(selectedTimeframe: selectedTimeframe)
        } else {
            unauthorizedPlaceholder
        }
    }

    private var unauthorizedPlaceholder: some View {
        VStack(spacing: 10) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(DS.Color.accent.opacity(0.7))
            Text("Connect Screen Time to see app usage")
                .font(.dsCaption)
                .foregroundStyle(DS.Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 26)
    }

    // MARK: Filter

    /// Reuses the same app selection persisted for the Active Locks feature.
    private var filter: DeviceActivityFilter {
        let calendar = Calendar.current
        let now = Date()
        let apps = screenTime.selection.applicationTokens

        switch selectedTimeframe {
        case .today:
            let interval = calendar.dateInterval(of: .day, for: now)
                ?? DateInterval(start: calendar.startOfDay(for: now), duration: 86_400)
            return DeviceActivityFilter(
                segment: .daily(during: interval),
                users: .all,
                devices: .init([.iPhone, .iPad]),
                applications: apps
            )
        case .thisWeek:
            let interval = calendar.dateInterval(of: .weekOfYear, for: now)
                ?? DateInterval(start: now, duration: 7 * 86_400)
            return DeviceActivityFilter(
                segment: .weekly(during: interval),
                users: .all,
                devices: .init([.iPhone, .iPad]),
                applications: apps
            )
        }
    }
}

// MARK: - Demo mock usage (App Store screenshots)

/// Only shown when `store.demoDataActive` is true. Renders realistic-looking
/// screen-time rows so the App Usage card looks populated in screenshots.
private struct MockUsageRows: View {
    let selectedTimeframe: AppUsageCard.Timeframe

    /// Ordered by duration, descending. Minutes value used for fill calculation.
    private var entries: [(name: String, duration: String, minutes: Int)] {
        switch selectedTimeframe {
        case .today:
            return [
                ("YouTube", "2h 15m", 135),
                ("Roblox",   "1h 30m", 90),
                ("TikTok",   "45m", 45),
                ("Other",    "30m", 30),
            ]
        case .thisWeek:
            return [
                ("YouTube", "12h 30m", 750),
                ("Roblox",   "8h 15m", 495),
                ("TikTok",   "5h 45m", 345),
                ("Other",    "3h 20m", 200),
            ]
        }
    }

    private var maxMinutes: Int {
        entries.map(\.minutes).max() ?? 1
    }

    var body: some View {
        VStack(spacing: 10) {
            ForEach(entries.indices, id: \.self) { i in
                let entry = entries[i]
                let fillPercent = Double(entry.minutes) / Double(maxMinutes)
                HStack(spacing: 12) {
                    leadingIcon(for: entry.name)

                    Text(entry.name)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(DS.Color.textPrimary)

                    Spacer()

                    Text(entry.duration)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(DS.Color.textSecondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .padding(.top, i == 0 ? 12 : 0)
                .background(
                    GeometryReader { geo in
                        DS.Color.accent.opacity(0.15)
                            .frame(width: geo.size.width * fillPercent)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                )
                .clipShape(.rect(cornerRadius: 12))
            }
        }
    }

    @ViewBuilder
    private func leadingIcon(for name: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 9)
                .fill(appColor(name).opacity(0.18))
                .frame(width: 34, height: 34)

            if name == "Other" {
                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(DS.Color.textSecondary)
            } else {
                Text(String(name.prefix(1)))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(appColor(name))
            }
        }
    }

    private func appColor(_ name: String) -> Color {
        switch name {
        case "YouTube": return .red
        case "Roblox":  return .blue
        case "TikTok":  return DS.Color.textPrimary
        default:        return DS.Color.accent
        }
    }
}
