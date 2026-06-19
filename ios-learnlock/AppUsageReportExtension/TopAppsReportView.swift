//
//  TopAppsReportView.swift
//  AppUsageReportExtension
//
//  The SwiftUI view rendered inside the App Usage card. Styled with Yoko's
//  brand (warm orange → cream, charcoal text) rather than the generic system
//  look. The extension can't import the app module, so the brand tokens are
//  mirrored locally in `ReportStyle` (kept in sync with DS in DesignSystem.swift).
//

import FamilyControls
import ManagedSettings
import SwiftUI

/// View-model for a single render of the report.
struct AppUsageConfiguration {
    var rows: [AppUsageRow] = []
}

/// One app row (or the grouped "Other" bucket when `token` is nil).
struct AppUsageRow: Identifiable {
    let id = UUID()
    let token: ApplicationToken?
    let name: String
    let duration: TimeInterval
    let isOther: Bool
}

struct TopAppsReportView: View {
    let configuration: AppUsageConfiguration

    var body: some View {
        if configuration.rows.isEmpty {
            emptyState
        } else {
            VStack(spacing: 10) {
                ForEach(configuration.rows) { row in
                    AppUsageRowView(row: row)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(ReportStyle.orange.opacity(0.65))
            Text("No usage yet")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(ReportStyle.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }
}

private struct AppUsageRowView: View {
    let row: AppUsageRow

    var body: some View {
        HStack(spacing: 12) {
            icon
                .frame(width: 34, height: 34)
                .clipShape(.rect(cornerRadius: 9))

            name
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 8)

            Text(ReportStyle.durationString(row.duration))
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(ReportStyle.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            LinearGradient(
                colors: [ReportStyle.gradStart.opacity(0.16), ReportStyle.gradEnd.opacity(0.16)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(.rect(cornerRadius: 14))
    }

    @ViewBuilder
    private var icon: some View {
        if let token = row.token {
            // Real app icon, provided privately by the system.
            Label(token)
                .labelStyle(.iconOnly)
                .font(.system(size: 26))
        } else {
            // Grouped bucket — we can't extract a single icon, so use a glyph.
            ZStack {
                RoundedRectangle(cornerRadius: 9).fill(ReportStyle.orange.opacity(0.18))
                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(ReportStyle.orange)
            }
        }
    }

    @ViewBuilder
    private var name: some View {
        if let token = row.token {
            // Real app name, provided privately by the system.
            Label(token)
                .labelStyle(.titleOnly)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(ReportStyle.textPrimary)
        } else {
            Text("Other")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(ReportStyle.textPrimary)
        }
    }
}

/// Brand tokens mirrored from the app's DesignSystem (the extension is a
/// separate module and can't import the app target).
enum ReportStyle {
    static let orange = Color(red: 1.000, green: 0.478, blue: 0.000)
    static let gradStart = Color(red: 1.000, green: 0.478, blue: 0.000) // warm orange
    static let gradEnd = Color(red: 1.000, green: 0.925, blue: 0.831)   // cream
    static let textPrimary = Color(red: 0.122, green: 0.122, blue: 0.122)
    static let textSecondary = Color(red: 0.420, green: 0.420, blue: 0.420)

    /// Formats a duration like "4h 43m" / "37m" / "2h".
    static func durationString(_ interval: TimeInterval) -> String {
        let totalMinutes = max(0, Int(interval) / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 && minutes > 0 { return "\(hours)h \(minutes)m" }
        if hours > 0 { return "\(hours)h" }
        return "\(minutes)m"
    }
}
