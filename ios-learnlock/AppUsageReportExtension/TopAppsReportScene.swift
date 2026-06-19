//
//  TopAppsReportScene.swift
//  AppUsageReportExtension
//
//  Aggregates the system-provided device activity into a small "top apps"
//  breakdown: the top 2 apps individually, with everything else summed into a
//  single "Other" bucket. Sorted descending by total duration.
//

import DeviceActivity
import FamilyControls
import ManagedSettings
import SwiftUI

extension DeviceActivityReport.Context {
    static let topAppsUsage = Self(rawValue: "TopAppsUsage")
}

struct TopAppsReportScene: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .topAppsUsage
    let content: (AppUsageConfiguration) -> TopAppsReportView

    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> AppUsageConfiguration {
        var durationByToken: [ApplicationToken: TimeInterval] = [:]
        var nameByToken: [ApplicationToken: String] = [:]
        // Apps without a resolvable token (e.g. system apps) get folded into Other.
        var untrackedDuration: TimeInterval = 0

        for await activityData in data {
            for await segment in activityData.activitySegments {
                for await category in segment.categories {
                    for await app in category.applications {
                        let duration = app.totalActivityDuration
                        guard duration > 0 else { continue }
                        if let token = app.application.token {
                            durationByToken[token, default: 0] += duration
                            if nameByToken[token] == nil {
                                nameByToken[token] = app.application.localizedDisplayName ?? ""
                            }
                        } else {
                            untrackedDuration += duration
                        }
                    }
                }
            }
        }

        // Sort descending by total duration, take the top 2 individually.
        let sorted = durationByToken.sorted { $0.value > $1.value }

        var rows: [AppUsageRow] = []
        for (token, duration) in sorted.prefix(2) {
            rows.append(
                AppUsageRow(token: token, name: nameByToken[token] ?? "", duration: duration, isOther: false)
            )
        }

        // Everything beyond the top 2 (plus untracked) becomes a single Other row.
        let remainder = sorted.dropFirst(2).reduce(0) { $0 + $1.value } + untrackedDuration
        if remainder > 0 {
            rows.append(AppUsageRow(token: nil, name: "Other", duration: remainder, isOther: true))
        }

        return AppUsageConfiguration(rows: rows)
    }
}
