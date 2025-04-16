//
//  Notification+Extensions.swift
//  LEDMESSENGER
//
//  Created by Claude AI on 4/12/2025.
//

import Foundation

/// Extension for notification names used in the app
extension Notification.Name {
    /// Notification when a message is added to the queue
    static let messageAdded = Notification.Name("messageAdded")
    
    /// Notification when a message is cancelled
    static let messageCancelled = Notification.Name("messageCancelled")
    
    /// Notification when a message is sent to the LED wall
    static let messageSent = Notification.Name("messageSent")
    
    /// Notification when a message is updated
    static let messageUpdated = Notification.Name("messageUpdated")
    
    /// Notification when the queue is cleared
    static let queueCleared = Notification.Name("queueCleared")
    
    /// Notification when edit message is requested
    static let editMessageRequested = Notification.Name("editMessageRequested")
}