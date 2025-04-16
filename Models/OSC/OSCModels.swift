//
//  OSCModels.swift
//  LEDMESSENGER
//
//  Created by Claude AI on 4/12/2025.
//

/**
 * Open Sound Control (OSC) core models
 * 
 * This file defines all data structures for OSC protocol implementation,
 * providing both the general OSC specification compliance and
 * Resolume-specific extensions needed for LED wall communication.
 * 
 * OSC is a network protocol for real-time communication between computers,
 * synthesizers, and other multimedia devices.
 */

import Foundation

/**
 * NOTE: This file contains all OSC model definitions consolidated in one place.
 * The individual OSC files (OSCAddress.swift, OSCMessage.swift, etc.) 
 * are kept as empty reference files to avoid duplicate definition errors.
 */

// MARK: - OSCAddress

/**
 * Represents an OSC message address
 *
 * OSC addresses follow a URL-like hierarchical structure:
 * - Must start with a forward slash "/"
 * - Cannot contain spaces
 * - Represents the target controller or command
 */
struct OSCAddress: Hashable, Equatable {
    /**
     * The raw address string value, always starting with "/"
     * Used to identify the target controller in the OSC server
     */
    let value: String
    
    /**
     * Initialize an OSC address with validation
     *
     * @param value The address string (must start with / and have no spaces)
     * @return nil if the address doesn't follow OSC address pattern rules
     */
    init?(_ value: String) {
        // Validate OSC address format according to the OSC specification
        guard value.hasPrefix("/"),
              !value.contains(" ") else {
            return nil
        }
        self.value = value
    }
    
    /**
     * Create an address for Resolume text content on a specific layer and clip
     *
     * This factory method creates an OSC address targeting the text content
     * of a specific clip in Resolume Arena's composition.
     *
     * @param layer The Resolume layer number (1-indexed)
     * @param clip The Resolume clip number (1-indexed)
     * @return An OSCAddress for controlling text content, or nil if invalid
     */
    static func resolumeTextContent(layer: Int, clip: Int) -> OSCAddress? {
        // Use the full path as confirmed in Resolume Arena documentation
        // This targets the "lines" parameter of a text generator source
        OSCAddress("/composition/layers/\(layer)/clips/\(clip)/video/source/textgenerator/text/params/lines")
    }
    
    /**
     * Create an address for triggering (selecting) a Resolume clip
     *
     * This factory method creates an OSC address that selects a specific
     * clip in Resolume's UI. Selection must be followed by "connect" to
     * actually display the clip.
     *
     * @param layer The Resolume layer number (1-indexed)
     * @param clip The Resolume clip number (1-indexed)
     * @return An OSCAddress for selecting a clip, or nil if invalid
     */
    static func resolumeTriggerClip(layer: Int, clip: Int) -> OSCAddress? {
        // Based on Resolume OSC documentation
        // Resolume uses a two-step process: first select, then connect
        OSCAddress("/composition/layers/\(layer)/clips/\(clip)/select")
    }
    
    /**
     * Create an address for clearing the Resolume screen
     *
     * This factory method creates an OSC address that selects a blank clip
     * designed to clear the LED display.
     *
     * @param layer The Resolume layer number (1-indexed)
     * @param clearClip The Resolume clip number for the clear clip (1-indexed)
     * @return An OSCAddress for the clear clip, or nil if invalid
     */
    static func resolumeClearScreen(layer: Int, clearClip: Int) -> OSCAddress? {
        // Use the same selection mechanism as regular clips
        OSCAddress("/composition/layers/\(layer)/clips/\(clearClip)/select")
    }
}

// MARK: - OSCTypeTag

/**
 * Represents the type tag of an OSC argument
 *
 * OSC messages include a type tag string that describes the data types
 * of each argument in the message. This enum defines all supported
 * OSC data types according to the OSC 1.0 specification.
 */
enum OSCTypeTag: String {
    // Standard OSC 1.0 types
    case int32 = "i"    // 32-bit signed integer
    case float32 = "f"  // 32-bit IEEE 754 floating point
    case string = "s"   // Null-terminated string
    case blob = "b"     // Arbitrary binary data with size prefix
    
    // Extended OSC types
    case int64 = "h"    // 64-bit signed integer
    case timetag = "t"  // OSC time tag (64-bit fixed point)
    case double = "d"   // 64-bit IEEE 754 double precision
    case char = "c"     // 32-bit character
    case color = "r"    // 32-bit RGBA color value
    case midi = "m"     // 4-byte MIDI message
    
    // Special type tags (no actual data)
    case `true` = "T"   // Boolean true (no data bytes)
    case `false` = "F"  // Boolean false (no data bytes)
    case null = "N"     // Null value (no data bytes)
    case impulse = "I"  // Impulse trigger (no data bytes)
    
    /**
     * Get the fixed size in bytes for this type, or nil for variable-size types
     * Used for binary data layout calculations in OSC encoding
     *
     * @return Number of bytes for fixed-size types, nil for variable-size types
     */
    var fixedSize: Int? {
        switch self {
        case .int32, .float32, .char, .color, .midi:
            return 4  // 32-bit/4-byte types
            
        case .int64, .timetag, .double:
            return 8  // 64-bit/8-byte types
            
        case .string, .blob:
            return nil  // Variable size types with null termination or size prefix
            
        case .true, .false, .null, .impulse:
            return 0  // Types that have no data payload
        }
    }
}

// MARK: - OSCArgument

/**
 * Protocol that all OSC argument types conform to
 *
 * This protocol defines the common interface for all OSC argument types,
 * allowing them to be used polymorphically in OSC messages while still
 * maintaining type safety.
 */
protocol OSCArgument {
    /**
     * The type tag for this argument
     * Identifies the data type in the OSC type tag string
     */
    var typeTag: OSCTypeTag { get }
    
    /**
     * Encode the argument to binary data for OSC transmission
     * Must follow the OSC specification for binary representation
     *
     * @return Data containing the binary encoded argument
     */
    func encode() -> Data
}

/**
 * An integer OSC argument
 * Represents a 32-bit signed integer in OSC messages
 */
struct OSCInt: OSCArgument {
    /// The integer value
    let value: Int32
    
    /// The OSC type tag (i - 32-bit integer)
    var typeTag: OSCTypeTag { .int32 }
    
    /**
     * Encode the integer to network byte order (big endian)
     * OSC requires all numeric values to be in network byte order
     *
     * @return Data containing the big-endian encoded 32-bit integer
     */
    func encode() -> Data {
        var int32 = value.bigEndian
        return Data(bytes: &int32, count: 4)
    }
}

/**
 * A floating point OSC argument
 * Represents a 32-bit IEEE 754 float in OSC messages
 */
struct OSCFloat: OSCArgument {
    /// The float value
    let value: Float
    
    /// The OSC type tag (f - 32-bit float)
    var typeTag: OSCTypeTag { .float32 }
    
    /**
     * Encode the float to network byte order (big endian)
     * Uses bit pattern to preserve the exact binary representation
     *
     * @return Data containing the big-endian encoded 32-bit float
     */
    func encode() -> Data {
        var float32 = value.bitPattern.bigEndian
        return Data(bytes: &float32, count: 4)
    }
}

/**
 * A string OSC argument
 * Represents a UTF-8 string in OSC messages
 */
struct OSCString: OSCArgument {
    /// The string value
    let value: String
    
    /// The OSC type tag (s - string)
    var typeTag: OSCTypeTag { .string }
    
    /**
     * Encode the string according to OSC specification:
     * - UTF-8 encoding
     * - Null-terminated
     * - Padded to multiple of 4 bytes
     *
     * @return Data containing the encoded, terminated, and padded string
     */
    func encode() -> Data {
        guard let stringData = value.data(using: .utf8) else {
            return Data()
        }
        
        // OSC strings follow specific encoding rules
        var data = stringData
        
        // 1. Add null terminator
        data.append(0)
        
        // 2. Pad to multiple of 4 bytes with null bytes
        let padding = 4 - (data.count % 4)
        if padding < 4 {
            data.append(contentsOf: [UInt8](repeating: 0, count: padding))
        }
        
        return data
    }
}

/**
 * A boolean true OSC argument
 * Represents the boolean value 'true' in OSC messages
 */
struct OSCTrue: OSCArgument {
    /// The OSC type tag (T - true)
    var typeTag: OSCTypeTag { .true }
    
    /**
     * Encode the true value
     * For boolean true in OSC, there is no actual data payload
     *
     * @return Empty data (the type tag alone indicates the value)
     */
    func encode() -> Data {
        // True has no data payload in OSC, just the type tag
        return Data()
    }
}

/**
 * A boolean false OSC argument
 * Represents the boolean value 'false' in OSC messages
 */
struct OSCFalse: OSCArgument {
    /// The OSC type tag (F - false)
    var typeTag: OSCTypeTag { .false }
    
    /**
     * Encode the false value
     * For boolean false in OSC, there is no actual data payload
     *
     * @return Empty data (the type tag alone indicates the value)
     */
    func encode() -> Data {
        // False has no data payload in OSC, just the type tag
        return Data()
    }
}

/**
 * Convenience factory methods for creating OSC arguments
 * These extensions provide a cleaner syntax for creating typed arguments
 */
extension OSCArgument where Self == OSCString {
    /**
     * Create a string OSC argument
     *
     * @param value The string value
     * @return A new OSCString argument
     */
    static func string(_ value: String) -> OSCArgument {
        OSCString(value: value)
    }
}

extension OSCArgument where Self == OSCInt {
    /**
     * Create an integer OSC argument
     *
     * @param value The integer value
     * @return A new OSCInt argument
     */
    static func int(_ value: Int32) -> OSCArgument {
        OSCInt(value: value)
    }
}

extension OSCArgument where Self == OSCFloat {
    /**
     * Create a float OSC argument
     *
     * @param value The float value
     * @return A new OSCFloat argument
     */
    static func float(_ value: Float) -> OSCArgument {
        OSCFloat(value: value)
    }
}

extension OSCArgument where Self == OSCTrue {
    /**
     * Create a true OSC argument
     *
     * @return A new OSCTrue argument
     */
    static var `true`: OSCArgument {
        OSCTrue()
    }
}

extension OSCArgument where Self == OSCFalse {
    /**
     * Create a false OSC argument
     *
     * @return A new OSCFalse argument
     */
    static var `false`: OSCArgument {
        OSCFalse()
    }
}

// MARK: - OSCMessage

/**
 * Represents a complete OSC message
 *
 * An OSC message consists of:
 * 1. An address pattern string (starting with /)
 * 2. A type tag string (starting with ,)
 * 3. Zero or more arguments of various types
 *
 * This struct handles construction and encoding of OSC messages
 * for transmission over network connections.
 */
struct OSCMessage {
    /**
     * The address pattern
     * Specifies the target of the message in the OSC server
     */
    let address: OSCAddress
    
    /**
     * The arguments to the message
     * Contains the data values to be transmitted
     */
    let arguments: [OSCArgument]
    
    /**
     * Create a message with an address string and arguments
     *
     * @param address The OSC address string
     * @param arguments Optional array of OSC arguments
     * @return nil if the address is invalid
     */
    init?(address: String, arguments: [OSCArgument] = []) {
        guard let oscAddress = OSCAddress(address) else {
            return nil
        }
        
        self.address = oscAddress
        self.arguments = arguments
    }
    
    /**
     * Create a message to set text content in Resolume
     *
     * This factory method creates a properly formatted OSC message
     * for setting the text content of a clip in Resolume Arena.
     *
     * @param layer The Resolume layer number (1-indexed)
     * @param clip The Resolume clip number (1-indexed)
     * @param text The text content to set
     * @return A configured OSCMessage or nil if creation fails
     */
    static func resolumeText(layer: Int, clip: Int, text: String) -> OSCMessage? {
        guard let address = OSCAddress.resolumeTextContent(layer: layer, clip: clip) else {
            return nil
        }
        
        return OSCMessage(address: address.value, arguments: [OSCString(value: text)])
    }
    
    /**
     * Create a message to trigger (select) a clip in Resolume
     *
     * This factory method creates a properly formatted OSC message
     * for selecting a clip in Resolume Arena's UI.
     *
     * @param layer The Resolume layer number (1-indexed)
     * @param clip The Resolume clip number (1-indexed)
     * @return A configured OSCMessage or nil if creation fails
     */
    static func resolumeTriggerClip(layer: Int, clip: Int) -> OSCMessage? {
        guard let address = OSCAddress.resolumeTriggerClip(layer: layer, clip: clip) else {
            return nil
        }
        
        // Resolume documentation specifies using a boolean true value
        return OSCMessage(address: address.value, arguments: [OSCTrue()])
    }
    
    /**
     * Create a message to clear the screen in Resolume
     *
     * This factory method creates a properly formatted OSC message
     * for activating a blank clip that clears the LED display.
     *
     * @param layer The Resolume layer number (1-indexed)
     * @param clearClip The Resolume clip number for the clear clip (1-indexed)
     * @return A configured OSCMessage or nil if creation fails
     */
    static func resolumeClearScreen(layer: Int, clearClip: Int) -> OSCMessage? {
        guard let address = OSCAddress.resolumeClearScreen(layer: layer, clearClip: clearClip) else {
            return nil
        }
        
        // Use the same format as trigger clip for consistency
        return OSCMessage(address: address.value, arguments: [OSCTrue()])
    }
    
    /**
     * Encode the message to binary OSC format according to specification
     *
     * The OSC binary format consists of:
     * 1. Address string (null-terminated, padded to 4 bytes)
     * 2. Type tag string (starting with ",", null-terminated, padded to 4 bytes)
     * 3. Arguments data (encoded according to their type)
     *
     * @return Data containing the complete encoded OSC message
     */
    func encode() -> Data {
        var data = Data()
        
        // 1. Encode address with correct padding
        if let addressData = address.value.data(using: .utf8) {
            data.append(addressData)
            
            // Add null terminator
            data.append(0)
            
            // Calculate padding needed to make the total length a multiple of 4
            let totalAddressLength = addressData.count + 1 // +1 for null terminator
            let paddingNeeded = (4 - (totalAddressLength % 4)) % 4 // Mod 4 again to handle case when already multiple of 4
            
            // Add padding
            if paddingNeeded > 0 {
                data.append(contentsOf: [UInt8](repeating: 0, count: paddingNeeded))
            }
        }
        
        // 2. Encode type tag string
        if !arguments.isEmpty {
            // Type tag string starts with comma followed by type tags
            var typeTagString = ","
            for arg in arguments {
                typeTagString += arg.typeTag.rawValue
            }
            
            // Encode type tag string with correct padding
            if let typeTagData = typeTagString.data(using: .utf8) {
                data.append(typeTagData)
                
                // Add null terminator
                data.append(0)
                
                // Calculate padding needed to make the total length a multiple of 4
                let totalTypeTagLength = typeTagData.count + 1 // +1 for null terminator
                let paddingNeeded = (4 - (totalTypeTagLength % 4)) % 4 // Mod 4 again to handle case when already multiple of 4
                
                // Add padding
                if paddingNeeded > 0 {
                    data.append(contentsOf: [UInt8](repeating: 0, count: paddingNeeded))
                }
            }
            
            // 3. Encode all arguments in sequence
            for arg in arguments {
                data.append(arg.encode())
            }
        } else {
            // Even with no arguments, we need an empty type tag section
            // with a comma and null terminator, properly padded
            let emptyTypeTag = ",".data(using: .utf8)!
            data.append(emptyTypeTag)
            data.append(0) // null terminator
            
            // Calculate padding needed (already have 2 bytes: comma + null)
            let paddingNeeded = (4 - 2) % 4
            if paddingNeeded > 0 {
                data.append(contentsOf: [UInt8](repeating: 0, count: paddingNeeded))
            }
        }
        
        return data
    }
}

// MARK: - OSCBundle

/**
 * Represents an OSC bundle containing multiple messages or nested bundles
 *
 * Bundles allow sending multiple OSC messages atomically with a shared timestamp.
 * They are useful for synchronization and ensuring multiple operations
 * are processed together.
 */
struct OSCBundle {
    /**
     * The timestamp for the bundle
     * OSC timestamps are 64-bit fixed-point NTP timestamps
     */
    let timestamp: UInt64
    
    /**
     * The elements in the bundle (already-encoded messages or nested bundles)
     * Stored as raw Data to avoid circular dependencies
     */
    let elements: [Data]
    
    /**
     * Create a bundle with pre-encoded elements
     *
     * @param timestamp Optional timestamp (default: 1, meaning "immediate")
     * @param elements Array of pre-encoded OSC message or bundle data
     */
    init(timestamp: UInt64 = 1, elements: [Data]) {
        self.timestamp = timestamp
        self.elements = elements
    }
    
    /**
     * Encode the bundle to binary OSC format
     *
     * The OSC bundle format consists of:
     * 1. "#bundle" string (null-terminated, padded to 4 bytes)
     * 2. Timestamp (8 bytes, big-endian)
     * 3. Each element prefixed with its size (4-byte big-endian)
     *
     * @return Data containing the complete encoded OSC bundle
     */
    func encode() -> Data {
        var data = Data()
        
        // 1. Bundle header
        let bundleHeader = "#bundle"
        if let headerData = bundleHeader.data(using: .utf8) {
            data.append(headerData)
            
            // Add null terminator
            data.append(0)
            
            // Pad to multiple of 4 bytes
            let padding = 4 - ((headerData.count + 1) % 4)
            if padding < 4 {
                data.append(contentsOf: [UInt8](repeating: 0, count: padding))
            }
        }
        
        // 2. Timestamp (OSC time tag)
        var bigEndianTimestamp = timestamp.bigEndian
        data.append(Data(bytes: &bigEndianTimestamp, count: 8))
        
        // 3. Bundle elements (each prefixed with size)
        for element in elements {
            // Add 4-byte size prefix in big-endian byte order
            var bigEndianSize = UInt32(element.count).bigEndian
            data.append(Data(bytes: &bigEndianSize, count: 4))
            
            // Add the element data itself
            data.append(element)
        }
        
        return data
    }
}