# LED MESSENGER

**Professional LED Wall Messaging Control System for Live Events**

LED Messenger is a robust SwiftUI application designed for controlling LED wall displays in live event environments through Resolume Arena. It enables event operators to create, queue, and display text messages on LED screens using the Open Sound Control (OSC) protocol.

![LED Messenger App](https://ledmessenger.com/app-preview.png)

## Key Features

- **Multi-Device Operation**: Seamless synchronization between iPad and macOS with real-time updates
- **Message Management**: Create, queue, edit, and send messages with customizable identifiers
- **5-Slot Text Rotation**: Intelligent system for managing multiple text clips in Resolume
- **Peer-to-Peer Connectivity**: Automatic discovery and connection between devices
- **Customizable Text Formatting**: Control line breaks and character limits
- **Message Templates**: Save and reuse common messages for quick access
- **Auto-Cycling**: Automatically rotate through queued messages at timed intervals
- **Connection Monitoring**: Real-time status tracking with automatic reconnection
- **iPad & macOS Support**: Fully optimized for tablets and desktop computers

## Setup Guide

### Resolume Configuration

1. **Enable OSC Input**: In Resolume, go to Preferences > OSC > OSC Input Port and set port to 2269
2. **Prepare Text Clips**: Create text clips in positions 1-5 on your preferred layer
3. **Create Empty Clip**: Add an empty clip at position 6 (or 5 slots after your starting position)

### Application Setup

1. Enter your Resolume computer's IP address
2. Specify the layer number for your text clips (default: 5)
3. Set the starting clip position (default: 1)
4. Confirm the clear clip position (default: starting position + 5)
5. Run the test pattern to verify connectivity

## Architecture

LED Messenger is built with a modern MVVM architecture using 100% SwiftUI with:

- **Pure SwiftUI Implementation**: No UIKit or AppKit dependencies
- **Native OSC Protocol**: Custom implementation using Network framework
- **Cross-Platform Design**: Unified codebase for iPad and macOS
- **Peer-to-Peer Connectivity**: Built on MultipeerConnectivity framework

## System Requirements

- **iOS/iPadOS**: Version 16.0 or higher (iPad recommended)
- **macOS**: Version 13.0 or higher
- **Resolume Arena**: Version 7.0 or higher
- **Network**: Devices must be on the same local network

## Recent Updates

- Added T-slot visualization for 5-clip rotation system
- Improved peer connectivity with exponential backoff for reconnection
- Implemented message tracking to prevent duplicate sends during reconnection
- Enhanced UI with clear status indicators for connection state
- Added manual reconnect option for peer connectivity

## Troubleshooting

If you encounter connection issues:

1. **Verify network settings**: Ensure all devices are on the same network
2. **Check Resolume OSC settings**: Confirm OSC Input Port is set to 2269
3. **Verify IP address**: Make sure you've entered the correct Resolume computer IP
4. **Firewall settings**: Check that OSC port is not blocked by firewall
5. **Manual reconnect**: Use the reconnect button if peer connection drops

## Support

For questions, feedback, or support requests, please contact:
hello@ledmessenger.com

---

© 2025 LED Messenger. All rights reserved.