# CLAUDELED: Modern Swift Native Roadmap

## Architecture Overview

CLAUDELED implements a 100% SwiftUI native application for controlling LED wall displays through Resolume Arena via OSC. The application follows a clean architecture approach with MVVM pattern and Swift Concurrency for async operations.

```
┌─────────────────────────────────────────────────┐
│                      UI Layer                    │
│ ┌─────────────┐  ┌─────────────┐  ┌───────────┐ │
│ │ Setup Views │  │Message Views│  │  Status   │ │
│ └─────────────┘  └─────────────┘  └───────────┘ │
└───────────────────────┬─────────────────────────┘
                        │
┌───────────────────────▼─────────────────────────┐
│                  Domain Layer                    │
│ ┌─────────────┐  ┌─────────────┐  ┌───────────┐ │
│ │MessageViewModel│MessageManager│  │ Settings  │ │
│ └─────────────┘  └─────────────┘  └───────────┘ │
└───────────────────────┬─────────────────────────┘
                        │
┌───────────────────────▼─────────────────────────┐
│                  Service Layer                   │
│ ┌─────────────┐  ┌─────────────┐  ┌───────────┐ │
│ │ OSCService  │  │   Network    │  │  Storage  │ │
│ └─────────────┘  └─────────────┘  └───────────┘ │
└───────────────────────┬─────────────────────────┘
                        │
                        ▼
                  External Systems
                 (Resolume Arena)
```

## Phase 1: Foundation (Week 1)

### Core Architecture & OSC Implementation

1. **Create Project Structure**
   - Set up cross-platform SwiftUI project (iOS/macOS)
   - Implement shared code architecture
   - Configure deployment targets

2. **OSC Service Implementation**
   - Implement OSCPacket protocol and related models
   - Create OSCService using Network framework's NWConnection
   - Implement OSC message serialization/deserialization
   - Add connection state monitoring with heartbeats

3. **Message Models**
   - Create Message domain model with all necessary properties
   - Implement MessageStatus enum with state transitions
   - Set up message formatters for different display modes

4. **Settings Management**
   - Create SettingsManager for persisting configurations
   - Implement settings models for OSC, formatting, and UI preferences
   - Add cross-platform settings adapter

### Networking & Communication

1. **UDP Communication**
   - Implement NWConnection-based UDP socket management
   - Create connection monitoring and auto-reconnection
   - Set up error handling and timeout management

2. **IP Address Management**
   - Implement detection of local network interfaces
   - Create validation for IP address and port configurations
   - Set up reachability testing for target endpoints

## Phase 2: Core Features (Week 2)

### Message Management System

1. **Message View Model**
   - Create reactive MessageViewModel with Combine publishers
   - Implement message state management
   - Add filtering and sorting capabilities

2. **Message Queue**
   - Implement in-memory queue with persistence
   - Create queue management operations
   - Add expiration logic and cleanup

3. **Text Formatting**
   - Implement text formatting strategies (two-word, character limit)
   - Create preview generator for formatted text
   - Add support for custom prefixes and labels

### UI Implementation

1. **Setup Views**
   - Create cross-platform setup workflow
   - Implement layer and slot configuration
   - Add connection status indicators and testing

2. **Message Creation & Management**
   - Implement New Message modal with validation
   - Create Message Queue view with live updates
   - Add message card components with action buttons

3. **Control Panel**
   - Create status display with connection indicators
   - Implement Clear Screen functionality
   - Add settings access controls

## Phase 3: Advanced Features (Week 3)

### Enhanced Functionality

1. **Multi-device Synchronization**
   - Implement MultipeerConnectivity session management
   - Create message synchronization protocol
   - Add conflict resolution for concurrent edits

2. **Message Templates**
   - Create template management system
   - Implement template selection in message creation
   - Add quick-access template triggers

3. **Message Scheduling**
   - Implement message timer and scheduling
   - Create visual countdown indicators
   - Add automatic message cycling

### Platform Adaptations

1. **iOS/iPadOS Optimizations**
   - Touch-optimized controls and layouts
   - Add haptic feedback
   - Implement gesture shortcuts

2. **macOS Enhancements**
   - Add keyboard shortcuts
   - Create macOS-specific window controls
   - Implement advanced editing capabilities

## Phase 4: Polish & Optimization (Week 4)

### Performance & Reliability

1. **Error Handling**
   - Implement comprehensive error handling
   - Create user-facing error messages
   - Add logging and diagnostics

2. **Testing**
   - Create unit tests for core components
   - Implement UI tests for key workflows
   - Add network simulation tests

3. **Performance Optimization**
   - Optimize rendering for message lists
   - Improve network efficiency
   - Reduce memory usage

### Final Integration

1. **Resolume Integration Testing**
   - Test with actual Resolume Arena installation
   - Verify OSC command compatibility
   - Create example Resolume composition

2. **Documentation**
   - Create in-app help system
   - Add comprehensive README and setup guide
   - Document OSC command structure

3. **Final Polish**
   - UI refinements and consistency
   - Accessibility improvements
   - Final cross-platform testing

## Technical Implementation Details

### OSC Protocol Implementation

The OSC implementation will use Apple's Network framework for UDP communication:

```swift
class OSCService {
    // Connection management
    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "com.claudeled.osc")
    
    // Auto-reconnect and status monitoring
    @Published var connectionState: ConnectionState = .disconnected
    private var heartbeatTimer: Timer?
    
    // Message sending with retry capabilities
    func sendMessage(_ message: OSCMessage, retries: Int = 3) async throws {
        // Implementation with error handling and retries
    }
}
```

### Message Pipeline

Messages will flow through a defined pipeline:

1. **Creation**: Input validation and normalization
2. **Formatting**: Apply wrapping and label rules
3. **Queueing**: Store in priority queue
4. **Dispatch**: Convert to OSC and send
5. **Monitoring**: Track delivery status and update UI

### Swift Concurrency

The app will leverage modern Swift concurrency for asynchronous operations:

```swift
// Sending a message
Task {
    do {
        try await messageService.sendMessage(message)
        await message.updateStatus(.sent)
        await MainActor.run {
            // Update UI
        }
    } catch {
        await handleError(error)
    }
}
```

### Data Persistence

User settings and message templates will be persisted using a combination of:

1. **UserDefaults**: For simple settings and preferences
2. **SwiftData**: For complex data and message templates
3. **FileManager**: For exportable configurations

## Milestones & Deliverables

1. **Week 1**: Core architecture and OSC implementation
   - Functioning OSC communication
   - Basic UI structure
   - Settings persistence

2. **Week 2**: Message management and main UI
   - Complete message creation workflow
   - Functioning queue management
   - Text formatting capabilities

3. **Week 3**: Advanced features and platform adaptations
   - Multi-device synchronization
   - Template system
   - Platform-specific optimizations

4. **Week 4**: Polish, optimization, and documentation
   - Complete error handling
   - Performance optimizations
   - Documentation and examples

## Conclusion

This roadmap outlines a comprehensive approach to building CLAUDELED as a 100% SwiftUI native application with robust OSC communication, advanced message management, and platform-specific optimizations for both iOS and macOS. The implementation will leverage modern Swift features including Swift Concurrency, Combine, and Network framework to create a reliable and performant solution for LED wall messaging in live event environments.