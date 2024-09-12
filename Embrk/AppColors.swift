//
//  AppColors.swift
//  Embrk
//
//  Created by Ty Mitchell on 9/7/24.
//


import SwiftUI

// MARK: - Color Scheme
struct AppColors {
    static let primary = Color(hex: "3498db")  // Bright blue
    static let secondary = Color(hex: "2ecc71")  // Emerald green
    static let accent = Color(hex: "e74c3c")  // Soft red
    static let background = Color(hex: "f8f9fa")  // Off-white
    static let cardBackground = Color.white
    static let text = Color(hex: "2c3e50")  // Dark blue-gray
    static let lightText = Color(hex: "95a5a6")  // Light gray
    
    // Additional colors for variety
    static let yellow = Color(hex: "f1c40f")
    static let purple = Color(hex: "9b59b6")
    static let orange = Color(hex: "e67e22")
}

// MARK: - Typography
struct AppFonts {
    static let titleFont = "Helvetica Neue"
    static let bodyFont = "Avenir"
    
    static let largeTitle = Font.custom(titleFont, size: 34).weight(.bold)
    static let title1 = Font.custom(titleFont, size: 28).weight(.semibold)
    static let title2 = Font.custom(titleFont, size: 22).weight(.semibold)
    static let title3 = Font.custom(titleFont, size : 18).weight(.semibold)
    static let headline = Font.custom(bodyFont, size: 17).weight(.semibold)
    static let body = Font.custom(bodyFont, size: 17)
    static let callout = Font.custom(bodyFont, size: 16)
    static let subheadline = Font.custom(bodyFont, size: 15)
    static let footnote = Font.custom(bodyFont, size: 13)
    static let caption = Font.custom(bodyFont, size: 12)
}

// MARK: - Common Components
struct AppButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppFonts.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(AppColors.primary)
                .cornerRadius(10)
        }
    }
}

struct AppCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(AppColors.cardBackground)
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Layout Guidelines
struct AppSpacing {
    static let small: CGFloat = 8
    static let medium: CGFloat = 16
    static let large: CGFloat = 24
    static let extraLarge: CGFloat = 32
}

// MARK: - Helper Extensions
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
