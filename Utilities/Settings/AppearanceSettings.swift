//
//  AppearanceSettings.swift
//  CLAUDELED
//
//  Created by Claude AI on 4/12/2025.
//

import Foundation
import SwiftUI

/**
 * Settings for app appearance
 *
 * Contains configuration parameters for the visual appearance
 * and behavior of the application UI.
 */
struct AppearanceSettings: Codable, Equatable {
    /// Whether to show debug information
    var showDebug: Bool
    
    /// Whether to show expiration timers on messages
    var showTimers: Bool
    
    /// The color theme for the application
    var colorTheme: ColorTheme
    
    /// Whether to use compact mode on smaller screens
    var useCompactMode: Bool
    
    /**
     * Available color themes for the application
     */
    enum ColorTheme: String, Codable, CaseIterable {
        /// Dark purple theme (default)
        case purple
        
        /// Dark blue theme
        case blue
        
        /// Dark red theme
        case red
        
        /// Dark mode (black/gray)
        case dark
        
        /**
         * Primary accent color for the theme
         */
        var accentColor: Color {
            switch self {
            case .purple:
                return Color.purple
            case .blue:
                return Color.blue
            case .red:
                return Color.red
            case .dark:
                return Color.gray
            }
        }
        
        /**
         * Secondary accent color for the theme
         */
        var secondaryColor: Color {
            switch self {
            case .purple:
                return Color(red: 0.5, green: 0.0, blue: 0.8)
            case .blue:
                return Color(red: 0.0, green: 0.5, blue: 0.8)
            case .red:
                return Color(red: 0.8, green: 0.2, blue: 0.2)
            case .dark:
                return Color(white: 0.3)
            }
        }
        
        /**
         * Background color for the theme
         */
        var backgroundColor: Color {
            return Color.black
        }
        
        /**
         * Display name for the theme
         */
        var displayName: String {
            switch self {
            case .purple:
                return "Purple"
            case .blue:
                return "Blue"
            case .red:
                return "Red"
            case .dark:
                return "Dark"
            }
        }
    }
    
    /**
     * Create appearance settings with default values
     *
     * - Returns: Default appearance settings configuration
     */
    static func defaultSettings() -> AppearanceSettings {
        AppearanceSettings(
            showDebug: false,
            showTimers: true,
            colorTheme: .purple,
            useCompactMode: false
        )
    }
}