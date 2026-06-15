//
//  StatCard.swift
//  Yoko
//

import SwiftUI

struct StatCard: View {
    let symbol: String
    let value: String
    let label: String
    var tint: Color = DS.Color.accent

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(tint.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(tint)
            }
            Text(value)
                .font(.dsTitle)
                .foregroundStyle(DS.Color.textPrimary)
            Text(label)
                .font(.dsCaption)
                .foregroundStyle(DS.Color.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsCard(padding: 16)
    }
}

struct SectionHeader: View {
    let title: String
    var trailing: String? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.dsTitle2)
                .foregroundStyle(DS.Color.textPrimary)
            Spacer()
            if let t = trailing {
                Text(t)
                    .font(.dsCallout)
                    .foregroundStyle(DS.Color.accent)
            }
        }
    }
}
