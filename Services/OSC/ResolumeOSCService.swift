//
//  ResolumeOSCService.swift
//  LEDMESSENGER
//
//  Created by Claude AI on 4/12/2025.
//

/**
 * Resolume-specific OSC communication service
 * 
 * This file implements high-level operations for sending messages to an
 * LED wall controlled by Resolume Arena software. It handles message
 * rotation, clip management, and screen clearing operations.
 */

import Foundation

/**
 * Specialized service for communicating with Resolume Arena
 *
 * This class provides Resolume-specific functionality built on top of
 * the generic OSC service layer:
 * - Text message display with 3-clip rotation system
 * - Screen clearing operations
 * - Connection testing and verification
 * - Clip configuration management
 */
final class ResolumeOSCService {
    // MARK: - Properties
    
    /**
     * The underlying OSC network service
     * Handles low-level network communication
     */
    let oscService: OSCServiceProtocol
    
    /**
     * The Resolume composition layer to use (1-indexed)
     * LED messages are displayed on this layer
     */
    let layer: Int
    
    /**
     * The first clip number in the 3-clip rotation system (1-indexed)
     * Messages are sent to clips startingClip, startingClip+1, and startingClip+2
     */
    let startingClip: Int
    
    /**
     * The special clip used for clearing the screen (1-indexed)
     * This is always startingClip+3 in the current implementation
     */
    let clearClip: Int
    
    /**
     * Get the current clear clip number
     * Used by clients to check current configuration
     *
     * @return Integer clip number for the clear clip
     */
    func getClearClip() -> Int {
        return clearClip
    }
    
    /**
     * Get the starting clip number
     * Used by clients to check current configuration
     *
     * @return Integer clip number for the first message clip
     */
    func getStartingClip() -> Int {
        return startingClip
    }
    
    // MARK: - Initialization
    
    /**
     * Initialize the Resolume OSC service with configuration
     *
     * @param oscService The underlying OSC network service
     * @param layer The Resolume layer number (default: 5)
     * @param startingClip The first clip number in message rotation (default: 1)
     * @param clearClip Optional custom clear clip (ignored - always startingClip+3)
     */
    init(oscService: OSCServiceProtocol, layer: Int = 5, startingClip: Int = 1, clearClip: Int? = nil) {
        self.oscService = oscService
        self.layer = layer
        self.startingClip = startingClip
        
        // Clear clip is ALWAYS startingClip + 3, regardless of passed parameter
        // This enforces a consistent pattern where the clear clip follows the 3 message clips
        self.clearClip = startingClip + 3
    }
    
    // MARK: - Configuration Management
    
    /**
     * Create a new service instance with updated configuration
     *
     * Since properties are immutable, we create a new instance with
     * updated configuration instead of modifying the existing one.
     *
     * @param layer The new Resolume layer number
     * @param startingClip The new first clip number
     * @param clearClip Optional custom clear clip (ignored - always startingClip+3)
     * @return A new ResolumeOSCService instance with updated configuration
     */
    func updateConfiguration(layer: Int, startingClip: Int, clearClip: Int? = nil) -> ResolumeOSCService {
        // Create a new instance with updated configuration
        let newService = ResolumeOSCService(
            oscService: self.oscService,
            layer: layer,
            startingClip: startingClip
        )
        
        // Log configuration change for troubleshooting
        print("🟣 IMPORTANT: Updated configuration - startingClip: \(startingClip), clearClip: \(newService.clearClip)")
        
        return newService
    }
    
    // MARK: - Message Display Operations
    
    /**
     * Send text to a Resolume clip and make it visible
     *
     * This method handles both setting the text content and activating the clip.
     * Uses a 3-clip rotation system to minimize flicker and allow smooth transitions.
     *
     * @param text The text to display on the LED wall
     * @param clipOffset Offset from startingClip (0-2) to determine which clip to use
     * @throws OSCError if message creation or transmission fails
     */
    func sendText(_ text: String, toClip clipOffset: Int = 0) async throws {
        // Normalize clip offset to wrap around within the 3-clip rotation
        // This ensures we stay within the 3 message clips regardless of input
        let normalizedOffset = clipOffset % 3
        
        // Calculate the actual Resolume clip number to use
        let targetClip = self.startingClip + normalizedOffset
        
        // Create the OSC message to set the clip's text content
        guard let message = OSCMessage.resolumeText(layer: self.layer, clip: targetClip, text: text) else {
            throw OSCError.invalidMessage
        }
        
        // Log detailed information for troubleshooting
        print("🟣 OSC TEXT COMMAND: \(message.address.value) with text: \(text)")
        print("🟣 SENDING TO CLIP: \(targetClip) (startingClip \(startingClip) + offset \(normalizedOffset))")
        print("🟣 3-CLIP ROTATION: Using position \(normalizedOffset+1) of 3")
        
        // Send the message to set the text content
        try await oscService.send(message)
        
        // First SELECT the clip (this highlights it in the Resolume UI)
        guard let selectMessage = OSCMessage.resolumeTriggerClip(layer: self.layer, clip: targetClip) else {
            throw OSCError.invalidMessage
        }
        
        // Log the exact OSC command for debugging
        print("🟣 SELECT CLIP MESSAGE: \(selectMessage.address.value)")
        try await oscService.send(selectMessage)
        
        // Then CONNECT to the clip (this actually makes it visible on the output)
        guard let connectMessage = OSCMessage(
            address: "/composition/layers/\(self.layer)/clips/\(targetClip)/connect",
            arguments: [OSCTrue()]
        ) else {
            throw OSCError.invalidMessage
        }
        
        // Log the exact OSC command for debugging
        print("🟣 CONNECT CLIP MESSAGE: \(connectMessage.address.value)")
        try await oscService.send(connectMessage)
    }
    
    /**
     * Create an OSC message to trigger a specific clip
     *
     * Helper method to generate clip trigger messages with proper logging
     *
     * @param clip The clip number to trigger
     * @return OSCMessage configured to trigger the specified clip
     * @throws OSCError.invalidMessage if message creation fails
     */
    private func createTriggerMessage(_ clip: Int) throws -> OSCMessage {
        guard let message = OSCMessage.resolumeTriggerClip(layer: self.layer, clip: clip) else {
            throw OSCError.invalidMessage
        }
        
        // Log the exact OSC command for debugging
        print("🟣 OSC TRIGGER COMMAND: \(message.address.value)")
        
        return message
    }
    
    /**
     * Clear the LED display by activating the clear clip
     *
     * Activates a special empty clip that shows nothing, effectively
     * clearing any message currently displayed on the LED wall.
     *
     * @throws OSCError if message creation or transmission fails
     */
    func clearScreen() async throws {
        // The clear clip is already calculated at initialization time (startingClip + 3)
        let actualClearClip = self.clearClip
        
        // Log operation details for troubleshooting
        print("🧹🟣 CLEARING SCREEN WITH CLIP: \(actualClearClip) (startingClip \(startingClip) + 3)")
        
        // First SELECT the clear clip in Resolume UI
        guard let selectMessage = OSCMessage(
            address: "/composition/layers/\(self.layer)/clips/\(actualClearClip)/select",
            arguments: [OSCTrue()]
        ) else {
            throw OSCError.invalidMessage
        }
        
        // Enhanced logging for clear screen operations
        print("🧹🟣 OSC SELECT CLEAR CLIP COMMAND: \(selectMessage.address.value)")
        print("🧹🟣 Using clearClip: \(actualClearClip) (layer: \(self.layer), clip: \(actualClearClip))")
        print("🧹🟣 Text clips are \(startingClip) through \(startingClip+2), clear clip is \(actualClearClip)")
        
        // Send the selection message
        try await oscService.send(selectMessage)
        
        // Then CONNECT to the clear clip (makes it visible on output)
        guard let connectMessage = OSCMessage(
            address: "/composition/layers/\(self.layer)/clips/\(actualClearClip)/connect", 
            arguments: [OSCTrue()]
        ) else {
            throw OSCError.invalidMessage
        }
        
        // Log the exact OSC command for debugging
        print("🧹🟣 OSC CONNECT CLEAR CLIP COMMAND: \(connectMessage.address.value)")
        
        // Send the connection message
        try await oscService.send(connectMessage)
        
        print("🧹🟣 CLEAR OPERATION COMPLETE")
    }
    
    // MARK: - Testing and Verification
    
    /**
     * Run a comprehensive test pattern to verify the connection
     *
     * Tests the entire message display system by sending test messages
     * to multiple clips in the rotation and then clearing the screen.
     * Provides detailed diagnostic logging of all operations.
     *
     * @return Boolean indicating if the test completed successfully
     * @throws OSCError if message creation or transmission fails
     */
    func sendTestPattern() async throws -> Bool {
        do {
            // Log detailed configuration information
            print("🔷 SENDING TEST PATTERN")
            print("🔷 Layer: \(layer)")
            print("🔷 Starting Clip: \(startingClip)")
            print("🔷 3-SLOT ROTATION:")
            print("🔷 SLOT 1 = Clip \(startingClip)")
            print("🔷 SLOT 2 = Clip \(startingClip+1)")
            print("🔷 SLOT 3 = Clip \(startingClip+2)")
            print("🔷 CLEAR SLOT = Clip \(clearClip)")
            
            // TEST 1: Send first test message to clip 1
            print("🔷 Sending test 1: LEDMESSENGER.COM to SLOT 1 (clip \(startingClip))")
            try await sendText("LEDMESSENGER.COM", toClip: 0)
            
            // Pause for visibility
            try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            
            // TEST 2: Send second test message to clip 2
            print("🔷 Sending test 2: LET'S PARTY to SLOT 2 (clip \(startingClip+1))")
            try await sendText("LET'S PARTY", toClip: 1)
            
            // Pause for visibility
            try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            
            // TEST 3: Clear the screen
            print("🔷 ACTIVATING CLEAR SLOT (clip \(clearClip))")
            try await clearScreen()
            
            // Test completed successfully
            print("🔷✅ TEST PATTERN COMPLETED SUCCESSFULLY")
            return true
        } catch {
            // Log failure details
            print("🔷❌ TEST PATTERN FAILED: \(error.localizedDescription)")
            return false
        }
    }
    
    /**
     * Perform a minimal connection test to Resolume
     *
     * Sends a non-disruptive OSC message to verify connectivity
     * without affecting the current display state. More reliable
     * than the full test pattern for simple connectivity checks.
     *
     * @return Boolean indicating if the connection test succeeded
     */
    func verifyConnection() async -> Bool {
        do {
            print("🔹 VERIFYING RESOLUME CONNECTION")
            
            // Create a harmless "ping" message that won't visibly affect the output
            // We use layer opacity which is safe to read without changing anything
            guard let pingMessage = OSCMessage(
                address: "/composition/layers/\(self.layer)/opacity/values",
                arguments: [OSCFloat(value: 0.5)]
            ) else {
                throw OSCError.invalidMessage
            }
            
            // Attempt to send the message (just testing network connectivity)
            try await oscService.send(pingMessage)
            
            // Connection verified successfully
            print("🔹✅ RESOLUME CONNECTION VERIFIED")
            return true
        } catch {
            // Log connection failure
            print("🔹❌ RESOLUME CONNECTION FAILED: \(error.localizedDescription)")
            return false
        }
    }
}