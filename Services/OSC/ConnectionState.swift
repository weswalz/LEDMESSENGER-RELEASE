//
//  ConnectionState.swift
//  CLAUDELED
//
//  Created by Claude AI on 4/12/2025.
//

import Foundation

/**
 * Represents the connection state of an OSC service
 *
 * Tracks the current status of the connection to the OSC endpoint,
 * providing a way to monitor connection status and handle errors.
 */
enum ConnectionState: String {
    /// Not connected to the OSC endpoint
    case disconnected
    
    /// Currently attempting to establish connection
    case connecting
    
    /// Successfully connected to the OSC endpoint
    case connected
    
    /// Connection attempt failed
    case failed
    
    /**
     * Whether the connection is active and usable
     */
    var isActive: Bool {
        self == .connected
    }
    
    /**
     * User-friendly description of the connection state
     */
    var description: String {
        switch self {
        case .disconnected:
            return "Not connected to OSC endpoint"
        case .connecting:
            return "Connecting to OSC endpoint..."
        case .connected:
            return "Connected to OSC endpoint"
        case .failed:
            return "Connection to OSC endpoint failed"
        }
    }
}