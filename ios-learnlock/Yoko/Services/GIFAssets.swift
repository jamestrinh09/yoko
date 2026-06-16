//
//  GIFAssets.swift
//  Yoko
//
//  Central catalog of remote mascot/animation GIF URLs. Hosted on Cloudinary.
//  Keeping every URL in one place means swapping a host or a single asset only
//  touches this file.
//

import Foundation

enum GIFAssets {
    static let happy = "https://res.cloudinary.com/dpx2bh9tw/image/upload/v1781582389/HappyGIF_w0tv1e.gif"
    static let thinking = "https://res.cloudinary.com/dpx2bh9tw/image/upload/v1781582388/ThinkingGIF_sk7fqc.gif"
    static let determined = "https://res.cloudinary.com/dpx2bh9tw/image/upload/v1781582388/DeterminedGIF_hunkij.gif"
    static let sad = "https://res.cloudinary.com/dpx2bh9tw/image/upload/v1781582386/SadGIF_cvnp8f.gif"
    static let excited = "https://res.cloudinary.com/dpx2bh9tw/image/upload/v1781582389/ExcitedGIF_uffo5e.gif"
    static let proud = "https://res.cloudinary.com/dpx2bh9tw/image/upload/v1781582383/ProudGIF_cityxu.gif"
    static let glasses = "https://res.cloudinary.com/dpx2bh9tw/image/upload/v1781582382/GlassesGIF_twlhso.gif"
    static let armor = "https://res.cloudinary.com/dpx2bh9tw/image/upload/v1781582389/armorGIF_wmcovd.gif"
    static let streak1 = "https://res.cloudinary.com/dpx2bh9tw/image/upload/v1781582384/StreakGIF1_jyclxd.gif"
    static let streak2 = "https://res.cloudinary.com/dpx2bh9tw/image/upload/v1781582384/StreakGIF2_jenk4n.gif"
    static let lockStanding = "https://res.cloudinary.com/dpx2bh9tw/image/upload/v1781588482/lockstandingGIF_twy5nk.gif"

    static var all: [String] {
        [happy, thinking, determined, sad, excited, proud, glasses, armor, streak1, streak2, lockStanding]
    }
}
