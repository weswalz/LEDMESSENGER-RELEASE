//
//  OSCSettings.swift
//  CLAUDELED
//
//  Created by Claude AI on 4/12/2025.
//

import Foundation

/// Settings related to OSC communication
struct OSCSettings: Codable, Equatable {
    /// The host address (IP or hostname) for the OSC server
    var host: String = "127.0.0.1"
    
    /// Alias for host for backward compatibility
    var ipAddress: String {
        get { host }
        set { host = newValue }
    }
    
    /// The port number for the OSC server
    var port: Int = 2269
    
    /// The Resolume layer number to use
    var layer: Int = 5
    
    /// The starting clip number for messages
    var startingClip: Int = 1
    
    /// The clip number to use for clearing the screen
    var clearClip: Int {
        get { return startingClip + 3 }
        set { /* Ignored - always calculated from startingClip */ }
    }
    
    /// Whether to automatically reconnect on launch
    var autoConnect: Bool = true
    
    /// Initialize with default settings
    init() {}
    
    /// Initialize with custom settings
    init(host: String = "127.0.0.1", port: Int = 2269, layer: Int = 5, startingClip: Int = 1, clearClip: Int = 6, autoConnect: Bool = true) {
        self.host = host
        self.port = port
        self.layer = layer
        self.startingClip = startingClip
        self.clearClip = clearClip
        self.autoConnect = autoConnect
    }
    
    /// Initialize with custom settings using ipAddress (backwards compatibility)
    init(ipAddress: String, port: Int, layer: Int, startingClip: Int, clearClip: Int, autoConnect: Bool) {
        self.host = ipAddress
        self.port = port
        self.layer = layer
        self.startingClip = startingClip
        self.clearClip = clearClip
        self.autoConnect = autoConnect
    }
    
    /// Default settings
    static func defaultSettings() -> OSCSettings {
        return OSCSettings()
    }
    
    /// Validate settings
    func validate() -> Bool {
        let validPort = port > 0 && port < 65536
        let validLayer = layer > 0
        let validClips = startingClip > 0 && clearClip > 0
        
        return validPort && validLayer && validClips
    }
}