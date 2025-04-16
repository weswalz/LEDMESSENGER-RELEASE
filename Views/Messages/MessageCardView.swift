//
//  MessageCardView.swift
//  LEDMESSENGER
//
//  Created by Claude AI on 4/12/2025.
//

import SwiftUI

/// View for an individual message card in the message queue
struct MessageCardView: View {
    let message: Message
    let onSend: () -> Void
    let onCancel: () -> Void
    let onEdit: () -> Void
    
    // Animation state for sent message pulse
    @State private var pulseAnimation = false
    @State private var fadeAnimation = false
    
    // Timer to control the fade
    @State private var timer: Timer? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Message content
            VStack(alignment: .leading, spacing: 8) {
                // Message text only - no label
                Text(message.text)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding([.horizontal, .top], 10)
            
            // No visible status indicator - using stroke animation instead
            
            // Action buttons
            HStack(spacing: 10) {
                if message.status == .queued {
                    // Delete button
                    Button(action: onCancel) {
                        Text("DELETE")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(Theme.dangerRed)
                            .cornerRadius(8)
                    }
                    .consistentMacOSStyle()
                    
                    // Edit button
                    Button(action: onEdit) {
                        Text("EDIT")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(Theme.secondaryGradient)
                            .cornerRadius(8)
                    }
                    .consistentMacOSStyle()
                    
                    Spacer()
                    
                    // Send to wall button
                    Button(action: onSend) {
                        Text("SEND TO WALL")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(Theme.primaryGradient)
                            .cornerRadius(8)
                    }
                    .consistentMacOSStyle()
                } else if message.status == .sent {
                    // Full width HStack with right-aligned button
                    HStack {
                        Spacer()
                        
                        // Return message to queue button 
                        Button(action: onCancel) {
                            Text("RETURN TO QUEUE")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(Theme.dangerRed)
                                .cornerRadius(8)
                        }
                        .consistentMacOSStyle()
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 10)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.cardGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            message.status == .sent ? 
                                Theme.successGreen.opacity(pulseAnimation ? 1.0 : (fadeAnimation ? 0.1 : 0.8)) : 
                                Theme.accentPeach.opacity(0.5),
                            lineWidth: message.status == .sent ? 2.5 : 1.5
                        )
                )
        )
        .onAppear {
            if message.status == .sent {
                // Start the pulsing animation
                withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    pulseAnimation = true
                }
                
                // Set up timer to fade out over 5 minutes
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
                        withAnimation(Animation.linear(duration: 300)) { // 5 minutes = 300 seconds
                            fadeAnimation = true
                        }
                    }
                }
                
                // Set up timer to automatically hide message after countdown completes
                if let expiresAt = message.expiresAt {
                    let timeRemaining = expiresAt.timeIntervalSinceNow
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + timeRemaining) {
                        withAnimation {
                            onCancel() // This will cancel the message once it expires
                        }
                    }
                }
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
        .shadow(
            color: Color.black.opacity(0.2),
            radius: 8,
            x: 0,
            y: 4
        )
    }
}