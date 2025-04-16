//
//  ContentView.swift
//  LEDMESSENGER
//
//  Created by Claude AI on 4/12/2025.
//

/**
 * Main content view for the LED Messenger application
 * Coordinates the display of different app states and manages UI transitions
 */

import SwiftUI
import Combine

/**
 * View extension that provides consistent button styling across platforms
 * Ensures that buttons have the same appearance and behavior on both macOS and iOS
 */
extension View {
    /**
     * Apply consistent button styling for macOS and iOS
     * On macOS, uses PlainButtonStyle for better click responsiveness
     * On iOS, maintains a consistent appearance with macOS
     * 
     * @return A modified view with platform-specific styling applied
     */
    func consistentMacOSStyle() -> some View {
        #if os(macOS)
        return self
            .buttonStyle(PlainButtonStyle())
            .contentShape(Rectangle()) // Increase hit area for better usability
        #else
        return self
            .buttonStyle(PlainButtonStyle())
            .contentShape(Rectangle()) // Increase hit area for better usability
        #endif
    }
}

/**
 * Animated splash screen shown at app launch
 * Features a logo animation and circular reveal transition
 */
struct SplashScreenView: View {
    /// Controls whether the splash screen is active
    @Binding var isActive: Bool
    /// Initial logo scale (starts larger for zoom effect)
    @State private var scale: CGFloat = 1.2
    /// Logo opacity for fade-in animation
    @State private var opacity: Double = 0
    /// Scale of the circular mask reveal effect
    @State private var maskScale: CGFloat = 0
    /// Whether to show the mask overlay
    @State private var showMask = false
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Gradient background from theme
                Theme.backgroundGradient
                    .edgesIgnoringSafeArea(.all)
                
                // Centered logo with animation properties
                VStack {
                    Image("ck120")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .scaleEffect(scale)
                        .opacity(opacity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Circular reveal animation implementation
                ZStack {
                    // Black overlay that will be masked to reveal content
                    Color.black
                        .opacity(showMask ? 1 : 0)
                        .animation(.easeInOut(duration: 0.3), value: showMask)
                    
                    // White circle mask that creates a "hole" in the overlay
                    Circle()
                        .fill(Color.white)
                        .frame(width: 300, height: 300)
                        .scaleEffect(maskScale)
                        .blendMode(.destinationOut)
                }
                .compositingGroup() // Required for proper blending
            }
        }
        .onAppear {
            // First animation: fade in and zoom logo
            withAnimation(.easeIn(duration: 0.4)) {
                opacity = 1
                scale = 1.0
            }
            
            // Schedule transition to main app after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                // Begin circular reveal transition sequence
                showMask = true  // Show the black overlay first
                
                // Step 1: Fade out the logo
                withAnimation(.easeOut(duration: 0.3)) {
                    opacity = 0
                }
                
                // Step 2: After logo fades, animate the circular reveal
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    // Grow the circle to reveal content underneath
                    withAnimation(.easeInOut(duration: 0.8)) {
                        maskScale = 5.0
                    }
                    
                    // After animation completes, deactivate splash screen
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                        self.isActive = false
                    }
                }
            }
        }
    }
}

/**
 * Custom button component for mode selection
 * Displays a mode option with appropriate styling for
 * selected and unselected states with visual feedback.
 */
struct ModeSelectButton: View {
    /// The app mode this button represents
    let mode: AppMode
    
    /// Whether this button is currently selected
    var isSelected: Bool
    
    /// The action to perform when tapped
    var action: () -> Void
    
    @State private var isPressed = false
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                // Mode icon with glowing effect
                ZStack {
                    // Background glow for selected state
                    Circle()
                        .fill(
                            isSelected ? 
                            (mode == .solo ? Theme.accentBlue : Theme.accentPurple) : 
                            Color.clear
                        )
                        .frame(width: 50, height: 50)
                        .blur(radius: 15)
                        .opacity(isSelected ? 0.7 : 0)
                    
                    // Icon container
                    Circle()
                        .fill(
                            isSelected ? 
                            (mode == .solo ? Theme.accentBlue : Theme.accentPurple) : 
                            Color.gray.opacity(0.2)
                        )
                        .frame(width: 44, height: 44)
                    
                    // Mode icon
                    Image(systemName: iconName)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(width: 44, height: 44)
                
                VStack(alignment: .leading, spacing: 5) {
                    // Mode name
                    Text(mode.displayName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    // Mode description
                    Text(mode.description)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Selection indicator
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
                    .opacity(isSelected ? 1.0 : 0.0)
                    .scaleEffect(isSelected ? 1.0 : 0.6)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(
                ZStack {
                    // Background fill with gradient
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            isSelected ? 
                            (mode == .solo ? 
                             LinearGradient(gradient: Gradient(colors: [Theme.accentBlue.opacity(0.8), Theme.accentBlue.opacity(0.4)]), startPoint: .topLeading, endPoint: .bottomTrailing) : 
                             LinearGradient(gradient: Gradient(colors: [Theme.accentPurple.opacity(0.8), Theme.accentPurple.opacity(0.4)]), startPoint: .topLeading, endPoint: .bottomTrailing)) : 
                            LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.1)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                    
                    // Button border
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isSelected ? 
                            (mode == .solo ? Theme.accentBlue : Theme.accentPurple) : 
                            (isHovered ? Color.white.opacity(0.3) : Color.gray.opacity(0.3)),
                            lineWidth: isSelected ? 2 : 1
                        )
                    
                    // Highlight overlay for hover state
                    if isHovered && !isSelected {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.05))
                    }
                }
            )
            .shadow(
                color: isSelected ? 
                (mode == .solo ? Theme.accentBlue.opacity(0.5) : Theme.accentPurple.opacity(0.5)) : 
                Color.black.opacity(0.1),
                radius: isSelected ? 8 : 2,
                x: 0,
                y: isSelected ? 4 : 1
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
            .contentShape(Rectangle())
            #if os(macOS)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovered = hovering
                }
            }
            #endif
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                        }
                    }
                    .onEnded { _ in
                        isPressed = false
                    }
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    /// Determine appropriate icon based on mode
    private var iconName: String {
        switch mode {
        case .solo:
            return "ipad"
        case .paired:
            return "ipad.and.mac"
        }
    }
}

/**
 * Mode selection screen for iPad
 * Displays a startup screen that allows the user to choose
 * between SOLO and PAIRED modes for iPad operation.
 */
struct ModeSelectionView: View {
    /// View model for app state and mode control
    @ObservedObject var viewModel: AppViewModel
    
    /// Current selected mode (independent of app actual mode)
    @State private var selectedMode: AppMode = .paired
    
    /// Animation state for buttons
    @State private var animateButtons = false
    @State private var animateBackground = false
    
    var body: some View {
        ZStack {
            // Animated background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Theme.accentPurple.opacity(0.4),
                    Theme.accentBlue.opacity(0.2),
                    Color.black
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .hueRotation(.degrees(animateBackground ? 30 : 0))
            .animation(
                Animation.easeInOut(duration: 10)
                    .repeatForever(autoreverses: true),
                value: animateBackground
            )
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                self.animateBackground = true
            }
            
            VStack(spacing: 30) {
                // LED Messenger logo at top
                Image("ledmlogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .padding(.top, 50)
                
                Spacer()
                
                // Title
                Text("CHOOSE MODE")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .tracking(1.5)
                    .padding(.bottom, 30)
                
                // Mode buttons
                VStack(spacing: 20) {
                    ForEach(AppMode.allCases) { mode in
                        ModeSelectButton(
                            mode: mode,
                            isSelected: selectedMode == mode,
                            action: {
                                withAnimation(.spring()) {
                                    self.selectedMode = mode
                                }
                            }
                        )
                        .scaleEffect(animateButtons ? 1.0 : 0.95)
                        .opacity(animateButtons ? 1.0 : 0)
                        .offset(y: animateButtons ? 0 : 20)
                        .animation(
                            .spring(response: 0.6, dampingFraction: 0.7).delay(mode == .solo ? 0.1 : 0.2),
                            value: animateButtons
                        )
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Mode explanation text
                VStack(alignment: .leading, spacing: 8) {
                    // Explanation based on selected mode
                    if selectedMode == .solo {
                        Text("Solo Mode")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Your iPad will have all the features of the Mac app, including setup and settings configuration. It will connect directly to Resolume.")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text("Paired Mode")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Your iPad will connect to a Mac running LED Messenger. The Mac will control settings and configuration while your iPad sends messages.")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
                .transition(.opacity)
                .id("explanation-\(selectedMode)")
                .animation(.easeInOut, value: selectedMode)
                
                // Continue button
                Button {
                    self.viewModel.setAppMode(self.selectedMode)
                } label: {
                    Text("CONTINUE")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 60)
                        .padding(.vertical, 16)
                        .background(Theme.primaryGradient)
                        .cornerRadius(25)
                        .shadow(color: Theme.accentPurple.opacity(0.5), radius: 8)
                }
                .padding(.bottom, 50)
                .opacity(animateButtons ? 1.0 : 0)
                .offset(y: animateButtons ? 0 : 20)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: animateButtons)
            }
        }
        .onAppear {
            // Set initial mode to current app mode
            self.selectedMode = self.viewModel.appMode
            
            // Animate buttons appearing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation {
                    self.animateButtons = true
                }
            }
        }
    }
}

/**
 * Main content view that coordinates all top-level views
 * Manages app state transitions and the splash screen
 */
struct ContentView: View {
    /// Main application view model that controls global state
    @EnvironmentObject var appViewModel: AppViewModel
    /// Controls whether the new message sheet is displayed
    @State private var isNewMessageSheetPresented = false
    /// Controls whether the splash screen is showing
    @State private var showSplash = false // Disabled to show mode selector first
    /// Selected mode in mode selection
    @State private var selectedMode: AppMode = .paired
    
    var body: some View {
        ZStack {
            // App-wide gradient background
            Theme.backgroundGradient
                .edgesIgnoringSafeArea(.all)
            
            // iOS-specific mode selection with debug print
            #if os(iOS)
            let _ = print("DEBUG: ContentView rendering, shouldShowModeSelection=\(appViewModel.shouldShowModeSelection), appState=\(appViewModel.appState)")
            
            if appViewModel.shouldShowModeSelection {
                // Mode selection screen for iOS
                ModeSelectionView(viewModel: appViewModel)
                    .transition(.opacity)
                    .id("ModeSelectionView-\(UUID())") // Force view to recreate when state changes
                    .onChange(of: appViewModel.shouldShowModeSelection) { _, newValue in
                        print("DEBUG: ModeSelectionView detected shouldShowModeSelection changed to \(newValue)")
                    }
            } else {
                // Main app content if not showing mode selection
                mainContent
                    .id("MainContent-\(appViewModel.appState)") // Force view to recreate when app state changes
                    .onAppear {
                        print("DEBUG: MainContent appeared with appState=\(appViewModel.appState)")
                    }
            }
            #else
            // Mac always shows main content
            mainContent
            #endif
            
            // No splash screen - we want mode selection to appear first
        }
        // Modal sheet for new message creation/editing
        .sheet(isPresented: $isNewMessageSheetPresented, onDismiss: {
            // Reset message view model state when sheet is dismissed
            appViewModel.messageViewModel.editingMessageId = nil
            appViewModel.messageViewModel.newMessageText = ""
            appViewModel.messageViewModel.newMessageIdentifier = ""
            appViewModel.messageViewModel.showingNewMessageSheet = false
        }) {
            // New message editor view
            NewMessageView(viewModel: appViewModel.messageViewModel)
                .onAppear {
                    // Sync sheet state with view model
                    appViewModel.messageViewModel.showingNewMessageSheet = true
                    
                    // Check if we're editing an existing message
                    if appViewModel.messageViewModel.editingMessageId != nil {
                        // Note: Message data is loaded in MessageQueueView before presenting this sheet
                        print("Opening editor for existing message")
                    }
                }
                .onDisappear {
                    // Update view model when sheet is dismissed
                    appViewModel.messageViewModel.showingNewMessageSheet = false
                }
                .background(Theme.backgroundGradient)
            
            // Platform-specific sheet presentation enhancements
            #if os(macOS)
            .keyboardShortcut(.escape, modifiers: []) // Allow ESC to dismiss sheet on macOS
            #endif
        }
        // Register for edit message notifications
        .onAppear {
            NotificationCenter.default.addObserver(
                forName: .editMessageRequested,
                object: nil,
                queue: .main
            ) { _ in
                // When a message edit is requested, show the edit sheet
                isNewMessageSheetPresented = true
            }
        }
        // Cleanup notification observer when view is removed
        .onDisappear {
            NotificationCenter.default.removeObserver(self, name: .editMessageRequested, object: nil)
        }
    }
    
    /// Main content view based on app state
    private var mainContent: some View {
        Group {
            switch appViewModel.appState {
            case .setup:
                // Initial configuration view
                SetupView(viewModel: appViewModel)
                    .transition(.opacity)
                    // No overlay badges here
            
            case .messageManagement:
                // Main message queue management view
                MessageManagementView(viewModel: appViewModel, isNewMessageSheetPresented: $isNewMessageSheetPresented)
                    .transition(.opacity)
                    // No overlay badges here
            
            case .customization:
                // Settings and customization view
                CustomizationView(viewModel: appViewModel)
                    .transition(.opacity)
                    // No overlay badges here
            }
        }
        .animation(.easeInOut, value: appViewModel.appState)
    }
}

/**
 * Main message management view showing the queue and controls
 * This is the primary interface users interact with
 */
struct MessageManagementView: View {
    /// Reference to the main app view model
    @ObservedObject var viewModel: AppViewModel
    /// Binding to control new message sheet presentation
    @Binding var isNewMessageSheetPresented: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // App header with title, logo, and controls
            HeaderView(viewModel: viewModel, isNewMessageSheetPresented: $isNewMessageSheetPresented)
            
            // Subtle divider for visual separation
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
                .padding(.horizontal, 0)
            
            // Instructions for user guidance
            instructionsBar
            
            // Another divider for visual hierarchy
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
                .padding(.horizontal, 0)
            
            // Main content area with message queue
            VStack(spacing: 15) {
                // Message queue showing all messages and their status
                MessageQueueView(viewModel: viewModel.messageViewModel)
                
                Spacer()
                
                // Logo footer
                Image("ck40")
                    .frame(width: 32, height: 40)
                    .padding(.bottom, 20)
            }
            .padding(.top, 15)
        }
        .background(Theme.backgroundGradient.ignoresSafeArea())
        .id("MessageManagementView") // Stable identifier for animations
    }
    
    /**
     * Instructions bar that provides user guidance
     * Shows a brief summary of the app's workflow
     */
    private var instructionsBar: some View {
        HStack {
            Text("INSTRUCTIONS: Queue message → Send to LED wall")
                .font(.system(size: Theme.fontCaption, weight: .medium))
                .foregroundColor(Theme.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
            
            Spacer()
        }
        .background(Theme.cardBgDark)
    }
}

/**
 * Header view containing app logo, title, and main controls
 * Displays connection status and provides navigation controls
 */
struct HeaderView: View {
    /// Reference to the app view model
    @ObservedObject var viewModel: AppViewModel
    /// Binding to control new message sheet presentation
    @Binding var isNewMessageSheetPresented: Bool
    
    var body: some View {
        VStack(spacing: 5) {
            HStack(alignment: .center) {
                // App logo on the left
                Image("ledlogowide")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 280, maxHeight: 45)
                    .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                
                Spacer()
                
                // Right-aligned action buttons
                HStack(spacing: 8) {
                    // Setup button (macOS or iPad SOLO mode)
                    #if os(macOS)
                    Button(action: {
                        viewModel.navigateToSetup()
                    }) {
                        Text("Setup")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(Theme.secondaryGradient)
                            .cornerRadius(20)
                            .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
                    }
                    .consistentMacOSStyle()
                    #else
                    // Show setup button on iPad only in SOLO mode
                    if viewModel.appMode == .solo {
                        Button(action: {
                            viewModel.navigateToSetup()
                        }) {
                            Text("Setup")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(Theme.secondaryGradient)
                                .cornerRadius(20)
                                .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
                        }
                        .consistentMacOSStyle()
                    }
                    #endif
                    
                    // Clear all messages button
                    Button(action: {
                        viewModel.messageViewModel.clearAllMessages()
                    }) {
                        Text("Clear")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(Theme.secondaryGradient)
                            .cornerRadius(20)
                            .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
                    }
                    .consistentMacOSStyle()
                    
                    // New message button
                    Button {
                        isNewMessageSheetPresented = true
                    } label: {
                        Text("+")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Theme.primaryGradient)
                            .cornerRadius(18)
                            .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .contentShape(Rectangle())
                    #if os(macOS)
                    .keyboardShortcut("n", modifiers: [.command]) // ⌘N shortcut on macOS
                    #endif
                }
            }
            .padding(.top, 8)
            .padding(.horizontal, 10)
            
            // Decorative gradient divider
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Theme.accentPeach.opacity(0.3),
                            Theme.accentPurple.opacity(0.5),
                            Theme.accentBlue.opacity(0.3)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .padding(.horizontal, 10)
                .padding(.top, 15)
            
            // Status indicators
            HStack(spacing: 20) {
                // Peer device connection status - only show in paired mode on iOS
                #if os(iOS)
                if viewModel.appMode.enablesPeerConnectivity {
                    PeerStatusView(
                        isConnected: $viewModel.peerConnectionStatus,
                        syncAction: {
                            Task { @MainActor in
                                viewModel.syncMessageQueueWithPeers()
                            }
                        },
                        restartAction: {
                            Task {
                                viewModel.restartPeerConnectivity()
                            }
                        }
                    )
                }
                #else
                // Always show on macOS
                PeerStatusView(
                    isConnected: $viewModel.peerConnectionStatus,
                    syncAction: {
                        Task { @MainActor in
                            viewModel.syncMessageQueueWithPeers()
                        }
                    },
                    restartAction: {
                        Task {
                            viewModel.restartPeerConnectivity()
                        }
                    }
                )
                #endif
                
                // Resolume OSC connection status
                ConnectionStatusIndicator(
                    isConnected: viewModel.connectionStatus == .connected,
                    label: "RESOLUME CONNECTED",
                    color: viewModel.connectionStatus == .connected ? Theme.successGreen : Theme.dangerRed
                )
                .onTapGesture {
                    viewModel.toggleDebugInfo()
                }
                
                // Debug information (only shown when enabled)
                if viewModel.showDebugInfo {
                    DebugInfoView(viewModel: viewModel)
                }
                
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
    }
}

/**
 * Reusable connection status indicator with colored dot
 * Shows connection state with visual feedback
 */
struct ConnectionStatusIndicator: View {
    /// Whether the connection is active
    let isConnected: Bool
    /// Text label for the connection status
    let label: String
    /// Color to use when connected (red is used for disconnected)
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            // Status indicator dot
            Circle()
                .fill(isConnected ? color : Color.red)
                .frame(width: 10, height: 10)
            
            // Status text label
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isConnected ? color : Color.red)
        }
    }
}

/**
 * Debug information panel showing technical details
 * Only visible when debug mode is enabled
 */
struct DebugInfoView: View {
    /// Reference to the app view model for accessing settings
    @ObservedObject var viewModel: AppViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Debug header
            Text("DEBUG INFO:")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.orange)
            
            // OSC connection details
            Text("IP: \(viewModel.settingsManager.settings.osc.ipAddress) | Port: \(viewModel.settingsManager.settings.osc.port) | Layer: \(viewModel.settingsManager.settings.osc.layer)")
                .font(.system(size: 10))
                .foregroundColor(.orange)
            
            // Platform indicator
            #if os(iOS)
            Text("Device: iPad/iPhone")
                .font(.system(size: 10))
                .foregroundColor(.orange)
            #else
            Text("Device: Mac")
                .font(.system(size: 10))
                .foregroundColor(.orange)
            #endif
            
            // Force reconnection button
            Button("Force Reconnect") {
                viewModel.forceReconnect()
            }
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.orange)
            .padding(.vertical, 2)
            .consistentMacOSStyle()
        }
        .padding(5)
        .background(Color.black.opacity(0.5))
        .cornerRadius(4)
    }
}

/**
 * Preview provider for SwiftUI canvas
 * Creates a preview of the ContentView for design-time visualization
 */
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}