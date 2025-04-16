//
//  NewMessageView.swift
//  LEDMESSENGER
//
//  Created by Claude AI on 4/12/2025.
//

import SwiftUI

/// View for creating or editing a message
struct NewMessageView: View {
    @ObservedObject var viewModel: MessageViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Local state for form inputs
    @State private var messageText: String = ""
    @State private var identifier: String = ""
    @State private var labelType: LabelType = .tableNumber
    @State private var customLabel: String = ""
    
    // Initialize with view model
    init(viewModel: MessageViewModel) {
        self.viewModel = viewModel
        
        // Initialize state from existing message or defaults
        _messageText = State(initialValue: viewModel.newMessageText)
        _identifier = State(initialValue: viewModel.newMessageIdentifier)
        _labelType = State(initialValue: viewModel.newMessageLabelType)
        _customLabel = State(initialValue: viewModel.newMessageCustomLabel)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text(viewModel.editingMessageId != nil ? "EDIT MESSAGE" : "NEW MESSAGE")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .tracking(1.0)
                .padding(.top, 25)
                .padding(.bottom, 25)
            
            // Message form
            VStack(spacing: 22) {
                // Label settings
                VStack(alignment: .leading, spacing: 10) {
                    Text("LABEL TYPE")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    
                    Picker("Label Type", selection: $labelType) {
                        ForEach(LabelType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .background(Color(white: 0.1))
                    .cornerRadius(5)
                }
                
                // Label identifier field (table number, etc)
                VStack(alignment: .leading, spacing: 10) {
                    Text(labelType == .tableNumber ? "TABLE NUMBER" : 
                         labelType == .customerName ? "CUSTOMER NAME" : 
                         labelType == .custom ? "CUSTOM LABEL" : "IDENTIFIER")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    
                    if labelType == .custom {
                        #if os(iOS)
                        // iOS-specific implementation with better touch responsiveness
                        TextField("VIP", text: $customLabel)
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Theme.bgTop.opacity(0.3))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Theme.accentBlue.opacity(0.5), lineWidth: 1)
                            )
                            .keyboardType(.default)
                            .autocapitalization(.allCharacters)
                            .disableAutocorrection(true)
                        #else
                        // macOS implementation
                        TextField("VIP", text: $customLabel)
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Theme.bgTop.opacity(0.3))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Theme.accentBlue.opacity(0.5), lineWidth: 1)
                            )
                            .textFieldStyle(PlainTextFieldStyle())
                        #endif
                    } else {
                        #if os(iOS)
                        // iOS-specific implementation with better touch responsiveness
                        TextField(labelType == .tableNumber ? "5" : "123", text: $identifier)
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Theme.bgTop.opacity(0.3))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Theme.accentBlue.opacity(0.5), lineWidth: 1)
                            )
                            .keyboardType(labelType == .tableNumber ? .numberPad : .default)
                            .autocapitalization(.allCharacters)
                            .disableAutocorrection(true)
                            .onChange(of: identifier) { newValue in
                                // For table numbers, allow only digits
                                if labelType == .tableNumber && !newValue.allSatisfy({ $0.isNumber }) {
                                    identifier = newValue.filter { $0.isNumber }
                                }
                            }
                        #else
                        // macOS implementation
                        TextField(labelType == .tableNumber ? "5" : "123", text: $identifier)
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Theme.bgTop.opacity(0.3))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Theme.accentBlue.opacity(0.5), lineWidth: 1)
                            )
                            .textFieldStyle(PlainTextFieldStyle())
                            .onChange(of: identifier) { newValue in
                                // For table numbers, allow only digits
                                if labelType == .tableNumber && !newValue.allSatisfy({ $0.isNumber }) {
                                    identifier = newValue.filter { $0.isNumber }
                                }
                            }
                        #endif
                    }
                }
                
                // Message text
                VStack(alignment: .leading, spacing: 10) {
                    Text("MESSAGE")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    
                    #if os(iOS)
                    // iOS-specific implementation for better touch responsiveness
                    TextField("Enter message text", text: $messageText)
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Theme.bgTop.opacity(0.3))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Theme.accentPink.opacity(0.5), lineWidth: 1)
                        )
                        .keyboardType(.asciiCapable)
                        .autocapitalization(.allCharacters)
                        .disableAutocorrection(true)
                        .onChange(of: messageText) { newValue in
                            if newValue != newValue.uppercased() {
                                messageText = newValue.uppercased()
                            }
                        }
                    #else
                    // macOS implementation
                    TextField("Enter message text", text: $messageText)
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Theme.bgTop.opacity(0.3))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Theme.accentPink.opacity(0.5), lineWidth: 1)
                        )
                        .textFieldStyle(PlainTextFieldStyle())
                        .onChange(of: messageText) { newValue in
                            if newValue != newValue.uppercased() {
                                messageText = newValue.uppercased()
                            }
                        }
                    #endif
                }
            }
            .padding(.horizontal, 30)
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 20) {
                // Cancel button
                Button {
                    // Reset editing state and dismiss
                    viewModel.editingMessageId = nil
                    viewModel.newMessageText = ""
                    viewModel.newMessageIdentifier = ""
                    dismiss()
                } label: {
                    Text("CANCEL")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 120)
                        .padding(.vertical, 14)
                        .background(Theme.secondaryGradient)
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
                }
                #if os(iOS)
                // iOS-specific styling for better touch response
                .buttonStyle(BorderlessButtonStyle())
                .contentShape(Rectangle())
                // Add a minimum tap area for better touch targets
                .frame(minWidth: 120, minHeight: 44)
                #else
                .buttonStyle(PlainButtonStyle())
                .contentShape(Rectangle())
                .keyboardShortcut(.escape, modifiers: [])
                #endif
                
                Spacer()
                
                // Save button
                Button {
                    saveMessage()
                    // Just use the environment dismiss
                    dismiss()
                } label: {
                    Text("QUEUE MESSAGE")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 180)
                        .padding(.vertical, 14)
                        .background(Theme.primaryGradient)
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
                }
                #if os(iOS)
                // On iOS, use the default button style which provides better touch feedback
                .buttonStyle(BorderlessButtonStyle()) 
                .contentShape(Rectangle())
                // Add a minimum tap area size for better touch targets
                .frame(minWidth: 180, minHeight: 44)
                #else
                .buttonStyle(PlainButtonStyle())
                .contentShape(Rectangle())
                .keyboardShortcut(.return, modifiers: [.command])
                #endif
                .disabled(messageText.isEmpty)
                .opacity(messageText.isEmpty ? 0.5 : 1.0)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 30)
            .padding(.top, 5)
        }
        .frame(width: 420, height: 440)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.cardGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Theme.accentBlue.opacity(0.6),
                                    Theme.accentPurple.opacity(0.6),
                                    Theme.accentPink.opacity(0.6)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
        )
        .onAppear {
            // Auto-capitalize message text
            messageText = messageText.uppercased()
        }
        // Enable keyboard events for the modal
        #if os(macOS)
        .onExitCommand {
            // Handle ESC key directly
            dismiss()
        }
        #endif
    }
    
    /// Save/update the message
    private func saveMessage() {
        // Ensure text is uppercase
        let finalText = messageText.uppercased()
        
        // Get appropriate label identifier
        let finalIdentifier = labelType == .custom ? customLabel : identifier
        
        if let editingId = viewModel.editingMessageId {
            // Update existing message
            viewModel.editMessage(
                id: editingId,
                text: finalText,
                identifier: finalIdentifier,
                labelType: labelType,
                customLabel: customLabel
            )
        } else {
            // Create new message
            viewModel.addMessage(
                text: finalText,
                identifier: finalIdentifier,
                labelType: labelType,
                customLabel: customLabel
            )
        }
        
        // Save the current settings for next time
        viewModel.newMessageLabelType = labelType
        viewModel.newMessageCustomLabel = customLabel
        
        // Reset editing state
        viewModel.editingMessageId = nil
        viewModel.newMessageText = ""
        viewModel.newMessageIdentifier = ""
        
        // Dismiss the sheet immediately
        dismiss()
    }
}