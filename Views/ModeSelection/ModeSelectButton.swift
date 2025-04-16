//
//  ModeSelectButton.swift
//  LEDMESSENGER
//
//  Created for iPad mode implementation
//

import SwiftUI

/**
 * Custom button component for mode selection
 *
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
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovered = hovering
                }
            }
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

#Preview {
    VStack(spacing: 20) {
        ModeSelectButton(
            mode: .solo,
            isSelected: true,
            action: {}
        )
        
        ModeSelectButton(
            mode: .paired,
            isSelected: false,
            action: {}
        )
    }
    .padding()
    .background(Color.black)
}