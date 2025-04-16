//
//  SetupView.swift
//  CLAUDELED
//
//  Created by Claude AI on 4/12/2025.
//

import SwiftUI

/**
 * Setup page navigation model that defines the different setup screens
 * 
 * Each page in the multi-step setup process is represented by a case in this enum,
 * allowing for clean navigation between configuration screens
 */
enum SetupPage: Int, CaseIterable {
    /// First page: IP address and port configuration for OSC connection
    case connection = 0
    
    /// Second page: Layer, slot configuration and T-box visualization
    case clipSetup = 1
    
    /// Third page: Line break and text formatting options
    case formatting = 2
    
    /// User-friendly title for each page to display in the UI header
    var title: String {
        switch self {
        case .connection: return "CONNECTION SETUP"
        case .clipSetup: return "CLIP CONFIGURATION"
        case .formatting: return "TEXT FORMATTING"
        }
    }
}

/**
 * Main setup view for configuring the application
 * 
 * This view provides a multi-page setup process to configure:
 * - Connection settings (IP, port)
 * - Clip configuration (layer, start slot)
 * - Text formatting options (line breaks)
 *
 * Features a consistent navigation pattern with Back/Next buttons
 * and the LEDM logo displayed prominently at the top of each page.
 */
struct SetupView: View {
    /// Main app view model
    @ObservedObject var viewModel: AppViewModel
    
    // Current setup page for multi-step navigation
    @State private var currentPage: SetupPage = .connection
    
    // Connection settings
    @State private var ipAddress: String
    @State private var port: String
    @State private var layer: String
    @State private var startingClip: String
    @State private var clearClip: String
    @State private var isConnecting = false
    
    // Text formatting settings
    @State private var lineBreakMode: LineBreakMode
    @State private var maxCharsPerLine: Int
    @State private var wordsPerLine: Int
    @State private var messageCountdownMinutes: Int
    
    /**
     * Initialize with settings from the view model
     *
     * Pulls all initial values from the existing settings to maintain
     * consistency between app sessions.
     */
    init(viewModel: AppViewModel) {
        self.viewModel = viewModel
        
        // Initialize connection settings from saved values
        _ipAddress = State(initialValue: viewModel.settingsManager.settings.osc.ipAddress)
        _port = State(initialValue: String(viewModel.settingsManager.settings.osc.port))
        _layer = State(initialValue: String(viewModel.settingsManager.settings.osc.layer))
        _startingClip = State(initialValue: String(viewModel.settingsManager.settings.osc.startingClip))
        _clearClip = State(initialValue: String(viewModel.settingsManager.settings.osc.clearClip))
        
        // Initialize formatting settings from saved values
        _lineBreakMode = State(initialValue: viewModel.settingsManager.settings.formatting.lineBreakMode)
        _maxCharsPerLine = State(initialValue: viewModel.settingsManager.settings.formatting.maxCharsPerLine)
        _wordsPerLine = State(initialValue: viewModel.settingsManager.settings.formatting.wordsPerLine)
        _messageCountdownMinutes = State(initialValue: viewModel.settingsManager.settings.formatting.messageCountdownMinutes)
    }
    
    /**
     * Main view body with page navigation system
     *
     * Presents a consistent UI structure:
     * - Logo and header at top
     * - Content area in middle (changes based on currentPage)
     * - Navigation buttons at bottom
     */
    var body: some View {
        VStack(spacing: 20) {
            // Logo and Page Title
            VStack(spacing: 5) {
                // Logo displayed prominently at top center
                Image("ledmlogomsmall")
                    .frame(width: 77, height: 50)
                
                // Page title based on current setup page
                Text(currentPage.title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .tracking(1.5)
                    .shadow(color: Theme.accentPurple.opacity(0.7), radius: 3, x: 0, y: 0)
                
                // Connection status indicator (only on connection page)
                if currentPage == .connection {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(viewModel.connectionStatus == .connected ? Theme.successGreen : Color.gray)
                            .frame(width: 12, height: 12)
                            .shadow(color: viewModel.connectionStatus == .connected ? Theme.successGreen.opacity(0.6) : Color.clear, radius: 4)
                        
                        Text("RESOLUME \(viewModel.connectionStatus == .connected ? "CONNECTED" : "DISCONNECTED")")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(viewModel.connectionStatus == .connected ? Theme.successGreen : Color.gray)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(20)
                }
            }
            .padding(.top, 15)
            
            // Page-specific content area
            ScrollView {
                switch currentPage {
                case .connection:
                    connectionPageContent
                case .clipSetup:
                    clipSetupPageContent
                case .formatting:
                    formattingPageContent
                }
            }
            .frame(maxWidth: .infinity)
            
            Spacer()
            
            // Navigation buttons
            HStack(spacing: 20) {
                // Back button (hidden on first page)
                if currentPage != .connection {
                    Button {
                        withAnimation {
                            currentPage = SetupPage(rawValue: currentPage.rawValue - 1) ?? .connection
                        }
                    } label: {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("BACK")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(Theme.secondaryGradient)
                        .cornerRadius(25)
                    }
                    .consistentMacOSStyle()
                } else {
                    // Empty spacer to maintain layout when back button is hidden
                    Spacer()
                }
                
                // Next/Finish button
                Button {
                    if currentPage == .formatting {
                        // Save settings
                        saveSettings()
                        
                        // Start connection process
                        isConnecting = true
                        viewModel.completeSetup()
                    } else {
                        withAnimation {
                            currentPage = SetupPage(rawValue: currentPage.rawValue + 1) ?? .formatting
                        }
                    }
                } label: {
                    HStack {
                        if currentPage == .formatting {
                            Text(isConnecting ? "CONNECTING..." : "LET'S GO!")
                        } else {
                            Text("NEXT")
                        }
                        
                        if currentPage != .formatting {
                            Image(systemName: "chevron.right")
                        }
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(Theme.primaryGradient)
                    .cornerRadius(25)
                }
                .consistentMacOSStyle()
                .disabled(isConnecting)
                .opacity(isConnecting ? 0.7 : 1.0)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            
            // Show connection status when connecting
            if isConnecting {
                Text(viewModel.setupStatusMessage)
                    .font(.system(size: 16))
                    .foregroundColor(Theme.accentPurple)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 15)
            }
        }
        .background(Theme.backgroundGradient.edgesIgnoringSafeArea(.all))
    }
    
    // MARK: - Page Content Views
    
    /**
     * First setup page: Connection settings
     *
     * Allows configuration of:
     * - Resolume IP address
     * - OSC port number
     */
    private var connectionPageContent: some View {
        VStack(spacing: 25) {
            // IP address input field
            VStack(spacing: 6) {
                Text("RESOLUME IP ADDRESS")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
                
                TextField("Enter IP address", text: $ipAddress)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(width: 220)
                    .background(Color.black.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Theme.accentPurple, lineWidth: 1.5)
                            .shadow(color: Theme.accentPurple.opacity(0.5), radius: 3)
                    )
                    .cornerRadius(8)
                    #if os(macOS)
                    .textFieldStyle(PlainTextFieldStyle())
                    #endif
            }
            
            // OSC port configuration
            VStack(spacing: 15) {
                // Port input
                HStack {
                    Text("PORT:")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    TextField("2269", text: $port)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 70)
                        .multilineTextAlignment(.center)
                        .padding(8)
                        .background(Color.black.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Theme.accentPurple, lineWidth: 1.5)
                                .shadow(color: Theme.accentPurple.opacity(0.5), radius: 3)
                        )
                        .cornerRadius(8)
                        #if os(macOS)
                        .textFieldStyle(PlainTextFieldStyle())
                        #endif
                        .onChange(of: port) { newValue in
                            // Keep only digits
                            port = newValue.filter { $0.isNumber }
                        }
                }
            }
            .padding(.horizontal, 20)
            
            // Help text for connection setup
            VStack(spacing: 8) {
                Text("Open port \(port) in Resolume > Preferences > OSC")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textHighlight)
                    .multilineTextAlignment(.center)
                
                Text("IP address must match your Resolume computer")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textHighlight)
                    .multilineTextAlignment(.center)
                
                Text("Uses OSC protocol for communication")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 10)
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
        }
        .padding(.vertical, 20)
    }
    
    /**
     * Second setup page: Clip configuration
     *
     * Visualizes and configures:
     * - Text slot layout with T-boxes
     * - Layer number selection
     * - Starting clip number selection
     */
    private var clipSetupPageContent: some View {
        VStack(spacing: 25) {
            // Container for information text
            VStack(spacing: 15) {
                // Title for the section
                Text("HOW IT WORKS")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Theme.accentPurple)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                // Explanation text in consistent container
                VStack(spacing: 15) {
                    Text("LED MESSENGER uses sequential text clips in Resolume")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    let clipStart = Int(startingClip) ?? 1
                    Text("EXAMPLE: Layer \(layer), Slots \(clipStart)-\(clipStart+2)")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                        
                    Text("Clip \(clipStart+3) clears the message")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.15))
                .cornerRadius(8)
            }
            .padding(.horizontal, 20)
            .padding(.top, 5)
            
            // Visual representation of text slots with T-boxes
            VStack(spacing: 10) {
                Text("TEXT SLOTS")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                HStack(spacing: 12) {
                    // Three boxes with "T" (represent text slots)
                    ForEach(1...3, id: \.self) { _ in
                        Text("T")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .frame(width: 40, height: 40)
                            .background(Color.black.opacity(0.3))
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Theme.accentPurple, lineWidth: 1.5)
                                    .shadow(color: Theme.accentPurple.opacity(0.5), radius: 3)
                            )
                            .cornerRadius(5)
                    }
                    
                    // Empty box (represents clear slot)
                    Text("")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .frame(width: 40, height: 40)
                        .background(Color.black.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Theme.accentPurple, lineWidth: 1.5)
                                .shadow(color: Theme.accentPurple.opacity(0.5), radius: 3)
                        )
                        .cornerRadius(5)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            
            // Layer & Slot Selectors in consistent container
            VStack(spacing: 15) {
                Text("CLIP CONFIGURATION")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Theme.accentPurple)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                // Centered control group
                VStack(spacing: 20) {
                    // Side-by-side controls in a single row
                    HStack(spacing: 30) {
                        // Layer number selector
                        VStack(spacing: 10) {
                            Text("LAYER")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            HStack {
                                Button(action: {
                                    let layerNum = max(1, (Int(layer) ?? 5) - 1)
                                    layer = "\(layerNum)"
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(Theme.accentPurple)
                                }
                                .consistentMacOSStyle()
                                
                                Text(layer)
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 50)
                                    .multilineTextAlignment(.center)
                                    .padding(6)
                                    .background(Color.black.opacity(0.3))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Theme.accentPurple, lineWidth: 1.5)
                                            .shadow(color: Theme.accentPurple.opacity(0.5), radius: 3)
                                    )
                                    .cornerRadius(8)
                                
                                Button(action: {
                                    let layerNum = min(20, (Int(layer) ?? 5) + 1)
                                    layer = "\(layerNum)"
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(Theme.accentPurple)
                                }
                                .consistentMacOSStyle()
                            }
                        }
                        
                        // Starting Slot selector
                        VStack(spacing: 10) {
                            Text("START SLOT")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            HStack {
                                Button(action: {
                                    let slotNum = max(1, (Int(startingClip) ?? 3) - 1)
                                    startingClip = "\(slotNum)"
                                    // Always set clear clip to startingClip + 3
                                    clearClip = "\(slotNum + 3)"
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(Theme.accentPurple)
                                }
                                .consistentMacOSStyle()
                                
                                Text(startingClip)
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 50)
                                    .multilineTextAlignment(.center)
                                    .padding(6)
                                    .background(Color.black.opacity(0.3))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Theme.accentPurple, lineWidth: 1.5)
                                            .shadow(color: Theme.accentPurple.opacity(0.5), radius: 3)
                                    )
                                    .cornerRadius(8)
                                
                                Button(action: {
                                    let slotNum = min(50, (Int(startingClip) ?? 3) + 1)
                                    startingClip = "\(slotNum)"
                                    // Always set clear clip to startingClip + 3
                                    clearClip = "\(slotNum + 3)"
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(Theme.accentPurple)
                                }
                                .consistentMacOSStyle()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 15)
                .background(Color.black.opacity(0.15))
                .cornerRadius(8)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.horizontal, 20)
            
            // Help text at the bottom
            Text("Layer must be active with visual slider up to see messages")
                .font(.system(size: 14))
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, 30)
                .padding(.top, 10)
        }
        .padding(.vertical, 10)
    }
    
    /**
     * Third setup page: Text formatting options
     *
     * Configures:
     * - Line break mode (none, words, characters)
     * - Line break parameters based on selected mode
     * - Live text preview with current settings
     */
    private var formattingPageContent: some View {
        VStack(spacing: 25) {
            // Title container
            VStack(spacing: 5) {
                Text("TEXT FORMATTING")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Theme.accentPurple)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.top, 10)
            
            // Message countdown setting
            VStack(alignment: .center, spacing: 8) {
                // Top row with controls
                HStack(alignment: .center) {
                    Text("Message Display Duration:")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
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
                            .frame(width: 28, height: 28)
                            .background(Color.purple.opacity(0.4))
                            .cornerRadius(4)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    
                    // Value display
                    Text("\(messageCountdownMinutes)")
                        .font(.system(size: 18).bold())
                        .foregroundColor(Color.white)
                        .frame(width: 30)
                        .padding(.horizontal, 2)
                    
                    // Plus button
                    Button(action: {
                        if messageCountdownMinutes < 60 {
                            messageCountdownMinutes += 1
                        }
                    }) {
                        Text("+")
                            .font(.system(size: 16).bold())
                            .foregroundColor(Color.white)
                            .frame(width: 28, height: 28)
                            .background(Color.purple.opacity(0.4))
                            .cornerRadius(4)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    
                    Text("minutes")
                        .font(.system(size: 14))
                        .foregroundColor(Color.white)
                        .lineLimit(1)
                }
                .padding(.horizontal, 5)
                
                Text("How long messages stay on the LED wall")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(10)
            .background(Color.purple.opacity(0.2))
            .cornerRadius(8)
            .padding(.horizontal, 20)
            .padding(.bottom, 10)
            
            // Container for all settings in a card
            VStack(spacing: 20) {
                // Line break mode selector
                VStack(spacing: 10) {
                    Text("Line Break Mode")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    Picker("", selection: $lineBreakMode) {
                        ForEach(LineBreakMode.allCases) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(5)
                    .background(Color.purple.opacity(0.2))
                    .cornerRadius(5)
                    
                    Text("Select how text is split across lines")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.horizontal, 15)
                
                // Character limit settings (only shown for characterLimit mode)
                if lineBreakMode == .characterLimit {
                    VStack(spacing: 10) {
                        Text("Maximum Characters Per Line: \(maxCharsPerLine)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        HStack {
                            Slider(value: Binding(
                                get: { Double(maxCharsPerLine) },
                                set: { maxCharsPerLine = Int($0) }
                            ), in: 10...100, step: 5)
                            
                            Stepper("", value: $maxCharsPerLine, in: 10...100)
                                .labelsHidden()
                        }
                        .padding(.horizontal, 15)
                        
                        Text("Default: 16 chars (fits 'LEDMESSENGER.COM')")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.15))
                    .cornerRadius(8)
                }
                
                // Words per line settings (only shown for wordCount mode)
                if lineBreakMode == .wordCount {
                    VStack(spacing: 10) {
                        Text("Words Per Line: \(wordsPerLine)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        HStack {
                            Slider(value: Binding(
                                get: { Double(wordsPerLine) },
                                set: { wordsPerLine = Int($0) }
                            ), in: 1...10, step: 1)
                            
                            Stepper("", value: $wordsPerLine, in: 1...10)
                                .labelsHidden()
                        }
                        .padding(.horizontal, 15)
                        
                        Text("Default: 2 words per line")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.15))
                    .cornerRadius(8)
                }
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                    .padding(.vertical, 5)
                
                // Text transformation information
                VStack(spacing: 8) {
                    Text("Text Transformation")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    Text("All text converted to UPPERCASE for better visibility")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.horizontal, 20)
                
                // Live text preview with current formatting
                VStack(spacing: 12) {
                    Text("PREVIEW")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Theme.accentPurple)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 5)
                    
                    // Formatted text preview using current settings
                    let previewText = "SAMPLE LED MESSENGER TEXT FOR PREVIEW"
                    let formattedText = formatTextForPreview(previewText)
                    
                    Text(formattedText)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .lineSpacing(8)
                        .multilineTextAlignment(.center)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .background(Theme.cardBgDark)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.purple, lineWidth: 1)
                        )
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.15))
                .cornerRadius(8)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 15)
        }
        .frame(maxWidth: .infinity)
    }
    
    /**
     * Format sample text with current formatting settings
     *
     * Used by the preview section to show how text would appear with
     * the current line break settings.
     *
     * - Parameter text: Sample text to format
     * - Returns: Formatted text with appropriate line breaks applied
     */
    private func formatTextForPreview(_ text: String) -> String {
        let dummyMessage = Message(text: text)
        return dummyMessage.formatWithLineBreaks(
            mode: lineBreakMode,
            maxCharsPerLine: maxCharsPerLine,
            wordsPerLine: wordsPerLine
        )
    }
    
    /**
     * Save all settings to the app's persistent storage
     *
     * Called when user completes the setup process to persist their choices
     * for both OSC connection settings and text formatting preferences.
     */
    private func saveSettings() {
        // Parse values from string inputs
        let parsedPort = Int(port) ?? 2269
        let parsedLayer = Int(layer) ?? 5
        let parsedStartingClip = Int(startingClip) ?? 1
        let parsedClearClip = Int(clearClip) ?? (parsedStartingClip + 3)
        
        // Update OSC connection settings
        viewModel.updateOSCSettings(
            ipAddress: ipAddress,
            port: parsedPort,
            layer: parsedLayer,
            startingClip: parsedStartingClip,
            clearClip: parsedClearClip
        )
        
        // Update text formatting settings
        viewModel.settingsManager.updateFormattingSettings(
            lineBreakMode: lineBreakMode,
            maxCharsPerLine: maxCharsPerLine,
            wordsPerLine: wordsPerLine,
            messageCountdownMinutes: messageCountdownMinutes
        )
    }
}