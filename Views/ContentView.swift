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

// Using direct file references for now - no import needed with proper structure

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
            let _ = print("DEBUG: ContentView rendering, shouldShowModeSelection=\(appViewModel.shouldShowModeSelection), appState=\(appViewModel.appState), mode=\(appViewModel.appMode.rawValue)")
            
            if appViewModel.shouldShowModeSelection {
                // Mode selection screen for iOS - rebuilt directly here to avoid import issues
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
                    .edgesIgnoringSafeArea(.all)
                    
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
                        
                        // Solo mode button
                        Button {
                            print("DEBUG: Selecting SOLO mode")
                            // Force disconnection first to ensure clean state
                            DispatchQueue.main.async {
                                appViewModel.shouldShowModeSelection = false
                                appViewModel.setAppMode(AppMode.solo)
                                print("DEBUG: SOLO mode set, mode is now \(appViewModel.appMode.rawValue), shouldShowModeSelection=\(appViewModel.shouldShowModeSelection)")
                            }
                        } label: {
                            VStack(spacing: 15) {
                                Image(systemName: "ipad")
                                    .font(.system(size: 36))
                                
                                Text("SOLO MODE")
                                    .font(.system(size: 20, weight: .bold))
                                    .tracking(1.2)
                                
                                Text("iPad connects directly to Resolume")
                                    .font(.system(size: 14))
                                    .opacity(0.9)
                            }
                            .foregroundColor(.white)
                            .frame(width: 280, height: 160)
                            .background(
                                Theme.primaryGradient
                            )
                            .cornerRadius(22)
                            .overlay(
                                RoundedRectangle(cornerRadius: 22)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(color: Theme.accentPurple.opacity(0.6), radius: 10, x: 0, y: 4)
                        }
                        .padding(.bottom, 30)
                        
                        // Paired mode button
                        Button {
                            print("DEBUG: Selecting PAIRED mode")
                            // Force update on main thread
                            DispatchQueue.main.async {
                                appViewModel.shouldShowModeSelection = false
                                appViewModel.setAppMode(AppMode.paired)
                                print("DEBUG: PAIRED mode set, mode is now \(appViewModel.appMode.rawValue), shouldShowModeSelection=\(appViewModel.shouldShowModeSelection)")
                            }
                        } label: {
                            VStack(spacing: 15) {
                                Image(systemName: "macbook.and.ipad")
                                    .font(.system(size: 36))
                                
                                Text("PAIRED MODE")
                                    .font(.system(size: 20, weight: .bold))
                                    .tracking(1.2)
                                
                                Text("iPad connects to a Mac")
                                    .font(.system(size: 14))
                                    .opacity(0.9)
                            }
                            .foregroundColor(.white)
                            .frame(width: 280, height: 160)
                            .background(
                                Theme.secondaryGradient
                            )
                            .cornerRadius(22)
                            .overlay(
                                RoundedRectangle(cornerRadius: 22)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(color: Theme.accentPink.opacity(0.6), radius: 10, x: 0, y: 4)
                        }
                        
                        Spacer()
                        
                        // Mode explanation text
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Choose how to use your iPad:")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("• Solo Mode: Your iPad connects directly to Resolume with full functionality")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.bottom, 4)
                            
                            Text("• Paired Mode: Your iPad connects to a Mac running LED Messenger")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, 40)
                        .padding(.bottom, 50)
                    }
                }
                .transition(AnyTransition.opacity)
            } else if appViewModel.appMode == .solo {
                // Use a custom solo view when in solo mode
                // We implement a simple wrapper directly here to avoid module imports
                VStack {
                    if appViewModel.appState == .setup {
                        SetupView(viewModel: appViewModel)
                    } else if appViewModel.appState == .messageManagement {
                        MessageManagementView(viewModel: appViewModel, isNewMessageSheetPresented: $isNewMessageSheetPresented)
                    } else {
                        CustomizationView(viewModel: appViewModel)
                    }
                }
                .id("iPadSolo-\(appViewModel.appState)-\(UUID())") // Force view to recreate when app state changes
                .onAppear {
                    print("DEBUG: iPadSoloContentView appeared with appState=\(appViewModel.appState)")
                }
            } else {
                // Paired mode uses the standard content view
                mainContent
                    .id("MainContent-\(appViewModel.appState)-\(UUID())") // Force view to recreate when app state changes
                    .onAppear {
                        print("DEBUG: MainContent appeared with appState=\(appViewModel.appState), mode=\(appViewModel.appMode.rawValue)")
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
    
    /// Main content view based on app state (reimplemented inline for now)
    private var mainContent: some View {
        Group {
            switch appViewModel.appState {
            case .setup:
                // Initial configuration view
                SetupView(viewModel: appViewModel)
                    .transition(.opacity)
            
            case .messageManagement:
                // Main message queue management view
                MessageManagementView(viewModel: appViewModel, isNewMessageSheetPresented: $isNewMessageSheetPresented)
                    .transition(.opacity)
            
            case .customization:
                // Settings and customization view
                CustomizationView(viewModel: appViewModel)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: appViewModel.appState)
    }
    
    // We now directly implement the iPad solo view in the body
    // The extracted view in Views/iPad/iPadSoloContentView.swift can be used 
    // in a future implementation if needed
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
            // App header with title, logo, and controls (with instructions view for solo mode)
            HeaderView(
                viewModel: viewModel, 
                isNewMessageSheetPresented: $isNewMessageSheetPresented,
                instructionsView: AnyView(self.instructionsBar)
            )
            
            #if os(iOS)
            // For PAIRED mode on iPad, we need instructions here
            // Solo mode already has instructions in the header
            if viewModel.appMode != .solo {
                // Just add 10px space after header, then instructions
                Spacer()
                    .frame(height: 10)
                
                // Instructions bar only - no divider lines (for paired mode)
                instructionsBar
            }
            #else
            // macOS layout - keeping the original design for consistency
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
            #endif
            
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
    /// Instructions view to display in solo mode (default to EmptyView)
    var instructionsView: AnyView = AnyView(EmptyView())
    
    var body: some View {
        VStack(spacing: 5) {
            HStack(alignment: .center) {
                // App logo with conditional SOLO badge for iPad
                HStack(spacing: 10) {
                    // Main app logo
                    Image("ledlogowide")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 280, maxHeight: 45)
                        .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                    
                    // SOLO mode badge for iPad in solo mode
                    #if os(iOS)
                    if viewModel.appMode == .solo {
                        Text("SOLO")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Theme.primaryGradient)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(color: Theme.accentPurple.opacity(0.6), radius: 3, x: 0, y: 2)
                    }
                    #endif
                }
                
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
            
            // No decorative gradient divider - removed as requested
            // Small space instead
            Spacer()
                .frame(height: 10)
            
            // Instructions added directly in place of previous line - SOLO mode
            #if os(iOS)
            if viewModel.appMode == .solo {
                // For SOLO mode on iPad, show instructions row here
                self.instructionsView
            } else {
                // Only show status indicators in paired mode on iOS
                HStack(spacing: 20) {
                    // Peer device connection status
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
                    
                    // Resolume connection status
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
            #else
            // macOS always shows status indicators
            HStack(spacing: 20) {
                // Peer connectivity status
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
                
                // Resolume connection status
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
            #endif
        }
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