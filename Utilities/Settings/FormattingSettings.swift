//
//  FormattingSettings.swift
//  CLAUDELED
//
//  Created by Claude AI on 4/12/2025.
//

import Foundation

/**
 * Settings for text formatting
 *
 * Contains configuration parameters for how messages are formatted
 * and displayed on the LED wall, including line breaks and labels.
 */
struct FormattingSettings: Codable, Equatable {
    /// The line break mode (none, wordCount, characterLimit)
    var lineBreakMode: LineBreakMode
    
    /// The maximum characters per line (used with characterLimit mode)
    var maxCharsPerLine: Int
    
    /// The number of words per line (used with wordCount mode)
    var wordsPerLine: Int
    
    /// The default label type for new messages
    var defaultLabelType: LabelType
    
    /// The default custom label text
    var defaultCustomLabel: String
    
    /// Message countdown duration in minutes
    var messageCountdownMinutes: Int
    
    /**
     * Create formatting settings with default values
     *
     * - Returns: Default formatting settings configuration
     */
    static func defaultSettings() -> FormattingSettings {
        FormattingSettings(
            lineBreakMode: .wordCount,
            maxCharsPerLine: 16,
            wordsPerLine: 2,
            defaultLabelType: .tableNumber,
            defaultCustomLabel: "",
            messageCountdownMinutes: 5
        )
    }
    
    /**
     * Validate the settings
     *
     * Checks that all settings are within valid ranges.
     *
     * - Returns: Boolean indicating if the settings are valid
     */
    func validate() -> Bool {
        // Character limit validation
        let charsValid = maxCharsPerLine >= 10 && maxCharsPerLine <= 100
        
        // Word count validation
        let wordsValid = wordsPerLine >= 1 && wordsPerLine <= 10
        
        // Custom label validation (if used)
        let labelValid = defaultLabelType != .custom || !defaultCustomLabel.isEmpty
        
        // Countdown minutes validation (1-60 minutes)
        let countdownValid = messageCountdownMinutes >= 1 && messageCountdownMinutes <= 60
        
        return charsValid && wordsValid && labelValid && countdownValid
    }
    
    /**
     * Apply line break formatting to text
     *
     * Formats the text according to the current line break settings.
     *
     * - Parameter text: The text to format
     * - Returns: Formatted text with appropriate line breaks
     */
    func formatText(_ text: String) -> String {
        // Manual line breaks implementation without Message dependency
        let words = text.split(separator: " ")
        
        switch lineBreakMode {
        case .none:
            // No line breaks, return the text as is
            return text
            
        case .wordCount:
            // Break after specified number of words
            var lines: [String] = []
            var currentLine: [String] = []
            
            for (index, word) in words.enumerated() {
                currentLine.append(String(word))
                
                // Add line break after every X words or at the end
                if (index + 1) % wordsPerLine == 0 || index == words.count - 1 {
                    lines.append(currentLine.joined(separator: " "))
                    currentLine = []
                }
            }
            
            return lines.joined(separator: "\n")
            
        case .characterLimit:
            // Break when exceeding character limit
            var lines: [String] = []
            var currentLine: [String] = []
            var currentLength = 0
            
            for word in words {
                let wordLength = word.count
                
                // Check if adding this word would exceed the limit
                if currentLength + wordLength + (currentLine.isEmpty ? 0 : 1) <= maxCharsPerLine {
                    // Word fits on the current line
                    currentLine.append(String(word))
                    currentLength += wordLength + (currentLine.count > 1 ? 1 : 0)
                } else {
                    // Word doesn't fit, create a new line
                    if !currentLine.isEmpty {
                        lines.append(currentLine.joined(separator: " "))
                    }
                    currentLine = [String(word)]
                    currentLength = wordLength
                }
            }
            
            // Add any remaining line
            if !currentLine.isEmpty {
                lines.append(currentLine.joined(separator: " "))
            }
            
            return lines.joined(separator: "\n")
        }
    }
    
    /**
     * Get the prefix text based on current label settings
     *
     * - Parameter identifier: Optional identifier (e.g., table number)
     * - Returns: Formatted prefix text
     */
    func formatPrefix(identifier: String = "") -> String {
        switch defaultLabelType {
        case .tableNumber:
            return identifier.isEmpty ? "Table: " : "Table \(identifier): "
        case .customerName:
            return "Customer: "
        case .custom:
            return defaultCustomLabel.isEmpty ? "" : "\(defaultCustomLabel): "
        case .none:
            return ""
        }
    }
}