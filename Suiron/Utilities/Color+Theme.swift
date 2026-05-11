
//  Color+Theme.swift
//  Suiron

import SwiftUI

extension Color {
    static let appBackground = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(white: 0.07, alpha: 1)   // #121212
            : UIColor(white: 0.95, alpha: 1)   // #F2F2F2
    })
    static let cardBackground = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(white: 0.12, alpha: 1)   // #1E1E1E
            : UIColor(white: 1.00, alpha: 1)   // #FFFFFF
    })
    static let inputBackground = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(white: 0.18, alpha: 1)   // #2E2E2E
            : UIColor(white: 0.96, alpha: 1)   // #F5F5F5
    })
    static let textPrimary = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(white: 0.92, alpha: 1)   // #EBEBEB
            : UIColor(white: 0.10, alpha: 1)   // #1A1A1A
    })
    static let textSecondary = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(white: 0.50, alpha: 1)   // #808080
            : UIColor(white: 0.53, alpha: 1)   // #888888
    })
    static let accent = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(white: 0.92, alpha: 1)   // #EBEBEB
            : UIColor(white: 0.10, alpha: 1)   // #1A1A1A
    })
    static let correct     = Color(hex: "#4CAF50")
    static let incorrect   = Color(hex: "#F44336")
    static let correctBg   = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.10, green: 0.18, blue: 0.10, alpha: 1)
            : UIColor(red: 0.91, green: 0.96, blue: 0.91, alpha: 1)
    })
    static let incorrectBg = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.18, green: 0.10, blue: 0.10, alpha: 1)
            : UIColor(red: 1.00, green: 0.92, blue: 0.93, alpha: 1)
    })

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
