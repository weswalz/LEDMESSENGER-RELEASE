//
//  OSCError.swift
//  CLAUDELED
//
//  Created by Claude AI on 4/12/2025.
//

import Foundation

/// Errors that can occur during OSC operations
enum OSCError: Error, LocalizedError {
    /// Attempted to send a message when not connected
    case notConnected
    
    /// Failed to send OSC message with an underlying error
    case sendFailed(Error)
    
    /// Attempted to create or send an invalid OSC message
    case invalidMessage
    
    /// Failed to establish connection to OSC endpoint
    case connectionFailed
    
    /// Timeout while waiting for response or connection
    case timeout
    
    /// Network interface or address not found
    case networkUnavailable
    
    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Not connected to OSC endpoint. Please check connection settings."
        case .sendFailed(let error):
            return "Failed to send OSC message: \(error.localizedDescription)"
        case .invalidMessage:
            return "Invalid OSC message format. Please check message parameters."
        case .connectionFailed:
            return "Failed to connect to OSC endpoint. Please verify the IP address and port."
        case .timeout:
            return "Connection timed out. Please check that Resolume is running and accessible."
        case .networkUnavailable:
            return "Network interface unavailable. Please check your network connection."
        }
    }
}