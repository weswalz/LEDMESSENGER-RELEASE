//
//  MessageTemplate.swift
//  CLAUDELED
//
//  Created by Claude AI on 4/12/2025.
//

import Foundation

/**
 * A template for creating messages
 *
 * Templates allow for quick creation of commonly used messages
 * with predefined text, label type, and formatting.
 */
struct MessageTemplate: Identifiable, Hashable, Codable {
    /// Unique identifier for this template
    let id: UUID
    
    /// The name of this template (displayed in template selector)
    var name: String
    
    /// The template text content
    var text: String
    
    /// The type of label to use
    var labelType: LabelType
    
    /// Custom label text (used when labelType is .custom)
    var customLabel: String
    
    /**
     * Create a new template
     *
     * - Parameters:
     *   - id: Unique UUID (auto-generated if not provided)
     *   - name: Display name for the template
     *   - text: Message content text
     *   - labelType: Type of label to apply (default: .tableNumber)
     *   - customLabel: Text for custom label (if using .custom label type)
     */
    init(
        id: UUID = UUID(),
        name: String,
        text: String,
        labelType: LabelType = .tableNumber,
        customLabel: String = ""
    ) {
        self.id = id
        self.name = name
        self.text = text.uppercased() // Ensure text is uppercase
        self.labelType = labelType
        self.customLabel = customLabel
    }
    
    /**
     * Create a message from this template
     *
     * Generates a new Message instance with properties copied from the template,
     * allowing for quick creation of standardized messages.
     *
     * - Parameter identifier: Optional identifier (e.g., table number) for the message
     * - Returns: A new Message instance based on this template
     */
    func createMessage(identifier: String = "") -> Message {
        Message(
            text: text,
            identifier: identifier,
            labelType: labelType,
            customLabel: customLabel
        )
    }
    
    /**
     * Create a formatted preview of this template
     *
     * Generates a preview of how the message will appear, including
     * label and identifier if provided.
     *
     * - Parameter identifier: Optional identifier to include in the preview
     * - Returns: Formatted preview text
     */
    func formattedPreview(identifier: String = "") -> String {
        let message = createMessage(identifier: identifier)
        return message.formattedText
    }
    
    // MARK: - Standard Templates
    
    /**
     * Create a set of standard templates
     *
     * Provides commonly used message templates for quick setup.
     *
     * - Returns: Array of standard message templates
     */
    static func standardTemplates() -> [MessageTemplate] {
        return [
            MessageTemplate(
                name: "Happy Birthday",
                text: "HAPPY BIRTHDAY",
                labelType: .tableNumber
            ),
            MessageTemplate(
                name: "Welcome VIP",
                text: "WELCOME VIP",
                labelType: .customerName
            ),
            MessageTemplate(
                name: "Congratulations",
                text: "CONGRATULATIONS",
                labelType: .none
            ),
            MessageTemplate(
                name: "Special Event",
                text: "SPECIAL EVENT",
                labelType: .none
            ),
            MessageTemplate(
                name: "New DJ Set",
                text: "NOW PLAYING: DJ",
                labelType: .custom,
                customLabel: "STAGE"
            )
        ]
    }
}