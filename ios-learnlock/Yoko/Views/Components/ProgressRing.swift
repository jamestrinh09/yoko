//
//  ProgressRing.swift
//  Yoko
//

import SwiftUI

struct ProgressRing: View {
    var progress: Double
    var size: CGFloat = 88
    var lineWidth: CGFloat = 10
    var trackColor: Color = DS.Color.accentSoft
    var ringColor: Color = DS.Color.accent

    var body: some View {
        ZStack {
            Circle()
                .stroke(trackColor, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, min(1, progress)))
                .stroke(ringColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(duration: 0.7), value: progress)
        }
        .frame(width: size, height: size)
    }
}

struct ProgressBar: View {
    var progress: Double
    var height: CGFloat = 10
    var tint: Color = DS.Color.accent

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(DS.Color.accentSoft)
                Capsule()
                    .fill(tint)
                    .frame(width: max(0, min(1, progress)) * geo.size.width)
            }
        }
        .frame(height: height)
        .animation(.spring(duration: 0.6), value: progress)
    }
}
