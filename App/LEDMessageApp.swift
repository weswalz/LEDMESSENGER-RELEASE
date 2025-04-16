//
//  LEDMessageApp.swift
//  LEDMESSENGER
//
//  Created by clubkit.io on 4/12/2025.
//

/**
 * Main entry point for the LED Messenger application.
 * This file defines the app structure and platform-specific delegates, handling
 * application lifecycle and window configuration.
 */

import SwiftUI

// Platform-specific imports
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/**
 * Platform-specific application delegate implementation
 */
#if os(iOS)
/**
 * iOS Application Delegate
 * Handles iOS-specific application lifecycle events
 */
class LEDMessageAppDelegate: NSObject, UIApplicationDelegate {
    /**
     * Called when the application finishes launching
     * Performs iOS-specific initialization tasks
     */
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        print("iOS App launched")
        return true
    }
}
#elseif os(macOS)
/**
 * macOS Application Delegate
 * Handles macOS-specific application lifecycle events
 */
class LEDMessageAppDelegate: NSObject, NSApplicationDelegate {
    /**
     * Called when the application finishes launching
     * Performs macOS-specific initialization tasks including setting the app appearance
     */
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("macOS App launched")
        
        // Force dark appearance regardless of system settings
        NSApp.appearance = NSAppearance(named: .darkAqua)
    }
}
#endif

/**
 * Main app structure using SwiftUI App protocol
 * Defines the app's UI hierarchy and scene configuration
 */
@main
struct LEDMessageApp: App {
    // Platform-specific application delegate
    #if os(iOS)
    @UIApplicationDelegateAdaptor(LEDMessageAppDelegate.self) var appDelegate
    #elseif os(macOS)
    @NSApplicationDelegateAdaptor(LEDMessageAppDelegate.self) var appDelegate
    #endif
    
    /// App view model for global state management
    @StateObject private var viewModel = AppViewModel()
    
    /**
     * Defines the app's scene configuration and content view hierarchy
     * Returns the main scene containing the application's ContentView
     */
    var body: some Scene {
        WindowGroup {
            #if os(iOS)
            // For iPad, inject the view model properly
            ContentView()
                .environmentObject(viewModel)
                .onAppear {
                    print("DEBUG: ContentView appeared")
                    
                    // CRITICAL: Force mode selection to appear
                    viewModel.shouldShowModeSelection = true
                    
                    // Clear all mode-related UserDefaults keys
                    UserDefaults.standard.removeObject(forKey: "com.ledmessenger.completedModeSetup")
                    UserDefaults.standard.removeObject(forKey: "com.ledmessenger.hasLaunchedBefore")
                    
                    // Ensure settings are reset to show mode selection
                    viewModel.settingsManager.updateModeSettings(showModeSelectionOnStartup: true)
                    
                    // Add multiple delayed checks to ensure mode selection appears
                    [0.1, 0.3, 0.5, 1.0].forEach { delay in
                        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                            viewModel.shouldShowModeSelection = true
                            print("DEBUG: Mode selection force-enabled at \(delay)s")
                        }
                    }
                }
                .preferredColorScheme(.dark)
            #else
            // Mac version always goes directly to ContentView
            ContentView()
                .environmentObject(viewModel)
                .preferredColorScheme(.dark)
                // Set window size constraints
                .frame(minWidth: 800, idealWidth: 1024, maxWidth: .infinity, 
                       minHeight: 700, idealHeight: 850, maxHeight: .infinity)
                // Configure macOS window appearance when the view appears
                .onAppear {
                    // Short delay to ensure window is fully initialized
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if let window = NSApp.windows.first {
                            // Set iPad-like dimensions for consistent cross-platform experience
                            window.setContentSize(NSSize(width: 1024, height: 850))
                            window.center() // Center on screen
                            window.title = "LED MESSENGER" // Set window title
                            
                            // Apply iOS-like styling to window for visual consistency
                            window.backgroundColor = NSColor.black
                            window.titlebarAppearsTransparent = true
                            window.styleMask.insert(.fullSizeContentView)
                            
                            // Minimize window chrome to match iOS aesthetic
                            window.titleVisibility = .hidden
                            
                            // Configure which window controls remain visible
                            window.standardWindowButton(.closeButton)?.isHidden = false
                            window.standardWindowButton(.miniaturizeButton)?.isHidden = false
                            window.standardWindowButton(.zoomButton)?.isHidden = false
                            
                            // Eliminate extra space around content views
                            if let contentView = window.contentView {
                                contentView.wantsLayer = true
                                contentView.layer?.backgroundColor = NSColor.black.cgColor
                            }
                            
                            // Remove toolbar for cleaner appearance
                            window.toolbar = nil
                            
                            // Force dark mode to match iOS appearance
                            window.appearance = NSAppearance(named: .darkAqua)
                        }
                    }
                }
                #endif
        }
    }
}