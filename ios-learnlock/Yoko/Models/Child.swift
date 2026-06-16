//
//  Child.swift
//  Yoko
//
//  A child identity within the household. Multiple children can be added under
//  one parent account. Each child has their own name and avatar colour, but all
//  children share the same curriculum and learning progress (the shared state
//  lives on `AppStore`). Switching the active child only changes the displayed
//  identity, not the underlying progress.
//

import SwiftUI

struct Child: Identifiable, Hashable {
    let id: UUID
    var name: String
    /// Index into `Child.palette` for the avatar background colour.
    var colorIndex: Int

    init(id: UUID = UUID(), name: String, colorIndex: Int) {
        self.id = id
        self.name = name
        self.colorIndex = colorIndex
    }

    var initial: String { String(name.prefix(1)).uppercased() }

    var avatarColor: Color { Child.palette[colorIndex % Child.palette.count] }

    /// Warm, parent-friendly avatar palette anchored on the brand orange.
    static let palette: [Color] = [
        Color(red: 1.000, green: 0.478, blue: 0.000), // brand orange
        Color(red: 0.95, green: 0.35, blue: 0.45),    // coral
        Color(red: 0.36, green: 0.62, blue: 0.96),    // sky blue
        Color(red: 0.30, green: 0.72, blue: 0.52),    // green
        Color(red: 0.62, green: 0.46, blue: 0.92),    // violet
        Color(red: 0.96, green: 0.66, blue: 0.18)     // amber
    ]
}
