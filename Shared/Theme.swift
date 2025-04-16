//
//  Theme.swift
//  LEDMESSENGER
//
//  Created by Claude AI on 4/12/2025.
//

/**
 * Application-wide visual theme definition
 * 
 * This file centralizes all visual styling for the LED Messenger app,
 * including colors, gradients, font sizes, and reusable style modifiers.
 * Using a centralized theme ensures visual consistency across the app.
 */

import SwiftUI

/**
 * Global theme definition containing all visual styling elements
 *
 * The Theme enum acts as a namespace for app-wide styling constants
 * and functions, providing a consistent look and feel throughout the app.
 */
enum Theme {
    // MARK: - Color Definitions
    
    /**
     * Main background gradient colors
     * Creates a deep purple to black radial gradient effect
     */
    static let bgTop = Color.black
    static let bgBottom = Color(hex: "#1E0938") // Deep purple
    
    /**
     * Accent colors for highlights and interactive elements
     * Carefully selected to complement the dark purple background
     */
    static let accentBlue = Color(hex: "#6042FF")  // Electric blue-purple
    static let accentPink = Color(hex: "#F15EFF")  // Vibrant magenta/pink
    static let accentPurple = Color(hex: "#A55EFF")  // Neon purple
    static let accentPeach = Color(hex: "#E2C1FF")  // Soft lavender
    
    /**
     * System feedback colors
     * Used for success/error states and indicators
     */
    static let dangerRed = Color(hex: "#FF5252")  // Warning/error color
    static let successGreen = Color(hex: "#69F0AE")  // Success/confirmation color
    
    /**
     * Text colors for different contexts
     * Ensures proper contrast and readability
     */
    static let textPrimary = Color.white  // Main text color
    static let textSecondary = Color(white: 0.8)  // Subdued text color
    static let textHighlight = Color(hex: "#F15EFF")  // Attention-grabbing text
    
    /**
     * Card and container background colors
     * Semi-transparent to maintain visual depth
     */
    static let cardBgDark = Color(hex: "#1E0938").opacity(0.85)  // Dark purple overlay
    static let cardBgLight = Color(hex: "#371364").opacity(0.5)  // Medium purple overlay
    
    // MARK: - Typography Sizes
    
    /**
     * Standardized text sizes for consistent typography
     * Used throughout the app for different text hierarchies
     */
    static let fontTitle = 24.0      // Main screen titles
    static let fontHeader = 20.0     // Section headers
    static let fontSubheader = 16.0  // Card titles, important labels
    static let fontBody = 15.0       // Standard body text
    static let fontCaption = 12.0    // Small informational text
    
    // MARK: - Gradient Definitions
    
    /**
     * Main app background gradient
     * Creates a radial effect with darker corners for depth
     */
    static let backgroundGradient = RadialGradient(
        gradient: Gradient(colors: [bgBottom, bgTop]),
        center: .center,
        startRadius: 5,
        endRadius: 500
    )
    
    /**
     * Primary action gradient for main buttons
     * Rich neon purple effect that stands out against the background
     */
    static let primaryGradient = LinearGradient(
        gradient: Gradient(colors: [accentPurple, accentPurple.opacity(0.8)]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /**
     * Secondary action gradient for alternative buttons
     * Purple to pink transition for visual variety
     */
    static let secondaryGradient = LinearGradient(
        gradient: Gradient(colors: [accentPurple, accentPink]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /**
     * Subtle gradient for card backgrounds
     * Adds visual depth without competing with content
     */
    static let cardGradient = LinearGradient(
        gradient: Gradient(colors: [cardBgDark, cardBgDark.opacity(0.7)]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    // MARK: - Style Modifiers
    
    /**
     * Creates a modern frosted glass effect for panels
     * Simulates translucency with highlights and shadows
     *
     * @param cornerRadius The corner radius of the glass panel
     * @return A View modifier for the glass effect
     */
    static func glassEffect(cornerRadius: CGFloat = 16) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.black.opacity(0.5))
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.black.opacity(0.3))
                    .blur(radius: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.white.opacity(0.4), .clear, .white.opacity(0.1)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
    
    /**
     * Creates a neon-like glowing border effect
     * Useful for highlighting active elements
     *
     * @param cornerRadius The corner radius of the border
     * @param color The color of the neon glow (default: accentPurple)
     * @return A View modifier for the neon border effect
     */
    static func neonBorder(cornerRadius: CGFloat = 16, color: Color = accentPurple) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .stroke(color, lineWidth: 1.5)
            .shadow(color: color.opacity(0.7), radius: 3, x: 0, y: 0)
    }
    
    /**
     * Cool secondary button style with shadow and hover effect
     * Used for medium-priority actions
     *
     * @param content The button content view
     * @return A styled button with the cool style applied
     */
    static func coolButtonStyle(_ content: some View) -> some View {
        content
            .font(.system(size: fontSubheader, weight: .bold))
            .foregroundColor(.white)
            .tracking(0.8)  // Letter spacing for better readability
            .padding(.vertical, 10)
            .padding(.horizontal, 18)
            .background(secondaryGradient)
            .clipShape(Capsule())
            .shadow(color: accentBlue.opacity(0.5), radius: 8, x: 0, y: 4)
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
    
    /**
     * Primary button style for high-visibility actions
     * Used for the most important actions on each screen
     *
     * @param content The button content view
     * @return A styled button with the hot style applied
     */
    static func hotButtonStyle(_ content: some View) -> some View {
        content
            .font(.system(size: fontSubheader, weight: .bold))
            .foregroundColor(.white)
            .tracking(0.8)  // Letter spacing for better readability
            .padding(.vertical, 10)
            .padding(.horizontal, 18)
            .background(primaryGradient)
            .clipShape(Capsule())
            .shadow(color: accentPink.opacity(0.5), radius: 8, x: 0, y: 4)
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
    
    /**
     * Rounded button style for general use
     * Features animation-friendly properties
     *
     * @param content The button content view
     * @return A styled button with the rounded style applied
     */
    static func roundedButtonStyle(_ content: some View) -> some View {
        content
            .font(.system(size: fontSubheader, weight: .bold))
            .foregroundColor(.white)
            .tracking(0.5)  // Moderate letter spacing
            .padding(.vertical, 10)
            .padding(.horizontal, 18)
            .background(secondaryGradient)
            .clipShape(Capsule())
            .shadow(color: accentPurple.opacity(0.5), radius: 8, x: 0, y: 4)
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
    
    /**
     * Modern card style for content containers
     * Features subtle gradient background and glowing border
     *
     * @param content The card content view
     * @return A styled card with consistent padding and appearance
     */
    static func cardStyle(_ content: some View) -> some View {
        content
            .padding(15)  // Internal content padding
            .background(
                cardGradient
                    .cornerRadius(16)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [accentPurple.opacity(0.7), accentPink.opacity(0.2)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: accentPurple.opacity(0.2), radius: 15, x: 0, y: 8)
    }
}

// MARK: - Custom Color Extension

/**
 * Extension to enable hex color code initialization for SwiftUI Colors
 * Makes it easier to use web-standard color codes in the app
 */
extension Color {
    /**
     * Initialize a Color from a hex string
     * Supports 3-digit RGB, 6-digit RGB, and 8-digit ARGB formats
     *
     * @param hex A hex color string (e.g. "#FF5500" or "#F50")
     * @return A SwiftUI Color initialized from the hex value
     */
    init(hex: String) {
        // Remove any non-alphanumeric characters (like # prefix)
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        // Variables for RGBA components
        let a, r, g, b: UInt64
        
        // Process different hex formats
        switch hex.count {
        case 3: // RGB (12-bit) - Like #F50
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit) - Like #FF5500
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit) - Like #FFFF5500
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0) // Default to opaque black for invalid values
        }
        
        // Initialize the color using the standard RGB initializer
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}