//
//  AppUsageReportExtension.swift
//  AppUsageReportExtension
//
//  DeviceActivity Report extension entry point. The system launches this
//  sandboxed extension to render the App Usage card shown on Yoko's Home tab.
//  It only renders a SwiftUI view from the data the system provides for the
//  requested context/filter — it never persists or transmits anything.
//

import DeviceActivity
import SwiftUI

@main
struct AppUsageReportExtension: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        // One scene per supported context. The context raw value must match the
        // `DeviceActivityReport.Context` used by the app (AppUsageCard).
        TopAppsReportScene { configuration in
            TopAppsReportView(configuration: configuration)
        }
    }
}
