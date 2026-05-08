
//  Color+Theme.swift
//  Suiron

import SwiftUI

extension Color {
    static let appBackground  = Color(hex: "#F2F2F2")
    static let cardBackground = Color(hex: "#FFFFFF")
    static let textPrimary    = Color(hex: "#1A1A1A")
    static let textSecondary  = Color(hex: "#888888")
    static let accent         = Color(hex: "#1A1A1A")
    static let correct        = Color(hex: "#4CAF50")
    static let incorrect      = Color(hex: "#F44336")
    static let correctBg      = Color(hex: "#E8F5E9")
    static let incorrectBg    = Color(hex: "#FFEBEE")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int & 0xFF)         / 255
        self.init(red: r, green: g, blue: b)
    }
}
