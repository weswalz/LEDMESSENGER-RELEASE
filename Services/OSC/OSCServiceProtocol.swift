//
//  OSCServiceProtocol.swift
//  CLAUDELED
//
//  Created by Claude AI on 4/12/2025.
//

import Foundation
import Combine

/// Protocol defining the interface for OSC communication services
protocol OSCServiceProtocol {
    /// The current connection state
    var connectionState: ConnectionState { get }
    
    /// Publisher for the connection state
    var connectionStatePublisher: AnyPublisher<ConnectionState, Never> { get }
    
    /// Connect to the OSC endpoint
    func connect() async
    
    /// Disconnect from the OSC endpoint
    func disconnect()
    
    /// Send an OSC message
    func send(_ message: OSCMessage) async throws
    
    /// Send an OSC bundle
    func send(_ bundle: OSCBundle) async throws
    
    /// Update the target endpoint
    func updateEndpoint(host: String, port: Int)
}