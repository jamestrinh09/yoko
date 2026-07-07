//
//  ShieldConfigurationExtension.swift
//  ShieldConfigurationExtension
//
//  Created by bella vitale on 7/6/26.
//

import ManagedSettings
import ManagedSettingsUI
import UIKit

class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    private func yokoShieldConfiguration() -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterial,
            backgroundColor: UIColor(red: 1.0, green: 0.54, blue: 0.12, alpha: 0.15),
            icon: UIImage(named: "AppIcon"),
            title: ShieldConfiguration.Label(
                text: "App locked by Yoko",
                color: UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1)
            ),
            subtitle: ShieldConfiguration.Label(
                text: "Complete a lesson to unlock your apps 📚",
                color: UIColor(red: 0.45, green: 0.45, blue: 0.45, alpha: 1)
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Open Yoko →",
                color: .white
            ),
            primaryButtonBackgroundColor: UIColor(red: 1.0, green: 0.54, blue: 0.12, alpha: 1)
        )
    }

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        yokoShieldConfiguration()
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        yokoShieldConfiguration()
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        yokoShieldConfiguration()
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        yokoShieldConfiguration()
    }
}
