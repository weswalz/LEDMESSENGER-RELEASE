//
//  LabelType.swift
//  CLAUDELED
//
//  Created by Claude AI on 4/12/2025.
//

import Foundation

/**
 * Represents the type of label/prefix applied to messages
 *
 * Labels are prefixes that appear before the message content,
 * such as "Table 5:" or "Customer:" to provide context for
 * the message being displayed.
 */
enum LabelType: String, Codable, CaseIterable, Identifiable {
    /// Use table number as prefix (e.g., "Table 5: ")
    case tableNumber
    
    /// Use customer name as prefix (e.g., "Customer: ")
    case customerName
    
    /// Use a custom prefix (user-defined)
    case custom
    
    /// Use no prefix (message content only)
    case none
    
    /**
     * Unique identifier for this label type
     *
     * Required by Identifiable protocol, uses the raw string value
     */
    var id: String { rawValue }
    
    /**
     * User-friendly display name for this label type
     *
     * Properly formatted name for use in UI controls
     */
    var displayName: String {
        switch self {
        case .tableNumber:
            return "Table Number"
        case .customerName:
            return "Customer Name"
        case .custom:
            return "Custom Label"
        case .none:
            return "No Label"
        }
    }
    
    /**
     * Generate the default prefix text for this label type
     *
     * - Parameter customLabel: Optional custom label text to use when type is .custom
     * - Returns: The appropriate prefix text for the label type
     */
    func defaultPrefix(customLabel: String = "") -> String {
        switch self {
        case .tableNumber:
            return "Table"
        case .customerName:
            return "Customer"
        case .custom:
            return customLabel
        case .none:
            return ""
        }
    }
}