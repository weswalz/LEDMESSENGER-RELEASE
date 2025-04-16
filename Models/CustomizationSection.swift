//
//  CustomizationSection.swift
//  CLAUDELED
//
//  Created by Claude AI on 4/12/2025.
//

import Foundation

/**
 * Defines sections in the customization view
 *
 * Used to organize the customization UI into logical sections,
 * each with different settings related to message display and formatting.
 */
enum CustomizationSection: CaseIterable {
    /// Message behavior settings (timers, auto-removal)
    case messageSettings
    
    /// Text formatting options (line breaks, character limits)
    case textFormatting
    
    /// Label settings (prefix type, custom labels)
    case labelSettings
    
    /// Template management (create, edit, delete templates)
    case templateManagement
    
    /**
     * Provides a display name for use in section headers
     */
    var displayName: String {
        switch self {
        case .textFormatting:
            return "TEXT FORMATTING"
        case .messageSettings:
            return "MESSAGE TIMING"
        case .labelSettings:
            return "LABEL SETTINGS"
        case .templateManagement:
            return "TEMPLATES"
        }
    }
    
    /**
     * Provides a detailed description of what each section controls
     */
    var description: String {
        switch self {
        case .textFormatting:
            return "Configure how text is formatted and broken into lines for display on the LED wall."
        case .messageSettings:
            return "Configure message countdown timers and automatic behavior."
        case .labelSettings:
            return "Set up labels and prefixes for messages, such as table numbers or custom labels."
        case .templateManagement:
            return "Create and manage message templates for quick access to commonly used messages."
        }
    }
    
    /**
     * Icon name for each section (SF Symbols)
     */
    var iconName: String {
        switch self {
        case .textFormatting:
            return "text.alignleft"
        case .messageSettings:
            return "timer"
        case .labelSettings:
            return "tag"
        case .templateManagement:
            return "doc.on.doc"
        }
    }
}