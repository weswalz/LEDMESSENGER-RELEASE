//
//  LineBreakMode.swift
//  CLAUDELED
//
//  Created by Claude AI on 4/12/2025.
//

import Foundation

/**
 * Defines how text is wrapped or broken into multiple lines
 *
 * On LED walls, text often needs to be broken into multiple lines
 * for better readability. This enum defines the different strategies
 * for determining where to insert line breaks.
 */
enum LineBreakMode: String, Codable, CaseIterable, Identifiable {
    /// No line breaks - display all text on a single line
    case none
    
    /// Break after a specific number of words (customizable)
    case wordCount
    
    /// Break after a certain number of characters (customizable)
    case characterLimit
    
    /**
     * Unique identifier for this line break mode
     *
     * Required by Identifiable protocol, uses the raw string value
     */
    var id: String { rawValue }
    
    /**
     * User-friendly display name for this line break mode
     *
     * Properly formatted name for use in UI controls
     */
    var displayName: String {
        switch self {
        case .none:
            return "No Line Breaks"
        case .wordCount:
            return "After X Words"
        case .characterLimit:
            return "After X Characters"
        }
    }
    
    /**
     * Description of how this mode works
     *
     * Detailed explanation for help text or tooltips
     */
    var description: String {
        switch self {
        case .none:
            return "Displays the entire message on a single line without any line breaks."
        case .wordCount:
            return "Breaks the text after a specified number of words, creating a consistent rhythm for the LED wall display."
        case .characterLimit:
            return "Breaks the text whenever a line would exceed the specified number of characters, optimizing for available space."
        }
    }
}