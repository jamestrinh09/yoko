//
//  AssetURLs.swift
//  Yoko
//
//  Central registry for all remote media URLs.
//
//  - GIFs are served from the GitHub assets folder (assets/gifs).
//  - Images are hosted on Rork; Supabase is used as the interim host until
//    images are migrated into Rork.
//

import Foundation

enum AssetURLs {
    // MARK: - GIFs (GitHub)

    /// Base for mascot/onboarding GIFs hosted in the repo's `assets/gifs` folder.
    static let gifBase = "https://raw.githubusercontent.com/dialedapps/Yoko/main/assets/gifs"

    static func gif(_ name: String) -> String { "\(gifBase)/\(name)" }

    static let happyGIF = gif("HappyGIF.gif")
    static let thinkingGIF = gif("ThinkingGIF.gif")
    static let determinedGIF = gif("DeterminedGIF.gif")
    static let sadGIF = gif("SadGIF.gif")
    static let excitedGIF = gif("ExcitedGIF.gif")
    static let proudGIF = gif("ProudGIF.gif")
    static let glassesGIF = gif("GlassesGIF.gif")

    static var allGIFs: [String] {
        [happyGIF, thinkingGIF, determinedGIF, sadGIF, excitedGIF, proudGIF, glassesGIF]
    }

    // MARK: - Images (Rork / Supabase interim)

    /// Interim Supabase host for onboarding/background images.
    static let imageBase = "https://pyikafpvphzqdadjvktz.supabase.co/storage/v1/object/public/Yoko"

    static func image(_ name: String) -> String { "\(imageBase)/\(name)" }

    static let unlockScreen = image("UnlockScreen.png")
    static let lookingAtIpad = image("LookingatIPAD.png")
    static let behindPov = image("BehindPOV.png")
    static let appBlockDemo = image("AppBlockDemo.png")
    static let learningStatistic = image("Learning%20statistic.png")
    static let abilityToFocusAndRecall = image("ability%20to%20focus%20and%20recall.png")

    /// Hero image for the "Connect Yoko to screen time / notifications" step
    /// (Screen Time + Yoko lock icons). Hosted on Rork.
    static let notificationsHero = "https://pub-e001eb4506b145aa938b5d3badbff6a5.r2.dev/attachments/6w8w55u8if1rg5lkuc9iu.png"
}
