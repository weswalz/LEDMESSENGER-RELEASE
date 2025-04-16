//
//  CustomizationView.swift
//  CLAUDELED
//
//  Created by Claude AI on 4/12/2025.
//

import SwiftUI

/// View for customizing message display options
struct CustomizationView: View {
    @ObservedObject var viewModel: AppViewModel
    
    // Local state for form
    @State private var lineBreakMode: LineBreakMode
    @State private var maxCharsPerLine: Int
    @State private var wordsPerLine: Int
    @State private var defaultLabelType: LabelType
    @State private var defaultCustomLabel: String
    @State private var messageCountdownMinutes: Int
    
    // Selected section
    @State private var selectedSection: CustomizationSection = .messageSettings
    
    // Preview text
    @State private var previewText = "SAMPLE LED MESSENGER TEXT FOR PREVIEW"
    
    // Initialize with view model
    init(viewModel: AppViewModel) {
        self.viewModel = viewModel
        
        // Initialize from settings
        _lineBreakMode = State(initialValue: viewModel.settingsManager.settings.formatting.lineBreakMode)
        _maxCharsPerLine = State(initialValue: viewModel.settingsManager.settings.formatting.maxCharsPerLine)
        _wordsPerLine = State(initialValue: viewModel.settingsManager.settings.formatting.wordsPerLine)
        _defaultLabelType = State(initialValue: viewModel.settingsManager.settings.formatting.defaultLabelType)
        _defaultCustomLabel = State(initialValue: viewModel.settingsManager.settings.formatting.defaultCustomLabel)
        _messageCountdownMinutes = State(initialValue: viewModel.settingsManager.settings.formatting.messageCountdownMinutes)
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 5) {
            Text("Message Display Customization")
                .font(.system(size: 22).bold())
                .foregroundColor(Color.white)
                .padding(.top, 12)
            
            Text("Configure how your messages will appear on the LED wall")
                .font(.system(size: 13))
                .foregroundColor(Color.gray)
        }
        .padding(.bottom, 10)
    }
    
    // MARK: - Tab Button
    private func tabButton(for section: CustomizationSection) -> some View {
        Button(action: {
            selectedSection = section
        }) {
            VStack(spacing: 3) {
                Image(systemName: section.iconName)
                    .font(.system(size: 12))
                
                Text(section.displayName)
                    .font(.system(size: 10).bold())
            }
            .foregroundColor(selectedSection == section ? Color.white : Color.gray.opacity(0.7))
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity)
            .background(tabButtonBackground(for: section))
        }
        .padding(.horizontal, 2)
    }
    
    // MARK: - Tab Button Background
    private func tabButtonBackground(for section: CustomizationSection) -> some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(selectedSection == section ? 
                  Theme.accentPurple.opacity(0.8) : 
                  Color.black.opacity(0.3))
            .padding(.horizontal, 4)
    }
    
    // MARK: - Tab Selection
    private var tabSelectionView: some View {
        HStack(spacing: 2) {
            ForEach(CustomizationSection.allCases, id: \.self) { section in
                tabButton(for: section)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .padding(.top, 25) // 25px padding at top as requested
        .background(Theme.cardBgDark)
    }
    
    // MARK: - Content Area
    private var contentAreaView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Section content based on selection
                switch selectedSection {
                case .textFormatting:
                    textFormattingSection
                case .messageSettings:
                    messageSettingsSection
                case .labelSettings:
                    labelSettingsSection
                case .templateManagement:
                    templateManagementSection
                }
                
                // Preview
                previewSection
            }
            .padding(20)
        }
    }
    
    // MARK: - Action Bar
    private var actionBarView: some View {
        HStack(spacing: 15) {
            // Back button
            Button(action: {
                // Discard changes and go back
                viewModel.navigateToMessageManagement()
            }) {
                Text("BACK")
                    .font(.system(size: 12).bold())
                    .foregroundColor(Color.white)
                    .tracking(0.5)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Theme.secondaryGradient)
                    .cornerRadius(5)
            }
            .consistentMacOSStyle()
            
            // Save button
            Button(action: {
                // Save settings
                saveSettings()
                
                // Update Resolume formatting
                Task {
                    await viewModel.messageViewModel.updateResolumeFormatting()
                }
                
                // Return to message management
                viewModel.navigateToMessageManagement()
            }) {
                Text("LET'S GO!")
                    .font(.system(size: 12).bold())
                    .foregroundColor(Color.white)
                    .tracking(0.5)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Theme.primaryGradient)
                    .cornerRadius(5)
            }
            .consistentMacOSStyle()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content
            VStack(spacing: 0) {
                headerView
                tabSelectionView
                
                // Content area
                contentAreaView
                    // Add space at the bottom to account for the action bar plus the requested 25px
                    .padding(.bottom, 82) // 57px for action bar + 25px extra space
            }
            
            // Action bar with limited background
            VStack(spacing: 0) {
                // Dark background that extends 25px above the buttons
                Rectangle()
                    .fill(Theme.bgBottom)
                    .frame(height: 25)
                
                // Action bar with its existing background
                actionBarView
                    .background(Theme.bgBottom)
            }
        }
        .background(Theme.backgroundGradient.edgesIgnoringSafeArea(.all))
    }
    
    /// Line break mode selector
    private var lineBreakModeSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Line Break Mode")
                .font(.headline)
                .foregroundColor(Color.white)
            
            Picker("Line Break Mode", selection: $lineBreakMode) {
                ForEach(LineBreakMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(5)
            .background(Color.purple.opacity(0.2))
            .cornerRadius(5)
            
            Text("Choose how text is split into multiple lines")
                .font(.caption)
                .foregroundColor(Color.gray)
        }
    }
    
    /// Character limit settings
    private var characterLimitSettings: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Maximum Characters Per Line: \(maxCharsPerLine)")
                .font(.headline)
                .foregroundColor(Color.white)
            
            HStack {
                Slider(value: Binding(
                    get: { Double(maxCharsPerLine) },
                    set: { maxCharsPerLine = Int($0) }
                ), in: 10...30, step: 1)
                
                Stepper("", value: $maxCharsPerLine, in: 10...30)
                    .labelsHidden()
            }
            
            Text("Default is 16 characters, which fits phrases like 'LEDMESSENGER.COM'")
                .font(.caption)
                .foregroundColor(Color.gray)
        }
    }
    
    /// Word count settings
    private var wordCountSettings: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Words Per Line: \(wordsPerLine)")
                .font(.headline)
                .foregroundColor(Color.white)
            
            HStack {
                Slider(value: Binding(
                    get: { Double(wordsPerLine) },
                    set: { wordsPerLine = Int($0) }
                ), in: 1...6, step: 1)
                
                Stepper("", value: $wordsPerLine, in: 1...6)
                    .labelsHidden()
            }
            
            Text("Default is 2 words per line. More words per line means fewer lines overall.")
                .font(.caption)
                .foregroundColor(Color.gray)
        }
    }
    
    /// Text transformation info
    private var textTransformationInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Text Transformation")
                .font(.headline)
                .foregroundColor(Color.white)
            
            Text("All text is automatically converted to UPPERCASE to maximize visibility on LED walls")
                .font(.caption)
                .foregroundColor(Color.gray)
        }
    }

    /// Text formatting section
    private var textFormattingSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            sectionHeader("TEXT FORMATTING")
            
            // Line break mode
            lineBreakModeSelector
            
            // Character limit
            if lineBreakMode == .characterLimit {
                characterLimitSettings
            }
            
            // Words per line
            if lineBreakMode == .wordCount {
                wordCountSettings
            }
            
            Divider()
                .background(Color.gray.opacity(0.3))
                .padding(.vertical, 10)
            
            // Text transformation
            textTransformationInfo
        }
    }
    
    /// Message countdown duration control
    private var messageCountdownControl: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 5) {
                Text("Message Display Duration:")
                    .font(.headline)
                    .foregroundColor(Theme.accentPurple)
                    .lineLimit(1)
                
                Spacer()
                
                // Minus button
                Button(action: {
                    if messageCountdownMinutes > 1 {
                        messageCountdownMinutes -= 1
                    }
                }) {
                    Text("-")
                        .font(.system(size: 16).bold())
                        .foregroundColor(Color.white)
                        .frame(width: 24, height: 24)
                        .background(Color.purple.opacity(0.3))
                        .cornerRadius(4)
                }
                .buttonStyle(BorderlessButtonStyle())
                
                // Value display
                Text("\(messageCountdownMinutes)")
                    .font(.system(size: 16).bold())
                    .foregroundColor(Color.white)
                    .frame(width: 26)
                
                // Plus button
                Button(action: {
                    if messageCountdownMinutes < 60 {
                        messageCountdownMinutes += 1
                    }
                }) {
                    Text("+")
                        .font(.system(size: 16).bold())
                        .foregroundColor(Color.white)
                        .frame(width: 24, height: 24)
                        .background(Color.purple.opacity(0.3))
                        .cornerRadius(4)
                }
                .buttonStyle(BorderlessButtonStyle())
                
                Text("minutes")
                    .font(.system(size: 14))
                    .foregroundColor(Color.white.opacity(0.7))
                    .lineLimit(1)
            }
            
            // Slider with min/max labels
            HStack(spacing: 10) {
                Text("1")
                    .font(.caption)
                    .foregroundColor(Color.gray)
                
                Slider(value: Binding(
                    get: { Double(messageCountdownMinutes) },
                    set: { messageCountdownMinutes = Int($0) }
                ), in: 1...60, step: 1)
                .accentColor(Theme.accentPurple)
                
                Text("60")
                    .font(.caption)
                    .foregroundColor(Color.gray)
            }
            
            Text("Time until message auto-returns to queue")
                .font(.caption)
                .foregroundColor(Color.gray)
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(countdownBackground)
        .onChange(of: messageCountdownMinutes) { newValue in
            // Ensure value stays in range
            if newValue < 1 {
                messageCountdownMinutes = 1
            } else if newValue > 60 {
                messageCountdownMinutes = 60
            }
        }
    }
    
    /// Background for the countdown control
    private var countdownBackground: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.black.opacity(0.5))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Theme.accentPurple.opacity(0.6), lineWidth: 1)
            )
    }
    
    /// Message behavior explanation
    private var messageBehaviorExplanation: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Message Behavior")
                .font(.headline)
                .foregroundColor(Color.white)
            
            Text("• Sent messages will automatically return to the queue after the countdown")
                .font(.caption)
                .foregroundColor(Color.gray)
            
            Text("• The 'RETURN TO QUEUE' button manually returns a sent message to the queue")
                .font(.caption)
                .foregroundColor(Color.gray)
            
            Text("• The 'DELETE' button permanently removes a queued message")
                .font(.caption)
                .foregroundColor(Color.gray)
        }
    }
    
    /// Message settings section
    private var messageSettingsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            sectionHeader("MESSAGE TIMING")
            
            // Message countdown duration control
            messageCountdownControl
            
            Divider()
                .background(Color.gray.opacity(0.3))
                .padding(.vertical, 10)
            
            // Message behavior explanation
            messageBehaviorExplanation
        }
    }
    
    /// Label type selector
    private var labelTypeSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Default Label Type")
                .font(.headline)
                .foregroundColor(Color.white)
            
            Picker("Default Label Type", selection: $defaultLabelType) {
                ForEach(LabelType.allCases) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(5)
            .background(Color.purple.opacity(0.2))
            .cornerRadius(5)
            
            Text("The default label type for new messages")
                .font(.caption)
                .foregroundColor(Color.gray)
        }
    }
    
    /// Custom label input field
    private var customLabelInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Default Custom Label")
                .font(.headline)
                .foregroundColor(Color.white)
            
            TextField("VIP", text: $defaultCustomLabel)
                .font(.body)
                .foregroundColor(Color.white)
                .padding()
                .background(Color.purple.opacity(0.2))
                .cornerRadius(8)
                #if os(macOS)
                .textFieldStyle(PlainTextFieldStyle())
                #else
                // Fix for iPad text field responsiveness issues
                .textFieldStyle(DefaultTextFieldStyle())
                .autocorrectionDisabled(true)
                #endif
            
            Text("Examples: VIP, Guest, Event, Booth, etc.")
                .font(.caption)
                .foregroundColor(Color.gray)
        }
    }
    
    /// Label behavior info
    private var labelBehaviorInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Label Behavior")
                .font(.headline)
                .foregroundColor(Color.white)
            
            Text("Labels are shown as prefixes to messages, e.g., 'Table 5: HAPPY BIRTHDAY'")
                .font(.caption)
                .foregroundColor(Color.gray)
        }
    }

    /// Label settings section
    private var labelSettingsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            sectionHeader("LABEL SETTINGS")
            
            // Default label type
            labelTypeSelector
            
            // Custom label
            if defaultLabelType == .custom {
                customLabelInput
            }
            
            Divider()
                .background(Color.gray.opacity(0.3))
                .padding(.vertical, 10)
            
            // Label behavior
            labelBehaviorInfo
        }
    }
    
    /// Template management info content
    private var templateManagementInfo: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Templates allow you to quickly create commonly used messages")
                .font(.headline)
                .foregroundColor(Color.white)
            
            Text("Templates can be accessed when creating a new message")
                .font(.caption)
                .foregroundColor(Color.gray)
            
            // Placeholder for future template management features
            Text("Template management is available when creating new messages")
                .font(.body)
                .foregroundColor(Color.gray)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.purple.opacity(0.1))
                .cornerRadius(10)
        }
    }

    /// Template management section (simplified)
    private var templateManagementSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            sectionHeader("TEMPLATE MANAGEMENT")
            
            // Template management info
            templateManagementInfo
        }
    }
    
    /// Sample text input field
    private var sampleTextInput: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Enter sample text:")
                .font(.headline)
                .foregroundColor(Color.white)
            
            TextField("SAMPLE TEXT", text: $previewText)
                .font(.body)
                .foregroundColor(Color.white)
                .padding()
                .background(Color.purple.opacity(0.2))
                .cornerRadius(8)
                #if os(macOS)
                .textFieldStyle(PlainTextFieldStyle())
                #else
                // Fix for iPad text field responsiveness issues
                .textFieldStyle(DefaultTextFieldStyle())
                .autocorrectionDisabled(true)
                .autocapitalization(.allCharacters)
                #endif
                .onChange(of: previewText) { newValue in
                    if newValue != newValue.uppercased() {
                        previewText = newValue.uppercased()
                    }
                }
        }
    }
    
    /// Formatted text preview display
    private var formattedTextPreview: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Message with formatting applied:")
                .font(.headline)
                .foregroundColor(Color.white)
                .padding(.top, 10)
            
            // Formatted text preview
            let formattedText = formatTextForPreview(previewText)
            Text(formattedText)
                .font(.system(size: 18).bold())
                .foregroundColor(Color.white)
                .lineSpacing(8)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.cardBgDark)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.purple, lineWidth: 1)
                )
        }
    }

    /// Preview section
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            sectionHeader("PREVIEW")
            
            VStack(alignment: .leading, spacing: 10) {
                // Sample text input
                sampleTextInput
                
                // Formatted preview
                formattedTextPreview
            }
        }
    }
    
    /// Create a section header
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 16).bold())
            .foregroundColor(Color.purple)
            .padding(.vertical, 5)
    }
    
    /// Format text according to settings for preview
    private func formatTextForPreview(_ text: String) -> String {
        let dummyMessage = Message(text: text)
        return dummyMessage.formatWithLineBreaks(
            mode: lineBreakMode,
            maxCharsPerLine: maxCharsPerLine,
            wordsPerLine: wordsPerLine
        )
    }
    
    /// Save the settings
    private func saveSettings() {
        viewModel.settingsManager.updateFormattingSettings(
            lineBreakMode: lineBreakMode,
            maxCharsPerLine: maxCharsPerLine,
            wordsPerLine: wordsPerLine,
            defaultLabelType: defaultLabelType,
            defaultCustomLabel: defaultCustomLabel,
            messageCountdownMinutes: messageCountdownMinutes
        )
    }
}