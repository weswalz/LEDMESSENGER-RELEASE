//
//  AppSettings.swift
//  LEDMESSENGER
//
//  Created by clubkit.io on 4/12/2025.
//

import Foundation

// App mode enum
public enum AppMode: String, Codable, CaseIterable, Identifiable {
    case solo
    case paired
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .solo:
            return "SOLO"
        case .paired:
            return "PAIRED"
        }
    }
    
    public var description: String {
        switch self {
        case .solo:
            return "Operate independently with all features"
        case .paired:
            return "Connect with Mac as synchronized peer"
        }
    }
    
    public var enablesPeerConnectivity: Bool {
        self == .paired
    }
    
    public var showsSetupScreen: Bool {
        self == .solo
    }
    
    public var allowsSettingsModification: Bool {
        self == .solo
    }
}

// Mode settings
public struct ModeSettings: Codable, Equatable {
    public var currentMode: AppMode
    public var showModeSelectionOnStartup: Bool
    public var allowModeSwitching: Bool
    public var showModeIndicator: Bool
    
    public init(
        currentMode: AppMode = .paired,
        showModeSelectionOnStartup: Bool = true,
        allowModeSwitching: Bool = true,
        showModeIndicator: Bool = true
    ) {
        self.currentMode = currentMode
        self.showModeSelectionOnStartup = showModeSelectionOnStartup
        self.allowModeSwitching = allowModeSwitching
        self.showModeIndicator = showModeIndicator
    }
    
    public static func defaultSettings() -> ModeSettings {
        ModeSettings(
            currentMode: .paired,
            showModeSelectionOnStartup: true,
            allowModeSwitching: true,
            showModeIndicator: false
        )
    }
    
    public func validate() -> Bool {
        return true
    }
}

/**
 * Global application settings
 *
 * Contains all configuration parameters for the application,
 * organized into logical sections for different aspects of functionality.
 */
struct AppSettings: Codable, Equatable {
    /// OSC connection settings
    var osc: OSCSettings
    
    /// Text formatting settings
    var formatting: FormattingSettings
    
    /// App appearance settings
    var appearance: AppearanceSettings
    
    /// App mode settings (iPad SOLO/PAIRED modes)
    var mode: ModeSettings
    
    /// Equatable implementation
    static func == (lhs: AppSettings, rhs: AppSettings) -> Bool {
        return lhs.osc.host == rhs.osc.host &&
               lhs.osc.port == rhs.osc.port &&
               lhs.osc.layer == rhs.osc.layer &&
               lhs.osc.startingClip == rhs.osc.startingClip &&
               lhs.osc.clearClip == rhs.osc.clearClip &&
               lhs.osc.autoConnect == rhs.osc.autoConnect &&
               lhs.formatting == rhs.formatting &&
               lhs.appearance == rhs.appearance &&
               lhs.mode.currentMode == rhs.mode.currentMode
    }
    
    /**
     * Create app settings with default values
     *
     * - Returns: Default application settings configuration
     */
    static func defaultSettings() -> AppSettings {
        AppSettings(
            osc: OSCSettings.defaultSettings(),
            formatting: FormattingSettings.defaultSettings(),
            appearance: AppearanceSettings.defaultSettings(),
            mode: ModeSettings.defaultSettings()
        )
    }
    
    /**
     * Validate all settings
     *
     * Checks that all settings are valid across all sections.
     *
     * - Returns: Boolean indicating if all settings are valid
     */
    func validate() -> Bool {
        return osc.validate() && formatting.validate() && mode.validate()
    }
    
    /**
     * Reset to default settings
     *
     * Returns a new AppSettings instance with all default values.
     *
     * - Returns: Default settings
     */
    static func resetToDefaults() -> AppSettings {
        return defaultSettings()
    }
    
    /**
     * Create a copy of the settings
     *
     * Useful for making temporary changes that can be discarded.
     *
     * - Returns: A deep copy of the settings
     */
    func copy() -> AppSettings {
        // Using encode/decode for deep copy
        guard let data = try? JSONEncoder().encode(self),
              let copy = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            // Fallback to defaults if serialization fails
            return AppSettings.defaultSettings()
        }
        return copy
    }
}