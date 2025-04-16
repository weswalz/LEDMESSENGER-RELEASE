//
//  MessageStatus.swift
//  CLAUDELED
//
//  Created by Claude AI on 4/12/2025.
//

import Foundation
import SwiftUI

/**
 * Represents the status of a message in the LED messaging system
 *
 * A message goes through several states in its lifecycle:
 * - queued: Message is created but not yet displayed
 * - sent: Message is currently being displayed on the LED wall
 * - expired: Message has timed out (typically after 5 minutes)
 * - cancelled: Message was cancelled by the user before completion
 */
enum MessageStatus: String, Codable, CaseIterable {
    /// Message is created but not yet sent to the LED wall
    case queued
    
    /// Message is currently displayed on the LED wall
    case sent
    
    /// Message has been displayed and has now expired
    case expired
    
    /// Message was cancelled before or during display
    case cancelled
    
    /**
     * Color associated with this status for UI representation
     *
     * Each status has a specific color to make it easily identifiable in the UI:
     * - queued: Yellow (waiting)
     * - sent: Green (active)
     * - expired: Gray (completed)
     * - cancelled: Red (cancelled)
     */
    var color: Color {
        switch self {
        case .queued:
            return .yellow
        case .sent:
            return .green
        case .expired:
            return .gray
        case .cancelled:
            return .red
        }
    }
    
    /**
     * Icon name associated with this status for UI representation
     *
     * Each status has a corresponding SF Symbol icon for visual identification:
     * - queued: clock.fill (waiting)
     * - sent: checkmark.circle.fill (active)
     * - expired: timer.fill (timed out)
     * - cancelled: xmark.circle.fill (cancelled)
     */
    var icon: String {
        switch self {
        case .queued:
            return "clock.fill"
        case .sent:
            return "checkmark.circle.fill"
        case .expired:
            return "timer.fill"
        case .cancelled:
            return "xmark.circle.fill"
        }
    }
    
    /**
     * Human-readable description of this status
     *
     * Returns the uppercase status name for display in the UI
     */
    var description: String {
        rawValue.uppercased()
    }
}