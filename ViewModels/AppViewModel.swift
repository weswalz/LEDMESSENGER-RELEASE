//
//  AppViewModel.swift
//  LEDMESSENGER
//
//  Created by clubkit.io on 4/12/2025.
//

/**
 * Main application view model that coordinates functionality
 * across the app and manages state transitions.
 */

import Foundation
import Combine
import OSLog
import SwiftUI

/// Test function to send OSC messages directly
func testOSCMessages() async {
    print("⚡️ SENDING TEST OSC MESSAGES ⚡️")
    
    let oscService = OSCService(host: "127.0.0.1", port: 7000)
    
    do {
        await oscService.connect()
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        print("🔹 SENDING MESSAGE 1: LEDMESSENGER.COM")
        // Direct OSC address for text content in Resolume (layer 1, clip 1)
        let textOSC = OSCMessage(
            address: "/composition/layers/1/clips/1/video/source/textgenerator/text/params/lines",
            arguments: [OSCString(value: "LEDMESSENGER.COM")]
        )
        try await oscService.send(textOSC!)
        
        // Trigger that clip
        let triggerOSC = OSCMessage(address: "/composition/layers/1/clips/1/connect")
        try await oscService.send(triggerOSC!)
        
        try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
        
        print("🔹 SENDING MESSAGE 2: LET'S PARTY")
        // Direct OSC address for text content in Resolume (layer 1, clip 2)
        let textOSC2 = OSCMessage(
            address: "/composition/layers/1/clips/2/video/source/textgenerator/text/params/lines",
            arguments: [OSCString(value: "LET'S PARTY")]
        )
        try await oscService.send(textOSC2!)
        
        // Trigger that clip
        let triggerOSC2 = OSCMessage(address: "/composition/layers/1/clips/2/connect")
        try await oscService.send(triggerOSC2!)
        
        try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
        
        print("🔹 CLEARING SCREEN")
        // Clear screen by triggering empty clip
        let clearOSC = OSCMessage(address: "/composition/layers/1/clips/6/connect")
        try await oscService.send(clearOSC!)
        
        print("✅ TEST COMPLETE")
    } catch {
        print("❌ TEST FAILED: \(error)")
    }
}

/**
 * Defines the main states of the application UI flow
 * Controls which main view is displayed to the user
 */
enum AppState {
    /// Initial setup and configuration phase
    case setup
    
    /// Main message creation and queue management phase
    case messageManagement
    
    /// App appearance and behavior customization phase
    case customization
}

/**
 * Main application view model that coordinates UI state
 * and manages communication between components.
 */
@MainActor
final class AppViewModel: ObservableObject, PeerServiceDelegate {
    // MARK: - Published Properties
    
    /// Current app state controlling which main view is shown
    @Published var appState: AppState = .setup
    
    /// Whether initial setup has been completed
    @Published var setupCompleted = false
    
    /// Connection status to Resolume OSC endpoint
    @Published var connectionStatus: ConnectionState = .disconnected
    
    /// Whether technical debug information is displayed
    @Published var showDebugInfo = false
    
    /// Current iPad mode (solo or paired)
    @Published var appMode: AppMode = .paired
    
    /// Whether to show mode selection view - default to true for iPad
    @Published var shouldShowModeSelection = true
    
    /// Status message displayed during setup process
    @Published var setupStatusMessage = "Starting..."
    
    /// Tracks if initial setup was completed in this app session
    /// Used to avoid sending test messages on every setup visit
    @Published var initialSetupCompletedThisSession = false
    
    /// Status of peer device connection (iPad-Mac connectivity)
    @Published var peerConnectionStatus = false
    
    // MARK: - Service and Manager Properties
    
    /// Message view model for managing message queue
    let messageViewModel: MessageViewModel
    
    /// Settings manager for persistent app configuration
    let settingsManager: SettingsManager
    
    /// Low-level OSC network communication service
    private let oscService: OSCService
    
    /// Resolume-specific OSC service for LED wall communication
    private var resolumeService: ResolumeOSCService
    
    /// Peer-to-peer connectivity service
    private var peerService: PeerService?
    
    /// Storage for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    /// Logging instance for debug and error tracking
    private let logger = Logger(subsystem: "com.ledmessenger.app", category: "viewmodel")
    
    // MARK: - Initialization
    
    /**
     * Initialize the app view model with all required services
     * Sets up dependencies and establishes connections
     */
    init() {
        // Initialize settings manager first as other services depend on settings
        let settings = SettingsManager()
        self.settingsManager = settings
        
        // Create OSC network service with settings
        let osc = OSCService(
            host: settings.settings.osc.host,
            port: settings.settings.osc.port
        )
        self.oscService = osc
        
        // Create Resolume-specific service for LED wall control
        let resolume = ResolumeOSCService(
            oscService: osc,
            layer: settings.settings.osc.layer,
            startingClip: settings.settings.osc.startingClip,
            clearClip: settings.settings.osc.clearClip
        )
        self.resolumeService = resolume
        
        // Create message view model for queue management
        let messages = MessageViewModel(
            resolumeService: resolume,
            settingsManager: settings
        )
        self.messageViewModel = messages
        
        // Load app mode settings for iPad
        #if os(iOS)
        // Check for stored mode selection from previous session
        if let selectedMode = UserDefaults.standard.string(forKey: "selectedAppMode") {
            // Process stored mode selection
            if selectedMode == "solo" {
                // Solo mode - set proper state for dedicated iPad Solo view
                appMode = .solo
                setupCompleted = false  // Always start with setup in solo mode
                initialSetupCompletedThisSession = false
                appState = .setup
                shouldShowModeSelection = false
                logger.info("Initialized in SOLO mode from UserDefaults")
                print("DEBUG: Loading previously selected SOLO mode, state=\(appState)")
            } else {
                // Paired mode - go directly to message management
                appMode = .paired
                setupCompleted = true
                appState = .messageManagement
                shouldShowModeSelection = false
                logger.info("Initialized in PAIRED mode from UserDefaults")
                print("DEBUG: Loading previously selected PAIRED mode, state=\(appState)")
            }
        } else {
            // No selected mode yet - show mode selection
            appMode = settings.settings.mode.currentMode
            shouldShowModeSelection = true
            
            // Clear setup flags to ensure mode selection shows
            UserDefaults.standard.removeObject(forKey: "com.ledmessenger.hasLaunchedBefore")
            UserDefaults.standard.removeObject(forKey: "com.ledmessenger.completedModeSetup")
            
            logger.info("No mode selection found, showing mode selector")
            print("DEBUG: No stored mode selection, showing mode selector")
        }
        #endif
        
        // Configure platform-specific initial app state
        #if os(macOS)
        // macOS always starts with setup screen as it's the configuration device
        setupCompleted = false
        appState = .setup
        #else
        // iOS (iPad) depends on mode setting
        if appMode == .solo {
            // Solo mode starts with setup like macOS
            setupCompleted = false
            appState = .setup
        } else {
            // Paired mode goes straight to message management
            setupCompleted = true
            appState = .messageManagement
        }
        #endif
        
        // Load debug mode state from settings
        #if os(macOS)
        // On macOS, load from settings
        showDebugInfo = settings.settings.appearance.showDebug
        #else
        // On iOS, always keep debug info off
        showDebugInfo = false
        // Reset the setting to ensure it stays off
        settings.updateAppearanceSettings(showDebug: false)
        #endif
        
        // Subscribe to OSC connection state changes
        oscService.connectionStatePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                self?.connectionStatus = state
            }
            .store(in: &cancellables)
        
        // Start OSC connection
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                await self.oscService.connect()
            }
        }
        
        // Initialize peer-to-peer connectivity based on mode
        #if os(macOS)
        // Mac always uses peer connectivity
        startPeerConnectivity()
        #else
        // iPad depends on mode
        if appMode == .paired {
            startPeerConnectivity()
        }
        #endif
        
        // Set up additional sync mechanism for iPad in paired mode
        #if !os(macOS)
        if appMode == .paired {
            setupRegularQueueSync()
        }
        #endif
        
        // Set up notification observers for message events
        setupNotificationHandlers()
    }
    
    
    /**
     * Set up a timer to periodically sync the message queue with peers
     * Only used on iPad to ensure the Mac has the latest messages
     */
    private func setupRegularQueueSync() {
        #if !os(macOS)
        // Create a timer that fires every 15 seconds
        Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { [weak self] _ in
            // Use Task to safely access MainActor-isolated properties
            Task { @MainActor [weak self] in
                guard let self = self, self.peerConnectionStatus else { return }
                
                // Only sync if there are messages in the queue
                if !self.messageViewModel.messages.isEmpty {
                    self.syncMessageQueueWithPeers()
                }
            }
        }
        #endif
    }
    
    /**
     * Request OSC settings from paired Mac when connection is established
     * iPad-only functionality as it receives settings from Mac
     */
    @MainActor
    private func requestSettingsFromPeers() async {
        #if !os(macOS)
        // Brief delay after connection before requesting settings
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        // Note: Currently relies on Mac proactively sending settings
        // Future improvement: Add explicit settings request message type
        #endif
    }
    
    /**
     * Set up notification handlers for message queue changes
     * Allows peer devices to stay in sync when messages are modified
     */
    private func setupNotificationHandlers() {
        // Handle message added to queue
        NotificationCenter.default.addObserver(
            forName: .messageAdded,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self, let message = notification.userInfo?["message"] as? Message else {
                return
            }
            
            // Notify peers of the added message
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.peerService?.notifyMessageAdded(message)
            }
        }
        
        // Handle message cancelled/removed from queue
        NotificationCenter.default.addObserver(
            forName: .messageCancelled,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self, let messageId = notification.userInfo?["messageId"] as? UUID else {
                return
            }
            
            // Notify peers of the cancelled message
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.peerService?.notifyMessageCancelled(messageId)
            }
        }
        
        // Handle message sent to LED wall
        NotificationCenter.default.addObserver(
            forName: .messageSent,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self, 
                  let message = notification.userInfo?["message"] as? Message else {
                return
            }
            
            // Get current slot from notification
            let currentSlot = notification.userInfo?["currentSlot"] as? Int
            
            // Notify peers of the sent message including the current slot
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.peerService?.notifyMessageSent(message, currentClipSlot: currentSlot)
            }
        }
        
        // Handle message updated (edited)
        NotificationCenter.default.addObserver(
            forName: .messageUpdated,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self, let message = notification.userInfo?["message"] as? Message else {
                return
            }
            
            // Get current slot from notification
            let currentSlot = notification.userInfo?["currentSlot"] as? Int
            
            // Notify peers of the updated message
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.peerService?.notifyMessageSent(message, currentClipSlot: currentSlot)
            }
        }
        
        // Handle entire queue cleared
        NotificationCenter.default.addObserver(
            forName: .queueCleared,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else {
                return
            }
            
            // Notify peers of the cleared queue
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.peerService?.notifyQueueCleared()
            }
        }
    }
    
    // MARK: - Setup Methods
    
    /**
     * Complete the initial setup process
     * Validates connection to Resolume and transitions to message management
     */
    func completeSetup() {
        // Use dispatch queue for better thread management
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Start setup process on main thread for UI
            self.setupStatusMessage = "Initializing connection..."
            
            // Launch the setup task
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                // Get all settings safely once
                let host = self.settingsManager.settings.osc.host
                let port = self.settingsManager.settings.osc.port
                let layer = self.settingsManager.settings.osc.layer
                let startingClip = self.settingsManager.settings.osc.startingClip
                let clearClip = self.settingsManager.settings.osc.clearClip
                
                // Update OSC service with current settings
                self.oscService.updateEndpoint(
                    host: host,
                    port: port
                )
                
                // Update Resolume service with current settings
                // Creates a new instance since properties are immutable
                let updatedService = self.resolumeService.updateConfiguration(
                    layer: layer,
                    startingClip: startingClip,
                    clearClip: clearClip
                )
                
                // Use MainActor for UI updates
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    
                    // Replace services with updated instances
                    self.resolumeService = updatedService
                    self.messageViewModel.updateResolumeService(updatedService)
                }
                
                // Try up to 3 connection attempts with safe thread handling
                for attempt in 1...3 {
                    // UI update on main thread
                    await MainActor.run { [weak self] in
                        guard let self = self else { return }
                        self.setupStatusMessage = "Connecting (attempt \(attempt)/3)..."
                    }
                    
                    // Connect with await
                    await self.oscService.connect()
                    
                    // Poll connection status for up to 2 seconds
                    for _ in 0..<20 {
                        // Safely check connection on main thread
                        let isConnected = await MainActor.run { [weak self] in
                            guard let self = self else { return false }
                            return self.connectionStatus == .connected
                        }
                        
                        if isConnected {
                            break
                        }
                        
                        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                    }
                    
                    // Check if connected using MainActor to access state safely
                    let isConnected = await MainActor.run { [weak self] in
                        guard let self = self else { return false }
                        return self.connectionStatus == .connected
                    }
                    
                    // Exit retry loop if connected
                    if isConnected {
                        break
                    }
                }
                
                // Check connection state on MainActor
                let finalConnected = await MainActor.run { [weak self] in
                    guard let self = self else { return false }
                    return self.connectionStatus == .connected
                }
                
                // Final result handling
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    
                    // Verify connection established successfully
                    if finalConnected {
                        self.setupStatusMessage = "Testing connection..."
                        
                        // Only send test messages on first setup this session
                        let shouldSendTestMessages = !self.initialSetupCompletedThisSession
                        
                        // Launch test message task
                        Task { @MainActor [weak self] in
                            guard let self = self else { return }
                            
                            if shouldSendTestMessages {
                                do {
                                    // Send test pattern to verify communication
                                    let testResult = try await self.resolumeService.sendTestPattern()
                                    
                                    // Back to main thread for UI
                                    await MainActor.run { [weak self] in
                                        guard let self = self else { return }
                                        
                                        if testResult {
                                            self.setupStatusMessage = "Test pattern successful! Connection verified. Setup complete!"
                                        } else {
                                            self.setupStatusMessage = "Test pattern completed with errors. Check console for details."
                                        }
                                        
                                        // Complete setup
                                        self.finalizeSetup()
                                    }
                                } catch {
                                    // Error handling on main thread
                                    await MainActor.run { [weak self] in
                                        guard let self = self else { return }
                                        self.setupStatusMessage = "Error testing connection: \(error.localizedDescription)"
                                        self.logger.error("Setup test failed: \(error.localizedDescription)")
                                        self.finalizeSetup()
                                    }
                                }
                            } else {
                                // Skip test messages on subsequent setups in this session
                                await MainActor.run { [weak self] in
                                    guard let self = self else { return }
                                    self.setupStatusMessage = "Connection verified. Setup complete! (Test messages skipped)"
                                    self.finalizeSetup()
                                }
                            }
                        }
                    } else {
                        // Failed to connect after multiple attempts
                        self.setupStatusMessage = "Connection failed. Please check settings and try again."
                        self.logger.error("Setup connection failed")
                    }
                }
            }
        }
    }
    
    /**
     * Helper to finalize setup after connection
     * Extracted to make thread safety clearer
     */
    @MainActor private func finalizeSetup() {
        // Mark setup as completed both for session and persistently
        initialSetupCompletedThisSession = true
        UserDefaults.standard.set(true, forKey: "setupCompleted")
        setupCompleted = true
        
        // Transition to main app interface
        appState = .messageManagement
    }
    
    /**
     * Reset setup to start configuration from scratch
     * Clears persistent settings and resets UI state
     */
    func resetSetup() {
        UserDefaults.standard.removeObject(forKey: "setupCompleted")
        setupCompleted = false
        initialSetupCompletedThisSession = false
        appState = .setup
        setupStatusMessage = "Setup reset."
    }
    
    // MARK: - Navigation Methods
    
    /**
     * Navigate to setup/configuration screen
     */
    func navigateToSetup() {
        appState = .setup
    }
    
    /**
     * Navigate to message management screen
     */
    func navigateToMessageManagement() {
        appState = .messageManagement
    }
    
    /**
     * Navigate to customization/settings screen
     */
    func navigateToCustomization() {
        appState = .customization
    }
    
    // MARK: - App Mode Methods
    
    /**
     * Set the application mode (SOLO or PAIRED)
     * Updates app behavior and initializes/terminates services as needed
     *
     * @param mode The new app mode to apply
     */
    func setAppMode(_ mode: AppMode) {
        // Skip if already in this mode
        if mode == self.appMode {
            return
        }
        
        logger.info("Changing app mode from \(self.appMode.rawValue) to \(mode.rawValue)")
        
        // Update app mode
        self.appMode = mode
        
        // Persist the app mode selection to UserDefaults for app restarts
        UserDefaults.standard.set(mode == .solo ? "solo" : "paired", forKey: "selectedAppMode")
        
        // Update settings
        settingsManager.updateModeSettings(
            currentMode: mode,
            showModeSelectionOnStartup: false,
            showModeIndicator: true  // Show mode indicators for clarity
        )
        
        // Record that mode selection was completed successfully
        UserDefaults.standard.set(true, forKey: "com.ledmessenger.completedModeSetup")
        
        // Handle transition to PAIRED mode
        if mode == .paired {
            // Stop OSC service that might be running in solo mode
            handlePairedModeConnection()
            
            // Start peer connectivity if not already running
            if peerService == nil {
                startPeerConnectivity()
            }
            
            // iPad in paired mode goes directly to message management
            setupCompleted = true
            appState = .messageManagement
            
            // Log that we're going to message management
            logger.info("Going to message management for PAIRED mode")
            
            // Set up regular queue sync for paired mode
            setupRegularQueueSync()
        } 
        // Handle transition to SOLO mode
        else if mode == .solo {
            // Stop peer connectivity if running
            if peerService != nil {
                stopPeerConnectivity()
            }
            
            // Reset OSC services for direct connection
            handleSoloModeConnection()
            
            // ALWAYS show setup when selecting SOLO mode
            setupCompleted = false
            appState = .setup
            
            // Reset the initialSetupCompletedThisSession flag
            initialSetupCompletedThisSession = false
            
            // Log that we're forcing setup screen
            logger.info("Forcing setup screen for SOLO mode")
        }
        
        // Close the mode selection screen
        self.shouldShowModeSelection = false
        
        // Add print statement for debugging in console
        print("DEBUG: App mode set to \(mode.rawValue), navigating to \(appState), showModeSelection=\(shouldShowModeSelection)")
        
        logger.info("App mode changed to \(self.appMode.rawValue)")
    }
    
    // MARK: - Settings Methods
    
    /**
     * Update OSC connectivity settings
     * Updates both local settings and propagates to services
     *
     * @param ipAddress Optional IP address for OSC target
     * @param port Optional port number for OSC communication
     * @param layer Optional Resolume layer number
     * @param startingClip Optional starting clip index
     * @param clearClip Optional clear screen clip index
     */
    func updateOSCSettings(
        ipAddress: String? = nil,
        port: Int? = nil,
        layer: Int? = nil,
        startingClip: Int? = nil,
        clearClip: Int? = nil,
        messageDuration: Int? = nil
    ) {
        // Check if settings can be modified on this device (for iPad)
        #if os(iOS)
        if !settingsManager.allowsSettingsModification {
            logger.warning("Attempted to modify OSC settings while in PAIRED mode (not allowed)")
            return
        }
        #endif
        
        // Update persistent settings
        settingsManager.updateOSCSettings(
            ipAddress: ipAddress,
            port: port,
            layer: layer,
            startingClip: startingClip,
            clearClip: clearClip,
            messageDuration: messageDuration
        )
        
        // Update OSC service endpoint if network settings changed
        if let ipAddress = ipAddress, let port = port {
            oscService.updateEndpoint(host: ipAddress, port: port)
        }
        
        // Create new Resolume service with updated settings
        // (necessary because properties are immutable)
        let updatedService = resolumeService.updateConfiguration(
            layer: settingsManager.settings.osc.layer,
            startingClip: settingsManager.settings.osc.startingClip,
            clearClip: settingsManager.settings.osc.clearClip
        )
        
        // Replace services with updated instances
        self.resolumeService = updatedService
        self.messageViewModel.updateResolumeService(updatedService)
        
        // Sync settings to connected peer devices
        if settingsManager.shouldEnablePeerConnectivity {
            peerService?.syncOSCSettings(settingsManager.settings.osc)
        }
    }
    
    /**
     * Toggle display of technical debug information
     * Updates both UI state and persistent settings
     */
    func toggleDebugInfo() {
        showDebugInfo.toggle()
        settingsManager.updateAppearanceSettings(showDebug: showDebugInfo)
    }
    
    // MARK: - Connection Helper Methods
    
    /**
     * Handles OSC connection for paired mode
     */
    private func handlePairedModeConnection() {
        // First disconnect on main thread, then reconnect
        oscService.disconnect()
        
        // Use dispatch after to add delay on main thread
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            
            // Reconnect with Task on main thread
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                await self.oscService.connect()
            }
        }
    }
    
    /**
     * Handles OSC connection for solo mode
     */
    private func handleSoloModeConnection() {
        // First disconnect
        oscService.disconnect()
        
        // Capture configuration values safely on main thread
        let host = settingsManager.settings.osc.host
        let port = settingsManager.settings.osc.port
        let layer = settingsManager.settings.osc.layer
        let startingClip = settingsManager.settings.osc.startingClip
        let clearClip = settingsManager.settings.osc.clearClip
        
        // Update endpoint settings (thread-safe operation with copied values)
        oscService.updateEndpoint(host: host, port: port)
        
        // Create updated service on main thread
        let updatedService = resolumeService.updateConfiguration(
            layer: layer,
            startingClip: startingClip,
            clearClip: clearClip
        )
        
        // Replace service and update view model
        self.resolumeService = updatedService
        self.messageViewModel.updateResolumeService(updatedService)
        
        // Add delay to ensure clean disconnect before reconnecting
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            
            // Reconnect on main thread with weak capture
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                await self.oscService.connect()
            }
        }
    }
    
    // MARK: - Testing Methods
    
    /**
     * Test connection to Resolume
     * Verifies OSC communication is working correctly
     *
     * @return Boolean indicating if connection test succeeded
     */
    func testConnection() async -> Bool {
        do {
            // If already connected, use lightweight verification
            if connectionStatus == .connected {
                if await resolumeService.verifyConnection() {
                    logger.info("Connection verified with ping - already connected")
                    return true
                }
            }
            
            // Full connection test sequence
            // Step 1: Send test message
            try await resolumeService.sendText("TEST", toClip: 0)
            logger.info("Successfully sent test message")
            
            // Step 2: Brief delay for visibility
            try await Task.sleep(nanoseconds: 1_000_000_000)
            
            // Step 3: Clear the screen
            try await resolumeService.clearScreen()
            logger.info("Successfully cleared screen")
            
            // All test steps successful
            logger.info("Connection test fully succeeded")
            return true
        } catch {
            // Log failure details
            logger.error("Connection test failed: \(error.localizedDescription)")
            return false
        }
    }
    
    /**
     * Direct low-level OSC testing function
     * Sends raw OSC messages to test specific Resolume functionality
     * Primarily used for development and troubleshooting
     */
    func testDirectOSC() async {
        // Create isolated OSC service for testing
        let testOscService = OSCService(
            host: settingsManager.settings.osc.host,
            port: settingsManager.settings.osc.port
        )
        
        do {
            // Establish connection
            await testOscService.connect()
            
            // Wait for connection to establish
            try await Task.sleep(nanoseconds: 1_000_000_000)
            
            // Get current configuration settings
            let layer = settingsManager.settings.osc.layer
            let startingClip = settingsManager.settings.osc.startingClip
            let clearClip = settingsManager.settings.osc.clearClip
            
            // TEST 1: Send first test message
            // Set text content
            let msg1 = OSCMessage(
                address: "/composition/layers/\(layer)/clips/\(startingClip)/video/source/textgenerator/text/params/lines",
                arguments: [OSCString(value: "LEDMESSENGER.COM")]
            )
            try await testOscService.send(msg1!)
            
            // Trigger the clip
            let activate1 = OSCMessage(
                address: "/composition/layers/\(layer)/clips/\(startingClip)/connect",
                arguments: []
            )
            try await testOscService.send(activate1!)
            
            // Wait for visibility
            try await Task.sleep(nanoseconds: 3_000_000_000)
            
            // TEST 2: Send second test message
            let secondClip = startingClip + 1
            
            // Set text content
            let msg2 = OSCMessage(
                address: "/composition/layers/\(layer)/clips/\(secondClip)/video/source/textgenerator/text/params/lines",
                arguments: [OSCString(value: "LET'S PARTY")]
            )
            try await testOscService.send(msg2!)
            
            // Trigger the clip
            let activate2 = OSCMessage(
                address: "/composition/layers/\(layer)/clips/\(secondClip)/connect",
                arguments: []
            )
            try await testOscService.send(activate2!)
            
            // Wait for visibility
            try await Task.sleep(nanoseconds: 3_000_000_000)
            
            // TEST 3: Clear the screen
            // Trigger clear clip
            let clearMsg = OSCMessage(
                address: "/composition/layers/\(layer)/clips/\(clearClip)/connect",
                arguments: []
            )
            try await testOscService.send(clearMsg!)
        } catch {
            logger.error("Direct OSC test failed: \(error.localizedDescription)")
        }
    }
    
    /**
     * Force reconnection to OSC endpoint
     * Used to recover from temporary network issues
     */
    func forceReconnect() {
        // Already on MainActor, so just execute the reconnection
        Task { @MainActor [weak self] in 
            guard let self = self else { return }
            await self.oscService.connect()
        }
    }
    
    // MARK: - Peer-to-Peer Connectivity
    
    /**
     * Start peer-to-peer connectivity service
     * Enables iPad-Mac communication for synchronization
     */
    func startPeerConnectivity() {
        // Get platform-specific device name
        #if os(macOS)
        let deviceName = Host.current().localizedName ?? "Mac"
        #else
        let deviceName = UIDevice.current.name
        #endif
        
        // Create and start peer service
        let service = PeerService(deviceName: deviceName)
        service.delegate = self
        service.start()
        
        // Store service reference
        peerService = service
        
        // Subscribe to connection status updates
        service.connectionStatusPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] isConnected in
                self?.peerConnectionStatus = isConnected
            }
            .store(in: &cancellables)
        
        logger.info("Started peer connectivity service")
    }
    
    /**
     * Stop peer-to-peer connectivity service
     * Terminates connection to peer devices
     */
    func stopPeerConnectivity() {
        peerService?.stop()
        peerService = nil
        peerConnectionStatus = false
        logger.info("Stopped peer connectivity service")
    }
    
    /**
     * Restart peer connectivity to recover from connection issues
     * Completely stops and restarts the peer service
     */
    func restartPeerConnectivity() {
        // First stop the existing service
        peerService?.stop()
        peerService = nil
        
        // Brief delay to allow network resources to reset
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            // Start a new service instance
            startPeerConnectivity()
            
            logger.info("Manually restarted peer connectivity service")
        }
    }
    
    /**
     * Synchronize the full message queue with connected peer devices
     * Ensures all devices have the same message state
     */
    @MainActor
    func syncMessageQueueWithPeers() {
        // Send full queue (even if empty) to ensure consistency
        peerService?.syncQueue(messageViewModel.messages)
    }
    
    // MARK: - PeerServiceDelegate
    
    /**
     * Handle peer connection status changes
     * Initiates appropriate synchronization when connection established
     *
     * @param connected Boolean indicating if peer connection is active
     */
    func peerConnectionStatusChanged(_ connected: Bool) {
        // Dispatch to main actor for UI updates
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            // Update connection status
            self.peerConnectionStatus = connected
            
            // Handle new connections
            if connected {
                // Brief delay to ensure connection is stable
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                
                // Platform-specific synchronization behavior
                #if os(macOS)
                // Mac is the source of truth for settings
                peerService?.syncOSCSettings(settingsManager.settings.osc)
                
                // Wait for settings to be processed
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                
                // Sync message queue after settings
                syncMessageQueueWithPeers()
                #else
                // iPad receives settings from Mac
                await requestSettingsFromPeers()
                
                // Wait for settings reception
                try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
                
                // Sync iPad messages to Mac
                syncMessageQueueWithPeers()
                #endif
                
                // Additional final sync to ensure consistency
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                syncMessageQueueWithPeers()
            }
        }
    }
    
    /**
     * Process incoming sync messages from peer devices
     * Routes messages to appropriate handlers based on type
     *
     * @param message The peer sync message to process
     */
    func didReceiveSyncMessage(_ message: PeerSyncMessage) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            switch message.type {
            case .messageQueueSync:
                // Full queue replacement
                if let queue = message.queue {
                    await processQueueSync(queue)
                }
                
            case .messageSent:
                // Single message sent update
                if let messageId = message.messageId, let messageData = message.message {
                    await processMessageSent(messageId, messageData, message)
                }
                
            case .messageCancelled:
                // Message cancellation
                if let messageId = message.messageId {
                    await processMessageCancelled(messageId)
                }
                
            case .messageAdded:
                // New message added
                if let messageData = message.message {
                    await processMessageAdded(messageData)
                }
                
            case .queueCleared:
                // Queue completely cleared
                await processQueueCleared()
                
            case .oscSettingsSync:
                // OSC settings update
                if let settingsData = message.oscSettings {
                    await processOSCSettingsSync(settingsData)
                }
                
            case .heartbeat:
                // Connection maintenance message (ignored)
                break
            }
        }
    }
    
    /**
     * Process a full queue synchronization from peer
     * Reconciles local queue with the received queue
     *
     * @param queue Array of message data to synchronize
     */
    @MainActor
    private func processQueueSync(_ queue: [MessageData]) async {
        // Convert MessageData objects to Message model objects
        let messages = queue.map { $0.toMessage() }
        
        // Identify current message IDs
        let currentIds = Set(messageViewModel.messages.map { $0.id })
        
        // Identify incoming message IDs
        let incomingIds = Set(messages.map { $0.id })
        
        // Debug diagnostics
        print("📲🔄 Processing queue sync:")
        print("📲🔄 - Current messages: \(messageViewModel.messages.count) [\(messageViewModel.messages.map { $0.text }.joined(separator: ", "))]")
        print("📲🔄 - Incoming messages: \(messages.count) [\(messages.map { $0.text }.joined(separator: ", "))]")
        
        // Find messages that need to be removed
        let idsToRemove = currentIds.subtracting(incomingIds)
        print("📲🔄 - Messages to remove: \(idsToRemove.count)")
        
        // Remove messages no longer in the synced queue
        for id in idsToRemove {
            messageViewModel.removeMessage(id)
        }
        
        // Process messages in the incoming queue
        for message in messages {
            if currentIds.contains(message.id) {
                // Update existing message
                print("📲🔄 - Updating message: \(message.text)")
                messageViewModel.updateMessageFromPeer(message)
            } else {
                // Add new message
                print("📲🔄 - Adding new message: \(message.text)")
                messageViewModel.addMessageFromPeer(message)
            }
        }
        
        logger.info("Processed queue sync with \(messages.count) messages")
    }
    
    /**
     * Process a message sent update from peer
     * Updates status of a message that was sent on another device
     *
     * @param messageId ID of the updated message
     * @param messageData Updated message data
     */
    @MainActor
    private func processMessageSent(_ messageId: UUID, _ messageData: MessageData, _ syncMessage: PeerSyncMessage) async {
        let message = messageData.toMessage()
        
        // Extract the current slot from the peer sync message
        let currentSlot = syncMessage.currentClipSlot
        
        // Update the message from peer with the slot information
        messageViewModel.updateMessageFromPeer(message, currentSlot: currentSlot)
        logger.debug("Processed message sent from peer: \(messageId), slot: \(String(describing: currentSlot))")
    }
    
    /**
     * Process a message cancellation from peer
     * Removes a message that was cancelled on another device
     *
     * @param messageId ID of the cancelled message
     */
    @MainActor
    private func processMessageCancelled(_ messageId: UUID) async {
        messageViewModel.cancelMessageFromPeer(messageId)
        logger.debug("Processed message cancelled from peer: \(messageId)")
    }
    
    /**
     * Process a new message added by a peer
     * Adds the message to the local queue
     *
     * @param messageData Data for the new message
     */
    @MainActor
    private func processMessageAdded(_ messageData: MessageData) async {
        let message = messageData.toMessage()
        messageViewModel.addMessageFromPeer(message)
        logger.debug("Processed message added from peer: \(message.id)")
    }
    
    /**
     * Process queue cleared notification from peer
     * Clears the entire local message queue
     */
    @MainActor
    private func processQueueCleared() async {
        messageViewModel.clearAllMessagesFromPeer()
        logger.debug("Processed queue cleared from peer")
    }
    
    /**
     * Process OSC settings sync from peer
     * Updates local OSC settings with those received from peer
     * iPad-only - Mac is the source of truth for settings
     *
     * @param settingsData The OSC settings data to apply
     */
    @MainActor
    private func processOSCSettingsSync(_ settingsData: OSCSettingsData) async {
        #if !os(macOS)
        // Only process settings updates on iPad - Mac is source of truth
        let settings = settingsData.toOSCSettings()
        
        // Update settings in settings manager
        settingsManager.updateOSCSettings(
            ipAddress: settings.ipAddress,
            port: settings.port,
            layer: settings.layer,
            startingClip: settings.startingClip,
            clearClip: settings.clearClip
        )
        
        // Update OSC service with new connection settings
        oscService.updateEndpoint(host: settings.ipAddress, port: settings.port)
        
        // Create new Resolume service with updated settings
        let updatedService = resolumeService.updateConfiguration(
            layer: settings.layer,
            startingClip: settings.startingClip,
            clearClip: settings.clearClip
        )
        
        // Replace service instances with updated ones
        self.resolumeService = updatedService
        self.messageViewModel.updateResolumeService(updatedService)
        
        logger.info("Received OSC settings from peer: IP=\(settings.ipAddress), Port=\(settings.port), Layer=\(settings.layer)")
        #endif
    }
}