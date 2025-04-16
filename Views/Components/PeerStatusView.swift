//
//  PeerStatusView.swift
//  LEDMESSENGER
//
//  Created by Claude AI on 4/12/2025.
//

import SwiftUI

/// View that shows the peer connection status
struct PeerStatusView: View {
    /// The connection status
    @Binding var isConnected: Bool
    
    /// Action to force sync with peers
    var syncAction: () -> Void
    
    /// Optional action to restart peer connectivity
    var restartAction: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 5) {
            // Connection indicator
            Circle()
                .fill(isConnected ? Theme.accentPurple : Color.red)
                .frame(width: 8, height: 8)
            
            // Status text
            Text(isConnected ? "PEER CONNECTED" : "NO PEERS")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isConnected ? Theme.accentPurple : Color.red)
            
            // Sync button (only shown when connected)
            if isConnected {
                Button(action: syncAction) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.accentPurple)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(4)
                .background(Color.black.opacity(0.3))
                .cornerRadius(4)
                #if os(iOS)
                .padding(.leading, 5)
                #endif
            }
            // Reconnect button (only shown when not connected and restart action is available)
            else if let restartAction = restartAction {
                Button(action: restartAction) {
                    Image(systemName: "network")
                        .font(.system(size: 12))
                        .foregroundColor(Color.red)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(4)
                .background(Color.black.opacity(0.3))
                .cornerRadius(4)
                #if os(iOS)
                .padding(.leading, 5)
                #endif
            }
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 3)
        .background(isConnected ? Theme.accentPurple.opacity(0.1) : Color.red.opacity(0.1))
        .cornerRadius(10)
    }
}