//
//  SettingsManager.swift
//  LEDMESSENGER
//
//  Created by Claude AI on 4/12/2025.
//

import Foundation
import Combine

/// Manages application settings
final class SettingsManager: ObservableObject {
    // MARK: - Properties
    
    /// The current settings
    @Published var settings: AppSettings
    
    /// For state changes
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Keys
    
    /// UserDefaults key for settings
    private let settingsKey = "com.ledmessenger.settings"
    
    // MARK: - Initialization
    
    /// Initialize the settings manager
    init() {
        // Load settings from UserDefaults or use defaults
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let settings = try? JSONDecoder().decode(AppSettings.self, from: data) {
            self.settings = settings
        } else {
            self.settings = AppSettings.defaultSettings()
        }
        
        // Save settings when they change
        $settings
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] settings in
                self?.saveSettings(settings)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Methods
    
    /// Save settings to UserDefaults
    private func saveSettings(_ settings: AppSettings) {
        guard let data = try? JSONEncoder().encode(settings) else {
            return
        }
        
        UserDefaults.standard.set(data, forKey: settingsKey)
    }
    
    /// Reset settings to defaults
    func resetToDefaults() {
        settings = AppSettings.defaultSettings()
    }
    
    /// Update OSC settings
    func updateOSCSettings(
        ipAddress: String? = nil,
        port: Int? = nil,
        layer: Int? = nil,
        startingClip: Int? = nil,
        clearClip: Int? = nil
    ) {
        var newSettings = settings.osc
        
        if let ipAddress = ipAddress {
            newSettings.ipAddress = ipAddress
        }
        
        if let port = port {
            newSettings.port = port
        }
        
        if let layer = layer {
            newSettings.layer = layer
        }
        
        if let startingClip = startingClip {
            newSettings.startingClip = startingClip
        }
        
        // clearClip is now always calculated from startingClip, so we ignore this parameter
        
        settings.osc = newSettings
    }
    
    /// Update formatting settings
    func updateFormattingSettings(
        lineBreakMode: LineBreakMode? = nil,
        maxCharsPerLine: Int? = nil,
        wordsPerLine: Int? = nil,
        defaultLabelType: LabelType? = nil,
        defaultCustomLabel: String? = nil,
        messageCountdownMinutes: Int? = nil
    ) {
        var newSettings = settings.formatting
        
        if let lineBreakMode = lineBreakMode {
            newSettings.lineBreakMode = lineBreakMode
        }
        
        if let maxCharsPerLine = maxCharsPerLine {
            newSettings.maxCharsPerLine = maxCharsPerLine
        }
        
        if let wordsPerLine = wordsPerLine {
            newSettings.wordsPerLine = wordsPerLine
        }
        
        if let defaultLabelType = defaultLabelType {
            newSettings.defaultLabelType = defaultLabelType
        }
        
        if let defaultCustomLabel = defaultCustomLabel {
            newSettings.defaultCustomLabel = defaultCustomLabel
        }
        
        if let messageCountdownMinutes = messageCountdownMinutes {
            newSettings.messageCountdownMinutes = messageCountdownMinutes
        }
        
        settings.formatting = newSettings
    }
    
    /// Update appearance settings
    func updateAppearanceSettings(
        showDebug: Bool? = nil,
        showTimers: Bool? = nil,
        colorTheme: AppearanceSettings.ColorTheme? = nil,
        useCompactMode: Bool? = nil
    ) {
        var newSettings = settings.appearance
        
        if let showDebug = showDebug {
            newSettings.showDebug = showDebug
        }
        
        if let showTimers = showTimers {
            newSettings.showTimers = showTimers
        }
        
        if let colorTheme = colorTheme {
            newSettings.colorTheme = colorTheme
        }
        
        if let useCompactMode = useCompactMode {
            newSettings.useCompactMode = useCompactMode
        }
        
        settings.appearance = newSettings
    }
}