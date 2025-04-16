//
//  PeerService.swift
//  LEDMESSENGER
//
//  Created by Claude AI on 4/12/2025.
//

import Foundation
import MultipeerConnectivity
import Combine
import OSLog

#if os(macOS)
import Network
import SystemConfiguration
#endif

/// Protocol for peer service delegate
protocol PeerServiceDelegate: AnyObject {
    /// Called when a peer connection status changes
    func peerConnectionStatusChanged(_ connected: Bool)
    
    /// Called when a sync message is received
    func didReceiveSyncMessage(_ message: PeerSyncMessage)
}

/// Types of peer messages
enum PeerMessageType: String, Codable {
    case messageQueueSync
    case messageSent
    case messageCancelled
    case messageAdded
    case queueCleared
    case heartbeat
    case oscSettingsSync
}

/// Peer sync message structure
struct PeerSyncMessage: Codable {
    /// The type of message
    let type: PeerMessageType
    
    /// The timestamp of the message
    let timestamp: Date
    
    /// Optional message ID for individual message operations
    let messageId: UUID?
    
    /// Optional message data for message operations
    let message: MessageData?
    
    /// Optional full queue for sync operations
    let queue: [MessageData]?
    
    /// Optional OSC settings for syncing configuration
    let oscSettings: OSCSettingsData?
    
    /// Initialize a new sync message
    init(type: PeerMessageType, messageId: UUID? = nil, message: Message? = nil, queue: [Message]? = nil, oscSettings: OSCSettings? = nil) {
        self.type = type
        self.timestamp = Date()
        self.messageId = messageId
        
        // Convert Message to MessageData if provided
        self.message = message != nil ? MessageData(from: message!) : nil
        
        // Convert Message array to MessageData array if provided
        self.queue = queue?.map { MessageData(from: $0) }
        
        // Convert OSC settings to data structure if provided
        self.oscSettings = oscSettings != nil ? OSCSettingsData(from: oscSettings!) : nil
    }
}

/// Data structure for serializing OSC settings
struct OSCSettingsData: Codable {
    let ipAddress: String
    let port: Int
    let layer: Int
    let startingClip: Int
    let clearClip: Int
    
    /// Initialize from OSCSettings
    init(from settings: OSCSettings) {
        self.ipAddress = settings.ipAddress
        self.port = settings.port
        self.layer = settings.layer
        self.startingClip = settings.startingClip
        self.clearClip = settings.clearClip
    }
    
    /// Convert to OSCSettings
    func toOSCSettings() -> OSCSettings {
        return OSCSettings(
            ipAddress: ipAddress,
            port: port,
            layer: layer,
            startingClip: startingClip,
            clearClip: clearClip,
            autoConnect: true
        )
    }
}

/// Data structure for serializing Message objects
struct MessageData: Codable {
    let id: UUID
    let text: String
    let identifier: String
    let labelType: String
    let customLabel: String
    let status: String
    let createdAt: Date
    let expiresAt: Date?
    
    /// Initialize from a Message
    init(from message: Message) {
        self.id = message.id
        self.text = message.text
        self.identifier = message.identifier
        self.labelType = message.labelType.rawValue
        self.customLabel = message.customLabel
        self.status = message.status.rawValue
        self.createdAt = message.createdAt
        self.expiresAt = message.expiresAt
    }
    
    /// Convert to a Message
    func toMessage() -> Message {
        let message = Message(
            id: id,
            text: text,
            identifier: identifier,
            labelType: LabelType(rawValue: labelType) ?? .tableNumber,
            customLabel: customLabel,
            status: MessageStatus(rawValue: status) ?? .queued,
            createdAt: createdAt,
            expiresAt: expiresAt
        )
        return message
    }
}

/// Service for peer-to-peer communication
final class PeerService: NSObject {
    // MARK: - Properties
    
    /// The service type for peer discovery
    /// Important: This MUST match exactly on all devices
    /// Format requirements: 1-15 ASCII characters, must contain only lowercase
    /// letters, numbers, and hyphens
    private let serviceType = "ledmessenger-v1"
    
    /// The local peer ID
    private let localPeerId: MCPeerID
    
    /// The peer session
    private var session: MCSession
    
    /// The advertiser for the session
    private var advertiser: MCNearbyServiceAdvertiser
    
    /// The browser for the session
    private var browser: MCNearbyServiceBrowser
    
    /// Whether the service is currently advertising
    private var isAdvertising = false
    
    /// Whether the service is currently browsing
    private var isDiscovering = false
    
    /// Connected peers
    private var connectedPeers: [MCPeerID] {
        return session.connectedPeers
    }
    
    /// Whether the service is connected to any peers
    var isConnected: Bool {
        return !connectedPeers.isEmpty
    }
    
    /// Connection status publisher
    let connectionStatusPublisher = PassthroughSubject<Bool, Never>()
    
    /// The delegate for the service
    weak var delegate: PeerServiceDelegate?
    
    /// Logger for peer service
    private let logger = Logger(subsystem: "com.ledmessenger.peer", category: "connectivity")
    
    /// Heartbeat timer
    private var heartbeatTimer: Timer?
    
    /// Time since last discovery restart
    private var lastDiscoveryRestartTime = Date()
    
    /// Count of consecutive restart attempts
    private var consecutiveRestartAttempts = 0
    
    /// Maximum number of restart attempts before backing off
    private let maxConsecutiveRestarts = 3
    
    // MARK: - Initialization
    
    /// Initialize the peer service
    init(deviceName: String? = nil) {
        // Use provided device name or system name
        #if os(iOS)
        let name = deviceName ?? UIDevice.current.name
        #elseif os(macOS)
        let name = deviceName ?? Host.current().localizedName ?? "Mac Device"
        #endif
        
        // Initialize peer ID with the device name
        self.localPeerId = MCPeerID(displayName: name)
        
        // Initialize session with the peer ID
        self.session = MCSession(
            peer: localPeerId,
            securityIdentity: nil,
            encryptionPreference: .required
        )
        
        // Initialize advertiser and browser
        self.advertiser = MCNearbyServiceAdvertiser(
            peer: localPeerId,
            discoveryInfo: nil,
            serviceType: serviceType
        )
        
        self.browser = MCNearbyServiceBrowser(
            peer: localPeerId,
            serviceType: serviceType
        )
        
        super.init()
        
        // Set delegates
        session.delegate = self
        advertiser.delegate = self
        browser.delegate = self
        
        // Start heartbeat timer
        startHeartbeatTimer()
    }
    
    // MARK: - Service Control
    
    /// Start the peer service
    func start() {
        startAdvertising()
        startDiscovering()
        
        // Print detailed network info for troubleshooting
        printNetworkInfo()
        
        logger.info("Peer service started - Using service type: \(self.serviceType)")
    }
    
    /// Stop the peer service
    func stop() {
        stopAdvertising()
        stopDiscovering()
        session.disconnect()
        logger.info("Peer service stopped")
    }
    
    /// Print detailed network info for troubleshooting
    private func printNetworkInfo() {
        #if os(macOS)
        // Get hostname
        let hostname = Host.current().name ?? "ureadnknown"
        let localizedName = Host.current().localizedName ?? "unknown"
        
        print("🔄📱 PEER DEBUGGING INFO:")
        print("🔄📱 macOS Device: \(localizedName) (hostname: \(hostname))")
        print("🔄📱 Peer ID: \(self.localPeerId.displayName)")
        print("🔄📱 Service Type: \(self.serviceType)")
        
        // List IP addresses
        let addresses = Host.current().addresses
        if addresses.isEmpty {
            print("🔄📱 No IP addresses found")
        } else {
            print("🔄📱 IP Addresses:")
            for address in addresses {
                print("🔄📱   - \(address)")
            }
        }
        #else
        // iOS device info
        let device = UIDevice.current
        
        print("🔄📱 PEER DEBUGGING INFO:")
        print("🔄📱 iOS Device: \(device.name) (\(device.model))")
        print("🔄📱 iOS Version: \(device.systemVersion)")
        print("🔄📱 Peer ID: \(self.localPeerId.displayName)")
        print("🔄📱 Service Type: \(self.serviceType)")
        #endif
    }
    
    /// Start advertising the service
    private func startAdvertising() {
        guard !isAdvertising else { return }
        
        advertiser.startAdvertisingPeer()
        isAdvertising = true
        logger.debug("Started advertising")
    }
    
    /// Stop advertising the service
    private func stopAdvertising() {
        guard isAdvertising else { return }
        
        advertiser.stopAdvertisingPeer()
        isAdvertising = false
        logger.debug("Stopped advertising")
    }
    
    /// Start discovering other peers
    private func startDiscovering() {
        guard !isDiscovering else { return }
        
        browser.startBrowsingForPeers()
        isDiscovering = true
        logger.debug("Started discovering")
    }
    
    /// Stop discovering other peers
    private func stopDiscovering() {
        guard isDiscovering else { return }
        
        browser.stopBrowsingForPeers()
        isDiscovering = false
        logger.debug("Stopped discovering")
    }
    
    // MARK: - Message Sending
    
    /// Send a message to all connected peers
    func sendToPeers(_ message: PeerSyncMessage) {
        guard !self.connectedPeers.isEmpty else {
            logger.warning("No peers connected to send message: \(message.type.rawValue)")
            return
        }
        
        do {
            // Encode the message
            let data = try JSONEncoder().encode(message)
            
            // Log more detail about what we're sending
            if message.type == .messageQueueSync {
                print("📱 Sending queue with \(message.queue?.count ?? 0) messages to \(self.connectedPeers.count) peers")
            } else if message.type == .messageAdded {
                print("📱 Sending new message to \(self.connectedPeers.count) peers: \(message.message?.text ?? "")")
            }
            
            // Send to all connected peers
            try session.send(data, toPeers: self.connectedPeers, with: .reliable)
            
            logger.debug("Sent message type \(message.type.rawValue) to \(self.connectedPeers.count) peers")
        } catch {
            logger.error("Failed to send message: \(error.localizedDescription)")
        }
    }
    
    /// Sync the entire message queue
    func syncQueue(_ messages: [Message]) {
        let syncMessage = PeerSyncMessage(
            type: .messageQueueSync,
            queue: messages
        )
        
        sendToPeers(syncMessage)
    }
    
    /// Notify peers that a message was sent
    func notifyMessageSent(_ message: Message) {
        let syncMessage = PeerSyncMessage(
            type: .messageSent,
            messageId: message.id,
            message: message
        )
        
        sendToPeers(syncMessage)
    }
    
    /// Notify peers that a message was cancelled
    func notifyMessageCancelled(_ messageId: UUID) {
        let syncMessage = PeerSyncMessage(
            type: .messageCancelled,
            messageId: messageId
        )
        
        sendToPeers(syncMessage)
    }
    
    /// Notify peers that a message was added
    func notifyMessageAdded(_ message: Message) {
        let syncMessage = PeerSyncMessage(
            type: .messageAdded,
            messageId: message.id,
            message: message
        )
        
        sendToPeers(syncMessage)
    }
    
    /// Notify peers that the queue was cleared
    func notifyQueueCleared() {
        let syncMessage = PeerSyncMessage(
            type: .queueCleared
        )
        
        sendToPeers(syncMessage)
    }
    
    /// Sync OSC settings to peers
    func syncOSCSettings(_ settings: OSCSettings) {
        let syncMessage = PeerSyncMessage(
            type: .oscSettingsSync,
            oscSettings: settings
        )
        
        sendToPeers(syncMessage)
    }
    
    // MARK: - Heartbeat and Connection Management
    
    /// Start the heartbeat timer
    private func startHeartbeatTimer() {
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // If connected, send heartbeat and reset restart counter
            if self.isConnected {
                let heartbeatMessage = PeerSyncMessage(type: .heartbeat)
                self.sendToPeers(heartbeatMessage)
                // Reset consecutive restart attempts when connected
                self.consecutiveRestartAttempts = 0
                return
            }
            
            // Check if enough time has passed since last restart
            let timeSinceLastRestart = Date().timeIntervalSince(self.lastDiscoveryRestartTime)
            
            // Calculate backoff time based on consecutive failures (exponential backoff)
            let backoffTime = min(60.0, pow(2.0, Double(self.consecutiveRestartAttempts)))
            
            // Only restart if enough time has passed based on backoff
            if timeSinceLastRestart > backoffTime {
                print("🔄📱 No peers connected - restarting discovery (attempt \(self.consecutiveRestartAttempts + 1))")
                self.restartDiscovery()
            }
        }
    }
    
    /// Restart peer discovery to find new peers
    private func restartDiscovery() {
        // Update tracking variables
        lastDiscoveryRestartTime = Date()
        consecutiveRestartAttempts += 1
        
        // If we've tried too many times, log but don't restart
        if consecutiveRestartAttempts > maxConsecutiveRestarts {
            print("🔄📱 Too many restart attempts (\(consecutiveRestartAttempts)). Allowing longer backoff period.")
            // Don't return - we'll still try, but with longer backoff times
        }
        
        // Stop and restart advertising and browsing
        stopAdvertising()
        stopDiscovering()
        
        // Brief pause to let the framework reset
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            
            print("🔄📱 Restarting peer discovery... (backoff time: \(min(60.0, pow(2.0, Double(self.consecutiveRestartAttempts)))) seconds)")
            self.startAdvertising()
            self.startDiscovering()
        }
    }
    
    // MARK: - Deinitialization
    
    deinit {
        heartbeatTimer?.invalidate()
        stop()
    }
}

// MARK: - MCSessionDelegate

extension PeerService: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        // Capture values before the closure
        let localConnected = !session.connectedPeers.isEmpty
        let localPeerName = peerID.displayName
        let localStateRaw = state.rawValue
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            switch state {
            case .connected:
                // Print more detailed connection info
                print("📱📱 PEER CONNECTED: \(localPeerName) - Total peers: \(session.connectedPeers.count)")
                print("📱📱 Connected peers: \(session.connectedPeers.map { $0.displayName }.joined(separator: ", "))")
                
                self.logger.info("Peer connected: \(localPeerName)")
                self.connectionStatusPublisher.send(localConnected)
                self.delegate?.peerConnectionStatusChanged(localConnected)
                
            case .connecting:
                print("📱 Connecting to peer: \(localPeerName)...")
                self.logger.debug("Peer connecting: \(localPeerName)")
                
            case .notConnected:
                print("📱 Peer disconnected: \(localPeerName)")
                self.logger.info("Peer disconnected: \(localPeerName)")
                self.connectionStatusPublisher.send(localConnected)
                self.delegate?.peerConnectionStatusChanged(localConnected)
                
            @unknown default:
                self.logger.warning("Peer \(localPeerName) unknown state: \(localStateRaw)")
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        do {
            // Decode the message
            let message = try JSONDecoder().decode(PeerSyncMessage.self, from: data)
            
            // Skip heartbeat messages
            if message.type == .heartbeat {
                return
            }
            
            // Enhanced logging for debugging
            if message.type == .messageQueueSync {
                print("📲 Received queue with \(message.queue?.count ?? 0) messages from \(peerID.displayName)")
                
                // Print the message texts for debugging
                if let queue = message.queue, !queue.isEmpty {
                    print("📲 Messages in queue: \(queue.map { $0.text }.joined(separator: ", "))")
                }
            } else if message.type == .messageAdded {
                print("📲 Received new message from \(peerID.displayName): \(message.message?.text ?? "")")
            } else if message.type == .oscSettingsSync {
                print("📲 Received OSC settings from \(peerID.displayName)")
            } else {
                print("📲 Received \(message.type.rawValue) from \(peerID.displayName)")
            }
            
            // Log message receipt
            logger.debug("Received message type \(message.type.rawValue) from \(peerID.displayName)")
            
            // Forward message to delegate
            DispatchQueue.main.async {
                self.delegate?.didReceiveSyncMessage(message)
            }
        } catch {
            print("📲 ERROR decoding message from \(peerID.displayName): \(error.localizedDescription)")
            logger.error("Failed to decode message: \(error.localizedDescription)")
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // Not used
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        // Not used
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        // Not used
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension PeerService: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // Automatically accept all invitations
        logger.info("Received invitation from peer: \(peerID.displayName)")
        invitationHandler(true, session)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        logger.error("Failed to start advertising: \(error.localizedDescription)")
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension PeerService: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        // Automatically invite discovered peers
        logger.info("Found peer: \(peerID.displayName)")
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 30)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        logger.info("Lost peer: \(peerID.displayName)")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        logger.error("Failed to start browsing: \(error.localizedDescription)")
    }
}
