//
//  Message.swift
//  LEDMESSENGER
//
//  Created by Claude AI on 4/12/2025.
//

/**
 * Core message model for the LED Messenger application
 * 
 * This file defines the fundamental Message struct that represents
 * text messages sent to the LED wall display.
 */

import Foundation

/**
 * Represents a message to be displayed on the LED wall
 *
 * This is the primary data model in the application, containing all information
 * about a message including its content, status, and lifecycle metadata.
 *
 * Key features:
 * - Content and formatting properties
 * - Status tracking with state transitions
 * - Lifecycle metadata (creation, expiration, sent times)
 * - Formatting utilities for display
 * - Prioritization support
 */
struct Message: Identifiable, Hashable, Codable {
    // MARK: - Hashable Conformance
    
    /**
     * Equality comparison operator for Hashable conformance
     * Two messages are considered equal if they have the same ID
     *
     * @param lhs First message to compare
     * @param rhs Second message to compare
     * @return Boolean indicating if messages are equal
     */
    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id
    }
    
    /**
     * Hash function implementation for Hashable conformance
     * Uses the message's unique ID for hashing
     *
     * @param hasher The hasher to use
     */
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // MARK: - Codable Implementation
    
    /**
     * Coding keys enum for serialization/deserialization
     * Defines the keys used when encoding/decoding Message instances
     */
    enum CodingKeys: String, CodingKey {
        case id, text, identifier, labelType, customLabel, status, createdAt, expiresAt, sentAt, priority
    }
    
    /**
     * Custom decoder initializer for Codable conformance
     * Reconstructs a Message from its encoded form
     *
     * @param decoder The decoder to read from
     * @throws DecodingError if required properties cannot be decoded
     */
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        identifier = try container.decode(String.self, forKey: .identifier)
        labelType = try container.decode(LabelType.self, forKey: .labelType)
        customLabel = try container.decode(String.self, forKey: .customLabel)
        status = try container.decode(MessageStatus.self, forKey: .status)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        expiresAt = try container.decodeIfPresent(Date.self, forKey: .expiresAt)
        sentAt = try container.decodeIfPresent(Date.self, forKey: .sentAt)
        priority = try container.decode(Int.self, forKey: .priority)
    }
    
    /**
     * Custom encoder implementation for Codable conformance
     * Encodes all message properties to the provided encoder
     *
     * @param encoder The encoder to write to
     * @throws EncodingError if properties cannot be encoded
     */
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(text, forKey: .text)
        try container.encode(identifier, forKey: .identifier)
        try container.encode(labelType, forKey: .labelType)
        try container.encode(customLabel, forKey: .customLabel)
        try container.encode(status, forKey: .status)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(expiresAt, forKey: .expiresAt)
        try container.encodeIfPresent(sentAt, forKey: .sentAt)
        try container.encode(priority, forKey: .priority)
    }
    
    // MARK: - Properties
    
    /// Unique identifier for this message (enables tracking across devices)
    let id: UUID
    
    /// The message content text (always stored in uppercase for LED display)
    var text: String
    
    /// The identifier string (usually a table number or customer identifier)
    var identifier: String
    
    /// The type of label to use for this message (table, customer, etc.)
    var labelType: LabelType
    
    /// Custom label text (only used when labelType is .custom)
    var customLabel: String
    
    /// The current status of this message in its lifecycle
    var status: MessageStatus
    
    /// Timestamp when this message was created
    let createdAt: Date
    
    /// Optional timestamp when this message will expire and be removed from display
    var expiresAt: Date?
    
    /// Optional timestamp when this message was sent to the LED display
    var sentAt: Date?
    
    /// Priority value for this message (higher values = higher priority)
    /// Used for sorting the message queue
    var priority: Int
    
    // MARK: - Initialization
    
    /**
     * Create a new message with specified properties
     *
     * This is the primary initializer for creating Message instances,
     * providing sensible defaults for optional parameters.
     *
     * @param id Unique UUID (auto-generated if not provided)
     * @param text Message content text (will be converted to uppercase)
     * @param identifier Table number or other identifier (optional)
     * @param labelType Type of label to apply (default: .tableNumber)
     * @param customLabel Text for custom label (if using .custom label type)
     * @param status Initial message status (default: .queued)
     * @param createdAt Creation timestamp (default: current time)
     * @param expiresAt Expiration timestamp (default: 5 minutes after creation)
     * @param sentAt When the message was sent (nil until sent)
     * @param priority Message priority for ordering (default: 0)
     */
    init(
        id: UUID = UUID(),
        text: String,
        identifier: String = "",
        labelType: LabelType = .tableNumber,
        customLabel: String = "",
        status: MessageStatus = .queued,
        createdAt: Date = Date(),
        expiresAt: Date? = nil,
        sentAt: Date? = nil,
        priority: Int = 0
    ) {
        self.id = id
        
        // Always convert text to uppercase for better LED wall visibility
        self.text = text.uppercased()
        
        self.identifier = identifier
        self.labelType = labelType
        self.customLabel = customLabel
        self.status = status
        self.createdAt = createdAt
        
        // Set default expiration time if none provided
        // Note: MessageViewModel may override this based on settings
        self.expiresAt = expiresAt ?? Calendar.current.date(byAdding: .minute, value: 5, to: createdAt)
        
        self.sentAt = sentAt
        self.priority = priority
    }
    
    // MARK: - Computed Properties
    
    /**
     * Get the display-ready formatted text for this message
     *
     * This property provides the final text that should be shown on the LED display,
     * including any necessary labels or formatting.
     *
     * @return String containing the formatted message text
     */
    var formattedText: String {
        // Currently returns just the raw message text without labels
        // This ensures consistent display across all message types
        return text
    }
    
    /**
     * Get the time remaining until message expiration
     *
     * Calculates the number of seconds remaining before this message
     * expires, based on the current time and the expiration timestamp.
     *
     * @return TimeInterval representing seconds until expiration, or nil if no expiration
     */
    var timeRemaining: TimeInterval? {
        guard let expiresAt = expiresAt else {
            // Message has no expiration time
            return nil
        }
        
        // Ensure non-negative value (0 if already expired)
        return max(0, expiresAt.timeIntervalSinceNow)
    }
    
    /**
     * Get normalized progress towards message expiration (0.0 to 1.0)
     *
     * Calculates a progress value that can be used for UI indicators,
     * where 0.0 represents a newly created message and 1.0 represents
     * a fully expired message.
     *
     * @return Double from 0.0 to 1.0 representing expiration progress
     */
    var expirationProgress: Double {
        guard let expiresAt = expiresAt else {
            // Message has no expiration time
            return 0.0
        }
        
        // Calculate total lifetime and remaining time
        let total = expiresAt.timeIntervalSince(createdAt)
        let remaining = expiresAt.timeIntervalSinceNow
        
        // Convert to normalized progress value, clamped to valid range
        return max(0.0, min(1.0, remaining / total))
    }
    
    // MARK: - Methods
    
    /**
     * Format message text with appropriate line breaks
     *
     * Applies line breaks to the text content according to the specified
     * line break strategy and parameters. This enables adapting the text
     * to fit different LED display dimensions and requirements.
     *
     * @param mode The line break strategy to use (none, wordCount, characterLimit)
     * @param maxCharsPerLine Maximum characters per line (for .characterLimit mode)
     * @param wordsPerLine Number of words per line (for .wordCount mode)
     * @return Formatted text with appropriate line breaks inserted
     */
    func formatWithLineBreaks(mode: LineBreakMode, maxCharsPerLine: Int = 16, wordsPerLine: Int = 2) -> String {
        // Split message into individual words
        let words = text.split(separator: " ")
        
        // Apply the selected line break strategy
        switch mode {
        case .none:
            // No line breaks, return the original text
            return text
            
        case .wordCount:
            // Break after specified number of words
            var lines: [String] = []
            var currentLine: [String] = []
            
            for (index, word) in words.enumerated() {
                // Add word to current line
                currentLine.append(String(word))
                
                // Create new line when word limit reached or at end
                if (index + 1) % wordsPerLine == 0 || index == words.count - 1 {
                    lines.append(currentLine.joined(separator: " "))
                    currentLine = []
                }
            }
            
            // Join lines with newlines
            return lines.joined(separator: "\n")
            
        case .characterLimit:
            // Break when line exceeds character limit
            var lines: [String] = []
            var currentLine: [String] = []
            var currentLength = 0
            
            for word in words {
                let wordLength = word.count
                let spaceNeeded = currentLine.isEmpty ? 0 : 1  // Account for space before word
                
                // Check if adding this word would exceed the limit
                if currentLength + wordLength + spaceNeeded <= maxCharsPerLine {
                    // Word fits on current line
                    currentLine.append(String(word))
                    currentLength += wordLength + (currentLine.count > 1 ? 1 : 0)
                } else {
                    // Word doesn't fit, start a new line
                    if !currentLine.isEmpty {
                        lines.append(currentLine.joined(separator: " "))
                    }
                    currentLine = [String(word)]
                    currentLength = wordLength
                }
            }
            
            // Add any remaining text in the last line
            if !currentLine.isEmpty {
                lines.append(currentLine.joined(separator: " "))
            }
            
            // Join lines with newlines
            return lines.joined(separator: "\n")
        }
    }
    
    /**
     * Update the status of this message
     *
     * Changes the message status and handles any side effects of the state change,
     * such as recording the sent timestamp when a message is displayed.
     *
     * @param newStatus The new status to apply to this message
     */
    mutating func updateStatus(_ newStatus: MessageStatus) {
        // Update the status
        status = newStatus
        
        // Handle side effects of status transitions
        if newStatus == .sent {
            // Record when the message was sent to the display
            sentAt = Date()
        }
    }
}