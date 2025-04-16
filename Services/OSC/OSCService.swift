//
//  OSCService.swift
//  LEDMESSENGER
//
//  Created by Claude AI on 4/12/2025.
//

/**
 * Core OSC (Open Sound Control) communication service
 * 
 * This file implements the low-level OSC protocol communication using
 * Apple's Network framework. It handles connection management and
 * message transmission to the Resolume LED wall controller.
 */

import Foundation
import Network
import Combine

/**
 * Implementation of OSC network service using Apple's Network framework
 *
 * This class provides UDP-based OSC protocol communication, handling:
 * - Connection management to the OSC endpoint
 * - Connection state tracking and publishing
 * - Message and bundle encoding and transmission
 * - Error handling and reporting
 */
final class OSCService: OSCServiceProtocol {
    // MARK: - Properties
    
    /**
     * Connection state publisher for reactive state monitoring
     * Uses Combine framework to publish connection state changes
     */
    private let connectionStateSubject = CurrentValueSubject<ConnectionState, Never>(.disconnected)
    
    /**
     * Public publisher for connection state changes
     * Allows other components to subscribe to connection state updates
     */
    var connectionStatePublisher: AnyPublisher<ConnectionState, Never> {
        connectionStateSubject.eraseToAnyPublisher()
    }
    
    /**
     * Current connection state property
     * Provides synchronous access to the current connection state
     */
    var connectionState: ConnectionState {
        connectionStateSubject.value
    }
    
    /**
     * Dedicated dispatch queue for network operations
     * Ensures network tasks don't block the main thread
     */
    private let queue = DispatchQueue(label: "com.ledmessenger.osc.network", qos: .userInitiated)
    
    /**
     * Active network connection to the OSC endpoint
     * Managed by Network framework
     */
    private var connection: NWConnection?
    
    /**
     * Network endpoint host for the OSC server
     * Usually Resolume running on a target machine
     */
    private var host: NWEndpoint.Host
    
    /**
     * Network endpoint port for the OSC server
     * Standard OSC port for Resolume Arena
     */
    private var port: NWEndpoint.Port
    
    // MARK: - Initialization
    
    /**
     * Initialize the OSC service with specified host and port
     *
     * @param host The hostname or IP address of the OSC server (default: localhost)
     * @param port The UDP port number for OSC communication (default: 2269 for Resolume)
     */
    init(host: String = "127.0.0.1", port: Int = 2269) {
        self.host = NWEndpoint.Host(host)
        self.port = NWEndpoint.Port(integerLiteral: UInt16(port))
    }
    
    // MARK: - Connection Management
    
    /**
     * Establish connection to the OSC endpoint
     *
     * Creates and starts a UDP connection to the configured endpoint.
     * Updates connection state based on connection lifecycle events.
     * Does nothing if already connected or in the process of connecting.
     */
    func connect() async {
        // Avoid duplicate connection attempts
        guard connectionState == .disconnected || connectionState == .failed else {
            return
        }
        
        // Update state to reflect connection attempt
        connectionStateSubject.send(.connecting)
        
        // Create a new UDP connection to the configured endpoint
        let connection = NWConnection(
            host: host,
            port: port,
            using: .udp
        )
        
        // Set up handler to track connection state changes
        connection.stateUpdateHandler = { [weak self] state in
            guard let self = self else { return }
            
            // Update published state based on Network framework connection state
            switch state {
            case .ready:
                self.connectionStateSubject.send(.connected)
            case .failed:
                self.connectionStateSubject.send(.failed)
            case .cancelled:
                self.connectionStateSubject.send(.disconnected)
            default:
                // Other states (preparing, waiting, etc.) don't trigger state changes
                break
            }
        }
        
        // Start the connection on the dedicated queue
        connection.start(queue: queue)
        
        // Store reference to active connection
        self.connection = connection
    }
    
    /**
     * Disconnect from the OSC endpoint
     *
     * Cancels any active connection and updates connection state.
     * Safe to call even if not currently connected.
     */
    func disconnect() {
        // Cancel the connection if it exists
        connection?.cancel()
        connection = nil
        
        // Update connection state
        connectionStateSubject.send(.disconnected)
    }
    
    /**
     * Update the target OSC endpoint
     *
     * Changes the host and port to connect to, disconnecting any
     * existing connection and initiating a new one.
     *
     * @param host The new hostname or IP address
     * @param port The new port number
     */
    func updateEndpoint(host: String, port: Int) {
        // Ensure clean disconnection first
        disconnect()
        
        // Update endpoint configuration
        self.host = NWEndpoint.Host(host)
        self.port = NWEndpoint.Port(integerLiteral: UInt16(port))
        
        // Initiate new connection with updated endpoint
        Task {
            await connect()
        }
    }
    
    // MARK: - Message Sending
    
    /**
     * Send an OSC message to the endpoint
     *
     * Encodes and transmits a single OSC message via UDP.
     * Provides detailed logging for debugging purposes.
     *
     * @param message The OSC message to send
     * @throws OSCError if not connected or if send operation fails
     */
    func send(_ message: OSCMessage) async throws {
        // Verify connection is established
        guard let connection = connection else {
            print("❌ OSC ERROR: Not connected to \(host):\(port)")
            throw OSCError.notConnected
        }
        
        // Encode the message to binary data according to OSC spec
        let data = message.encode()
        
        // Log detailed information about the message being sent
        print("📤 OSC SENDING: \(message.address.value) to \(host):\(port) with \(message.arguments.count) arguments")
        if !message.arguments.isEmpty, let textArg = message.arguments.first as? OSCString {
            print("📝 OSC CONTENT: \"\(textArg.value)\"")
        }
        
        // Convert the NWConnection callback-based API to Swift concurrency
        return try await withCheckedThrowingContinuation { continuation in
            // Send the message data
            connection.send(content: data, completion: .contentProcessed { error in
                if let error = error {
                    // Handle send failure
                    print("❌ OSC SEND FAILED: \(error.localizedDescription)")
                    continuation.resume(throwing: OSCError.sendFailed(error))
                } else {
                    // Handle successful send
                    print("✅ OSC SENT SUCCESSFULLY")
                    continuation.resume(returning: ())
                }
            })
        }
    }
    
    /**
     * Send an OSC bundle to the endpoint
     *
     * Encodes and transmits a bundle of OSC messages via UDP.
     * OSC bundles allow multiple messages to be sent with precise timing.
     *
     * @param bundle The OSC bundle to send
     * @throws OSCError if not connected or if send operation fails
     */
    func send(_ bundle: OSCBundle) async throws {
        // Verify connection is established
        guard let connection = connection else {
            throw OSCError.notConnected
        }
        
        // Encode the bundle to binary data according to OSC spec
        let data = bundle.encode()
        
        // Convert the NWConnection callback-based API to Swift concurrency
        return try await withCheckedThrowingContinuation { continuation in
            // Send the bundle data
            connection.send(content: data, completion: .contentProcessed { error in
                if let error = error {
                    // Handle send failure
                    continuation.resume(throwing: OSCError.sendFailed(error))
                } else {
                    // Handle successful send
                    continuation.resume(returning: ())
                }
            })
        }
    }
}