//
//  MessageViewModel.swift
//  LEDMESSENGER
//
//  Created by Claude AI on 4/12/2025.
//

import Foundation
import Combine
import OSLog
import SwiftUI

/// Class responsible for managing messages
@MainActor
final class MessageViewModel: ObservableObject {
    // MARK: - Properties
    
    /// All messages in the system
    @Published private(set) var messages: [Message] = []
    
    /// Whether a new message sheet is showing
    @Published var showingNewMessageSheet = false
    
    /// Message currently being edited (if any)
    @Published var editingMessageId: UUID?
    
    /// Text for the new message being created
    @Published var newMessageText = ""
    
    /// Identifier for the new message being created
    @Published var newMessageIdentifier = ""
    
    /// Whether messages are currently cycling automatically
    @Published private(set) var isAutoCycling = false
    
    /// Label type for the new message
    @Published var newMessageLabelType: LabelType = .tableNumber
    
    /// Custom label for the new message
    @Published var newMessageCustomLabel = ""
    
    /// Available message templates
    @Published private(set) var templates: [MessageTemplate] = []
    
    /// The Resolume service
    private var resolumeService: ResolumeOSCService
    
    /// Update the Resolume service reference
    func updateResolumeService(_ service: ResolumeOSCService) {
        self.resolumeService = service
    }
    
    /// The settings manager
    private let settingsManager: SettingsManager
    
    /// Current clip offset in the 3-clip rotation (starts at 0)
    /// This tracks which of the 3 clips we're currently using
    /// First message goes to slot 1 (offset 0)
    /// Second message goes to slot 2 (offset 1)
    /// Third message goes to slot 3 (offset 2)
    /// Fourth message wraps back to slot 1 (offset 0)
    private var currentSlot: Int = 0
    
    /// Current clip offset for peer message updates
    /// This tracks which clip to use for peer message updates
    private var currentClipOffset: Int = 0
    
    /// Tracks the last time a specific message ID was sent to Resolume
    /// Used to prevent duplicate sends of the same message
    private var lastSendTimes: [UUID: Date] = [:]
    
    /// Tracks messages that have been successfully sent to the wall
    /// Once a message is successfully sent, it's added to this set and should never be resent
    /// This prevents connection retries from resending messages
    private var sentMessageIds = Set<UUID>()
    
    /// Minimum time between resending the same message (in seconds)
    /// This is used only for explicit user-triggered resends, not for connection retries
    private let messageSendCooldown: TimeInterval = 30.0
    
    /// Timer for checking message expiration
    private var expirationTimer: Timer?
    
    /// Timer for automatic message cycling
    private var cycleTimer: Timer?
    
    /// Logger
    private let logger = Logger(subsystem: "com.ledmessenger.messages", category: "viewmodel")
    
    // MARK: - Initialization
    
    /// Initialize the message view model
    init(resolumeService: ResolumeOSCService, settingsManager: SettingsManager) {
        self.resolumeService = resolumeService
        self.settingsManager = settingsManager
        
        // Set up expiration timer
        setupExpirationTimer()
        
        // Load message templates
        loadTemplates()
        
        // Set initial label type from settings
        newMessageLabelType = settingsManager.settings.formatting.defaultLabelType
        newMessageCustomLabel = settingsManager.settings.formatting.defaultCustomLabel
    }
    
    // MARK: - Message Operations
    
    /// Add a message to the queue
    func addMessage(text: String, identifier: String, labelType: LabelType, customLabel: String) {
        guard !text.isEmpty else { return }
        
        // Create the message
        var message = Message(
            text: text.uppercased(),
            identifier: identifier,
            labelType: labelType,
            customLabel: customLabel
        )
        
        // Set expiration time based on current settings
        let countdownMinutes = settingsManager.settings.formatting.messageCountdownMinutes
        message.expiresAt = Calendar.current.date(byAdding: .minute, value: countdownMinutes, to: message.createdAt)
        
        messages.append(message)
        print("💬 Added message to queue: \(message.text) (\(message.id.uuidString)) | Expires in: \(countdownMinutes) minutes")
        logger.info("Added message to queue: \(message.id.uuidString) | Countdown: \(countdownMinutes) min")
        
        // Notify AppViewModel of the change
        NotificationCenter.default.post(
            name: .messageAdded,
            object: nil,
            userInfo: ["message": message]
        )
    }
    
    /// Add a message from a peer device
    func addMessageFromPeer(_ message: Message) {
        // Ensure we're on the main thread
        Task { @MainActor in
            // Check if the message already exists
            if messages.contains(where: { $0.id == message.id }) {
                print("💬🔁 Message already exists, not adding: \(message.text) (\(message.id.uuidString))")
                return
            }
            
            // Create a mutable copy of the message
            var updatedMessage = message
            
            // Update expiration time to use local settings
            let countdownMinutes = settingsManager.settings.formatting.messageCountdownMinutes
            updatedMessage.expiresAt = Calendar.current.date(byAdding: .minute, value: countdownMinutes, to: message.createdAt)
            
            // Add the message
            messages.append(updatedMessage)
            print("💬✅ Added message from peer: \(updatedMessage.text) (\(updatedMessage.id.uuidString)) | Expires in: \(countdownMinutes) minutes")
            logger.info("Added message from peer: \(updatedMessage.id.uuidString) | Countdown: \(countdownMinutes) min")
        }
    }
    
    /// Cancel a message
    func cancelMessage(_ messageId: UUID) {
        guard let index = messages.firstIndex(where: { $0.id == messageId }) else {
            return
        }
        
        // First, safely update message status to avoid crashing
        let wasMessageSent = messages[index].status == .sent
        
        if wasMessageSent {
            // If the message was sent, return it to the queue instead of removing it
            messages[index].updateStatus(.queued)
            
            // Remove from sentMessageIds set so it can be resent
            sentMessageIds.remove(messageId)
            
            // Remove from lastSendTimes to bypass cooldown
            lastSendTimes.removeValue(forKey: messageId)
            
            // Trigger the clear clip to clear the screen
            Task {
                do {
                    let messageText = messages[index].text
                    print("🧹 CANCELLING SENT MESSAGE: \(messageText)")
                    print("🧹 Returning message to queue and clearing screen")
                    print("🧹 Message can now be resent immediately (cooldown removed)")
                    
                    // Use the clearScreen method to clear
                    try await resolumeService.clearScreen()
                    
                    logger.info("Triggered clear clip after returning message to queue: \(messageId.uuidString)")
                } catch {
                    print("🧹❌ ERROR CLEARING SCREEN: \(error.localizedDescription)")
                    logger.error("Failed to clear screen: \(error.localizedDescription)")
                }
            }
        } else {
            // For queued messages, change status to cancelled and remove from queue
            messages[index].updateStatus(.cancelled)
            
            // Create a local copy of the message info we need after removal
            let messageText = messages[index].text
            
            // Remove the message from the array
            messages.removeAll { $0.id == messageId }
            
            print("🗑️ DELETING QUEUED MESSAGE: \(messageText)")
        }
        
        // Notify AppViewModel of the change
        NotificationCenter.default.post(
            name: .messageCancelled,
            object: nil,
            userInfo: ["messageId": messageId]
        )
    }
    
    /// Cancel a message received from a peer
    func cancelMessageFromPeer(_ messageId: UUID) {
        // Ensure we're on the main thread
        Task { @MainActor in
            guard let index = messages.firstIndex(where: { $0.id == messageId }) else {
                return
            }
            
            // Check if the message was sent
            let wasMessageSent = messages[index].status == .sent
            
            if wasMessageSent {
                // If the message was sent, return it to the queue instead of removing it
                messages[index].updateStatus(.queued)
                
                // Remove from sentMessageIds set so it can be resent
                sentMessageIds.remove(messageId)
                
                // Remove from lastSendTimes to bypass cooldown
                lastSendTimes.removeValue(forKey: messageId)
                
                // Trigger the clear clip after updating our data model
                Task {
                    do {
                        let messageText = messages[index].text
                        print("🧹 PEER CANCELLING SENT MESSAGE: \(messageText)")
                        print("🧹 Returning message to queue and clearing screen")
                        print("🧹 Message can now be resent immediately (cooldown removed)")
                        
                        // Use the clearScreen method to clear
                        try await resolumeService.clearScreen()
                        
                        logger.info("Triggered clear clip after peer returned message to queue: \(messageId.uuidString)")
                    } catch {
                        print("🧹❌ ERROR CLEARING SCREEN FROM PEER: \(error.localizedDescription)")
                        logger.error("Failed to clear screen: \(error.localizedDescription)")
                    }
                }
            } else {
                // For queued messages, change status to cancelled and remove from queue
                messages[index].updateStatus(.cancelled)
                
                // Create a local copy of the message info we need after removal
                let messageText = messages[index].text
                
                // Remove the message from the array
                messages.removeAll { $0.id == messageId }
                
                print("🗑️ PEER DELETING QUEUED MESSAGE: \(messageText)")
            }
            
            logger.info("Cancelled message from peer: \(messageId.uuidString)")
        }
    }
    
    /// Remove a message (used for peer sync)
    func removeMessage(_ messageId: UUID) {
        // Ensure we're on the main thread
        Task { @MainActor in
            messages.removeAll { $0.id == messageId }
            logger.debug("Removed message via peer sync: \(messageId.uuidString)")
        }
    }
    
    /// Clear all messages and the screen
    func clearAllMessages() {
        Task {
            do {
                // Important debugging output
                print("🧹 CLEARING ALL MESSAGES AND SCREEN")
                print("🧹 Will use clearClip: \(resolumeService.getClearClip())")
                
                // Force a clearScreen operation
                try await resolumeService.clearScreen()
                
                logger.info("Cleared screen and all messages")
            } catch {
                print("🧹❌ ERROR CLEARING SCREEN: \(error.localizedDescription)")
                logger.error("Failed to clear screen: \(error.localizedDescription)")
            }
        }
        
        // Update all sent messages to cancelled
        for index in messages.indices where messages[index].status == .sent {
            messages[index].updateStatus(.cancelled)
        }
        
        // Clear the queue
        messages.removeAll()
        
        // Reset all slot counters and state to start fresh
        currentSlot = 0
        currentClipOffset = 0
        lastSendTimes.removeAll()
        sentMessageIds.removeAll()
        
        // Notify AppViewModel of the change
        NotificationCenter.default.post(name: .queueCleared, object: nil)
    }
    
    /// Clear all messages from a peer device
    func clearAllMessagesFromPeer() {
        // Ensure we're on the main thread
        Task { @MainActor in
            // Clear the screen if needed
            if messages.contains(where: { $0.status == .sent }) {
                Task {
                    do {
                        try await resolumeService.clearScreen()
                        logger.info("Cleared screen from peer queue clear")
                    } catch {
                        logger.error("Failed to clear screen: \(error.localizedDescription)")
                    }
                }
            }
            
            // Clear the queue
            messages.removeAll()
            
            // Reset all slot counters and state to start fresh
            currentSlot = 0
            currentClipOffset = 0
            lastSendTimes.removeAll()
            sentMessageIds.removeAll()
            
            logger.info("Cleared all messages from peer")
        }
    }
    
    /// Send a message to the LED wall
    func sendMessageToWall(_ messageId: UUID) async {
        guard let index = messages.firstIndex(where: { $0.id == messageId }) else {
            return
        }
        
        // Get the message to send
        let message = messages[index]
        
        // If the message already has 'sent' status and is in our sentMessageIds set, don't resend it
        // This prevents retries from sending the same message multiple times
        if message.status == .sent && sentMessageIds.contains(messageId) {
            print("🎬🚫 NOT RESENDING - Message has already been successfully sent: \(message.text)")
            return
        }
        
        // Check if this message was recently sent (prevent accidental duplicate sends)
        if let lastSendTime = lastSendTimes[messageId] {
            let timeSinceLastSend = Date().timeIntervalSince(lastSendTime)
            if timeSinceLastSend < messageSendCooldown {
                print("🎬 SKIPPING RESEND - Message was sent \(String(format: "%.1f", timeSinceLastSend))s ago (cooldown: \(messageSendCooldown)s): \(message.text)")
                return
            }
        }
        
        // Set all other sent messages to expired
        for i in messages.indices where messages[i].status == .sent {
            messages[i].updateStatus(.expired)
        }
        
        do {
            // Record send time to prevent duplicate sends
            lastSendTimes[messageId] = Date()
            
            // Format the text according to settings
            let formattedText = formatTextForResolume(message.formattedText)
            
            // Increment the slot for the 3-clip rotation system
            // If this is the first message, it goes to slot 1
            // Second message -> slot 2, and so on
            // After slot 3, we wrap back to slot 1
            
            // Get the resolume starting clip (e.g., clip 1)
            let startingClip = resolumeService.getStartingClip()
            
            // Enhanced logging for clarity
            print("🎬 MESSAGE: Sending to SLOT \(currentSlot + 1) of 3")
            print("🎬 Using Resolume clip #\(startingClip + currentSlot)")
            print("🎬 Text: \"\(message.text)\"")
            
            // Use the current slot for this message
            let slotToUse = currentSlot
            
            // Increment to the next slot for the next message
            // After slot 3, wrap back to slot 1
            currentSlot = (currentSlot + 1) % 3
            
            // Send the text to the correct clip in the rotation
            try await resolumeService.sendText(formattedText, toClip: slotToUse)
            
            // Update message status
            messages[index].updateStatus(.sent)
            
            // Mark this message as successfully sent - it should never be resent automatically
            sentMessageIds.insert(messageId)
            
            // Notify AppViewModel of the change
            NotificationCenter.default.post(
                name: .messageSent,
                object: nil,
                userInfo: ["message": messages[index]]
            )
            
            logger.info("Sent message to LED wall: \(message.id.uuidString) using clip offset \(slotToUse)")
        } catch {
            logger.error("Failed to send message to LED wall: \(error.localizedDescription)")
            // Could update UI with an error here
        }
    }
    
    /// Create and send a new message
    func createAndSendMessage(text: String, identifier: String, labelType: LabelType, customLabel: String) async {
        // Add the message to the queue
        addMessage(text: text, identifier: identifier, labelType: labelType, customLabel: customLabel)
        
        // Get the message ID
        guard let messageId = messages.last?.id else {
            return
        }
        
        // Send the message to the wall
        await sendMessageToWall(messageId)
    }
    
    /// Edit an existing message
    func editMessage(id: UUID, text: String, identifier: String, labelType: LabelType, customLabel: String) {
        guard let index = messages.firstIndex(where: { $0.id == id }) else {
            return
        }
        
        // Update the message
        messages[index].text = text.uppercased()
        messages[index].identifier = identifier
        messages[index].labelType = labelType
        messages[index].customLabel = customLabel
        
        // If message is sent, update it on the LED wall
        if messages[index].status == .sent {
            Task {
                await sendMessageToWall(id)
            }
        }
        
        // Notify AppViewModel of the change
        NotificationCenter.default.post(
            name: .messageUpdated,
            object: nil,
            userInfo: ["message": messages[index]]
        )
    }
    
    /// Update a message from a peer
    func updateMessageFromPeer(_ message: Message) {
        // Ensure we're on the main thread
        Task { @MainActor in
            guard let index = messages.firstIndex(where: { $0.id == message.id }) else {
                // Message doesn't exist, add it
                addMessageFromPeer(message)
                return
            }
            
            // Update the message
            messages[index].text = message.text
            messages[index].identifier = message.identifier
            messages[index].labelType = message.labelType
            messages[index].customLabel = message.customLabel
            messages[index].status = message.status
            
            // If this message is now sent but a different one was previously sent,
            // update the LED wall
            if message.status == .sent {
                // If the message is already in our sentMessageIds set, don't resend it
                // This prevents retries from sending the same message multiple times
                if sentMessageIds.contains(message.id) {
                    print("🎬🚫 NOT RESENDING PEER MESSAGE - Message has already been successfully sent: \(message.text)")
                    return
                }
                
                // Set all other sent messages to expired
                for i in messages.indices where 
                    messages[i].status == .sent && messages[i].id != message.id {
                    messages[i].updateStatus(.expired)
                }
                
                // Update the wall with this message
                Task {
                    do {
                        // Check if this message was recently sent (prevent duplicates)
                        if let lastSendTime = lastSendTimes[message.id] {
                            let timeSinceLastSend = Date().timeIntervalSince(lastSendTime)
                            if timeSinceLastSend < messageSendCooldown {
                                print("🎬🔄 SKIPPING PEER RESEND - Message was sent \(String(format: "%.1f", timeSinceLastSend))s ago (cooldown: \(messageSendCooldown)s): \(message.text)")
                                return
                            }
                        }
                        
                        // Record send time to prevent duplicate sends
                        lastSendTimes[message.id] = Date()
                        
                        // Format the text according to settings
                        let formattedText = formatTextForResolume(message.formattedText)
                        
                        // Use the same slot system from the peer, don't re-calculate
                        // Get the current slot value based on the message index in the 3-clip rotation
                        let peerSlotIndex = messages.firstIndex(where: { $0.id == message.id }) ?? 0
                        let slotToUse = peerSlotIndex % 3
                        
                        // Enhanced logging for 3-clip rotation debugging
                        print("🎬🔄 PEER UPDATE - Using clip offset: \(slotToUse) in 3-clip rotation")
                        print("🎬🔄 PEER UPDATE - Clip position: \(slotToUse + 1) of 3")
                        print("🎬🔄 PEER UPDATE - Message: \"\(message.text)\"")
                        
                        // Send the text to Resolume with the correct slot value
                        try await resolumeService.sendText(formattedText, toClip: slotToUse)
                        
                        // Mark this message as successfully sent - it should never be resent automatically
                        sentMessageIds.insert(message.id)
                        
                        logger.info("Sent peer message to LED wall: \(message.id.uuidString) using clip offset \(slotToUse)")
                    } catch {
                        logger.error("Failed to send peer message to LED wall: \(error.localizedDescription)")
                    }
                }
            }
            
            logger.debug("Updated message from peer: \(message.id.uuidString)")
        }
    }
    
    // MARK: - Message Cycling
    
    /// Start automatic message cycling
    func startAutoCycling(interval: TimeInterval = 10.0) {
        guard !isAutoCycling, !messages.isEmpty else {
            return
        }
        
        isAutoCycling = true
        
        cycleTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            Task { @MainActor in
                await self.cycleToNextMessage()
            }
        }
        
        // Immediately cycle to the first message
        Task {
            await cycleToNextMessage()
        }
        
        logger.info("Started automatic message cycling with interval: \(interval) seconds")
    }
    
    /// Stop automatic message cycling
    func stopAutoCycling() {
        cycleTimer?.invalidate()
        cycleTimer = nil
        isAutoCycling = false
        
        logger.info("Stopped automatic message cycling")
    }
    
    /// Cycle to the next message
    private func cycleToNextMessage() async {
        // Find the currently sent message
        let currentSentIndex = messages.firstIndex { $0.status == .sent }
        
        // Find the next queued message
        let nextQueuedIndex = messages.firstIndex { $0.status == .queued }
        
        // If there's a current message, set it to expired
        if let currentSentIndex = currentSentIndex {
            messages[currentSentIndex].updateStatus(.expired)
        }
        
        // If there's a next message, send it
        if let nextQueuedIndex = nextQueuedIndex {
            await sendMessageToWall(messages[nextQueuedIndex].id)
        } else if currentSentIndex != nil {
            // If there's no next message but there was a current one, clear the screen
            do {
                try await resolumeService.clearScreen()
                logger.info("Cleared screen at end of message cycle")
            } catch {
                logger.error("Failed to clear screen: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Formatting
    
    /// Format text for Resolume according to settings
    private func formatTextForResolume(_ text: String) -> String {
        let mode = settingsManager.settings.formatting.lineBreakMode
        let maxChars = settingsManager.settings.formatting.maxCharsPerLine
        
        // Important: text parameter is already the full formatted text including the label
        // We use Message.formatWithLineBreaks to apply line breaks appropriately
        // This ensures the label is displayed correctly on the wall
        print("💬 Sending to wall with label: \(text)")
        return Message(text: text).formatWithLineBreaks(mode: mode, maxCharsPerLine: maxChars)
    }
    
    /// Apply text formatting settings to Resolume
    func updateResolumeFormatting() async {
        let useWordMode = settingsManager.settings.formatting.lineBreakMode == .wordCount
        let maxChars = settingsManager.settings.formatting.maxCharsPerLine
        
        logger.info("Using text formatting: wordMode=\(useWordMode), maxChars=\(maxChars)")
        // Note: ResolumeOSCService doesn't implement updateTextFormatting
        // This is just a placeholder for now
    }
    
    // MARK: - Message Templates
    
    /// Load message templates
    private func loadTemplates() {
        guard let data = UserDefaults.standard.data(forKey: "messageTemplates") else {
            loadDefaultTemplates()
            return
        }
        
        do {
            self.templates = try JSONDecoder().decode([MessageTemplate].self, from: data)
            logger.info("Loaded \(self.templates.count) message templates from UserDefaults")
        } catch {
            logger.error("Failed to decode message templates: \(error.localizedDescription)")
            loadDefaultTemplates()
        }
    }
    
    /// Save message templates
    private func saveTemplates() {
        do {
            let data = try JSONEncoder().encode(self.templates)
            UserDefaults.standard.set(data, forKey: "messageTemplates")
            logger.info("Saved \(self.templates.count) message templates to UserDefaults")
        } catch {
            logger.error("Failed to encode message templates: \(error.localizedDescription)")
        }
    }
    
    /// Load default templates
    private func loadDefaultTemplates() {
        self.templates = MessageTemplate.standardTemplates()
        saveTemplates()
    }
    
    /// Add a template
    func addTemplate(name: String, text: String, labelType: LabelType, customLabel: String) {
        let template = MessageTemplate(
            name: name,
            text: text,
            labelType: labelType,
            customLabel: customLabel
        )
        
        templates.append(template)
        saveTemplates()
    }
    
    /// Delete a template
    func deleteTemplate(id: UUID) {
        templates.removeAll { $0.id == id }
        saveTemplates()
    }
    
    /// Apply a template to the current message
    func applyTemplate(_ templateId: UUID) {
        guard let template = templates.first(where: { $0.id == templateId }) else {
            return
        }
        
        newMessageText = template.text
        newMessageLabelType = template.labelType
        newMessageCustomLabel = template.customLabel
    }
    
    // MARK: - Message Expiration
    
    /// Set up the expiration timer
    private func setupExpirationTimer() {
        expirationTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { [weak self] _ in
            // Dispatch to main thread for MainActor operations
            DispatchQueue.main.async {
                // Early return if we're deallocating
                guard let strongSelf = self else { return }
                
                // Check message expiration on the main thread
                strongSelf.checkExpiredMessages()
            }
        }
    }
    
    /// Check for expired messages - safe to call from the main thread
    @MainActor
    private func checkExpiredMessages() {
        let now = Date()
        
        // Make a safe copy of indices to iterate
        let indices = self.messages.indices
        
        // Check each message for expiration
        for index in indices where
            index < self.messages.count &&
            self.messages[index].status != .expired &&
            self.messages[index].status != .cancelled {
            
            if let expiresAt = self.messages[index].expiresAt, now > expiresAt {
                self.messages[index].updateStatus(.expired)
                self.logger.info("Message expired: \(self.messages[index].id.uuidString)")
            }
        }
    }
    
    // MARK: - Deinitialization
    
    deinit {
        expirationTimer?.invalidate()
        cycleTimer?.invalidate()
    }
}