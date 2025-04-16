# LEDMESSENGER - Xcode Project Setup Guide

This document provides step-by-step instructions for setting up the LEDMESSENGER project in Xcode, including all necessary configurations, build settings, dependencies, and requirements to ensure proper functionality across iOS and macOS platforms.

## Table of Contents

1. [Project Requirements](#project-requirements)
2. [Creating the Project](#creating-the-project)
3. [Setting Up the Project Structure](#setting-up-the-project-structure)
4. [Configuring Build Settings](#configuring-build-settings)
5. [Setting Up Info.plist Configuration](#setting-up-infoplist-configuration)
6. [Configuring Entitlements](#configuring-entitlements)
7. [Adding App Icons and Assets](#adding-app-icons-and-assets)
8. [Setting Up Code Signing](#setting-up-code-signing)
9. [Configuring Network Security](#configuring-network-security)
10. [Building and Running](#building-and-running)
11. [Troubleshooting](#troubleshooting)

## Project Requirements

- **Xcode Version**: 14.0 or higher (15.0+ recommended)
- **Swift Version**: 5.5 or higher
- **Deployment Targets**:
  - iOS: 16.0 or higher
  - macOS: 13.0 or higher
- **Frameworks**: SwiftUI, Combine, Network, OSLog

## Creating the Project

1. **Launch Xcode** and select "Create a new Xcode project"
2. **Choose template**:
   - Select "App" under the "Multiplatform" section
   - Click "Next"
3. **Configure project options**:
   - Product Name: `LEDMESSENGER`
   - Team: Select your Apple Developer team (or create a personal team)
   - Organization Identifier: `com.yourcompany` (replace with your identifier)
   - Bundle Identifier: Will be auto-filled based on above fields
   - Interface: `SwiftUI`
   - Language: `Swift`
   - **Check** "Include Tests"
   - **Ensure** "Use Core Data" is unchecked
   - Click "Next"
4. **Choose save location**:
   - Select a location to save your project
   - **Uncheck** "Create Git repository" if you want to manage Git separately
   - Click "Create"

## Setting Up the Project Structure

Create the following folder structure within your project:

1. **Right-click** on the LEDMESSENGER group in the Project Navigator
2. Select **New Group** and create the following groups:
   - App
   - Models
   - Services
   - Utilities
   - ViewModels
   - Views
   - Extensions
   - Shared
   - Documentation

Expand the Views group and create these subgroups:
- Components
- Messages
- Setup
- Customization

Within the Models group, create a subgroup:
- OSC

Within the Services group, create a subgroup:
- OSC

Within the Utilities group, create a subgroup:
- Settings

## Configuring Build Settings

### 1. Project Settings

1. **Select the project** in the Project Navigator
2. Select the **LEDMESSENGER target**
3. Go to the **General** tab

### 2. Identity Configuration

Configure the following identity settings:
- Display Name: `LED MESSENGER`
- Version: `1.0`
- Build: `1`

### 3. Deployment Info

Configure the following deployment settings:
- iOS Deployment Target: `16.0` or higher
- macOS Deployment Target: `13.0` or higher

### 4. Supported Interface Orientations

For **iOS target**:
- Portrait: **Checked**
- Upside Down: **Checked**
- Landscape Left: **Checked**
- Landscape Right: **Checked**

### 5. Build Settings Tab

Select the **Build Settings** tab and configure:

1. **Swift Compiler - Language**:
   - Swift Language Version: `Swift 5`

2. **Packaging**:
   - Product Name: `LEDMESSENGER`

3. **Apple Clang - Warnings - All languages**:
   - Enable most warning settings to help identify potential issues

### 6. Capability Configuration

Select the **Signing & Capabilities** tab and add:

1. **App Sandbox** (for macOS):
   - Enable the following:
     - Outgoing Connections (Client): **Checked**
     - Incoming Connections (Server): **Checked**

2. **Network** capability (for iOS):
   - Click "+" and add "Network"

## Setting Up Info.plist Configuration

### 1. Common Info.plist Settings

Open the Info.plist file for each platform and add/edit:

1. **Common settings**:
   ```xml
   <key>CFBundleDisplayName</key>
   <string>LED MESSENGER</string>
   <key>UIApplicationSceneManifest</key>
   <dict>
     <key>UIApplicationSupportsMultipleScenes</key>
     <true/>
   </dict>
   ```

### 2. iOS-Specific Info.plist Settings

Add the following entries to the iOS Info.plist:

1. **Local Network Usage Description**:
   ```xml
   <key>NSLocalNetworkUsageDescription</key>
   <string>LED MESSENGER needs to connect to Resolume on your local network to send messages to the LED wall.</string>
   ```

2. **Bonjour Services**:
   ```xml
   <key>NSBonjourServices</key>
   <array>
     <string>_osc._udp</string>
   </array>
   ```

3. **User Interface Style**:
   ```xml
   <key>UIUserInterfaceStyle</key>
   <string>Dark</string>
   ```

4. **Status Bar Style**:
   ```xml
   <key>UIStatusBarStyle</key>
   <string>UIStatusBarStyleLightContent</string>
   <key>UIViewControllerBasedStatusBarAppearance</key>
   <false/>
   ```

## Configuring Entitlements

### 1. macOS Entitlements

For the macOS app entitlements file:

1. **Ensure** the following entitlements are configured:
   ```xml
   <key>com.apple.security.app-sandbox</key>
   <true/>
   <key>com.apple.security.network.client</key>
   <true/>
   <key>com.apple.security.network.server</key>
   <true/>
   ```

### 2. iOS Entitlements

For the iOS app entitlements file:

1. **Ensure** the following entitlements are configured:
   ```xml
   <key>com.apple.developer.networking.wifi-info</key>
   <true/>
   ```

## Adding App Icons and Assets

### 1. Opening Asset Catalog

1. Open **Assets.xcassets** in the Project Navigator

### 2. Adding App Icons

1. **For iOS**:
   - Select AppIcon in the asset catalog
   - Drag and drop icon files for all required sizes into appropriate slots
   - Required sizes: 20pt, 29pt, 40pt, 60pt at 2x and 3x resolutions

2. **For macOS**:
   - Select AppIcon in the macOS asset catalog
   - Drag and drop icon files for all required sizes into appropriate slots
   - Required sizes: 16pt, 32pt, 64pt, 128pt, 256pt, 512pt, 1024pt at 1x and 2x resolutions

### 3. Adding Custom Colors

1. **Right-click** in the asset catalog and select **New Color Set**
2. Name it `AccentPurple`
3. Set the color value to `#B667F1`
4. Ensure Appearances is set to "Any, Dark"

## Setting Up Code Signing

### 1. Automatic Signing (Easiest)

1. Select the project in the Project Navigator
2. Select the LEDMESSENGER target
3. Go to the **Signing & Capabilities** tab
4. For each platform:
   - Set Team to your Apple Developer team
   - Check "Automatically manage signing"
   - Xcode will generate provisioning profiles automatically

### 2. Manual Signing (Advanced)

If you need specific provisioning profiles:

1. Uncheck "Automatically manage signing"
2. Select the Provisioning Profile from the dropdown
3. Ensure Bundle Identifier matches your provisioning profile

## Configuring Network Security

### Transport Security Settings

Add to Info.plist:

```xml
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsLocalNetworking</key>
  <true/>
</dict>
```

## Building and Running

### 1. Select Platform

In the Xcode toolbar:
1. Select either "LEDMESSENGER (iOS)" or "LEDMESSENGER (macOS)" from the scheme selector

### 2. Select Destination

1. For iOS:
   - Choose a connected iOS device OR
   - Choose an iOS simulator
2. For macOS:
   - Choose "My Mac"

### 3. Build and Run

Click the ▶️ button or press **Cmd + R** to build and run the app

### 4. Build for Testing

To run the tests:
1. Press **Cmd + U** or
2. Choose **Product > Test** from the menu

## Troubleshooting

### Common Build Issues

1. **Code Signing Error**:
   - Review team and provisioning profile settings
   - Ensure Apple Developer account is active

2. **Missing Frameworks**:
   - Ensure all frameworks are properly linked in Build Phases > Link Binary With Libraries

3. **Storyboard Compilation Error** (if you use any):
   - Check for broken connections or missing IBOutlets/IBActions

4. **Networking Not Working**:
   - Verify Info.plist has necessary network usage descriptions
   - Check Entitlements for network client/server settings
   - For iOS, check if Local Network permission is granted in device settings

5. **SwiftUI Preview Not Working**:
   - Try cleaning the build folder (Shift + Cmd + K)
   - Restart Xcode

### Network Debugging Tips

If OSC messages aren't reaching Resolume:

1. Verify Resolume is running and OSC input is enabled
2. Check Resolume OSC settings match the app settings
3. Confirm UDP port is open (2269 by default)
4. Use Network Link Conditioner to test under different network conditions
5. Try using a tool like Wireshark to monitor OSC traffic

## Final Setup Checks

Before running the app in a production environment, verify:

1. All build settings are correctly configured
2. App icons and assets are properly added
3. Network permissions are correctly set
4. Bundle identifier matches your provisioning profile
5. All required capabilities are added
6. Dark mode is properly supported
7. Both iOS and macOS targets build successfully

---

This setup guide should ensure your LEDMESSENGER project is properly configured in Xcode. For further assistance or troubleshooting, please refer to the project documentation or contact the development team.