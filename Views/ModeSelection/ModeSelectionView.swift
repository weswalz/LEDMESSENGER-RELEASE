//
//  ModeSelectionView.swift
//  LEDMESSENGER
//
//  Created for iPad mode implementation
//

import SwiftUI

/**
 * Mode selection screen for iPad
 *
 * Displays a startup screen that allows the user to choose
 * between SOLO and PAIRED modes for iPad operation.
 */
struct ModeSelectionView: View {
    /// View model for app state and mode control - explicitly ObservedObject to ensure UI updates
    @ObservedObject var viewModel: AppViewModel
    
    /// Current selected mode (independent of app actual mode)
    @State private var selectedMode: AppMode = .paired
    
    /// Animation state for buttons
    @State private var animateButtons = false
    @State private var animateBackground = false
    
    /// View for continue button label
    private var continueLabelView: some View {
        Text("CONTINUE")
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 60)
            .padding(.vertical, 16)
            .background(Theme.primaryGradient)
            .cornerRadius(25)
            .shadow(color: Theme.accentPurple.opacity(0.5), radius: 8)
    }
    
    var body: some View {
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
            .hueRotation(.degrees(animateBackground ? 30 : 0))
            .animation(
                Animation.easeInOut(duration: 10)
                    .repeatForever(autoreverses: true),
                value: animateBackground
            )
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                self.animateBackground = true
            }
            
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
                
                // Mode buttons
                VStack(spacing: 20) {
                    ForEach(AppMode.allCases) { mode in
                        ModeSelectButton(
                            mode: mode,
                            isSelected: selectedMode == mode,
                            action: {
                                withAnimation(.spring()) {
                                    self.selectedMode = mode
                                }
                            }
                        )
                        .scaleEffect(animateButtons ? 1.0 : 0.95)
                        .opacity(animateButtons ? 1.0 : 0)
                        .offset(y: animateButtons ? 0 : 20)
                        .animation(
                            .spring(response: 0.6, dampingFraction: 0.7).delay(mode == .solo ? 0.1 : 0.2),
                            value: animateButtons
                        )
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Mode explanation text
                VStack(alignment: .leading, spacing: 8) {
                    // Explanation based on selected mode
                    if selectedMode == .solo {
                        Text("Solo Mode")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Your iPad will have all the features of the Mac app, including setup and settings configuration. It will connect directly to Resolume.")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text("Paired Mode")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Your iPad will connect to a Mac running LED Messenger. The Mac will control settings and configuration while your iPad sends messages.")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
                .transition(.opacity)
                .id("explanation-\(selectedMode)")
                .animation(.easeInOut, value: selectedMode)
                
                // Continue button with two separate actions
                ZStack {
                    if selectedMode == .solo {
                        // Solo mode button
                        Button {
                            print("DEBUG: SOLO button pressed")
                            // Set the app mode
                            self.viewModel.appMode = .solo
                            // Force navigation to setup
                            self.viewModel.navigateToSetup()
                            // Hide the mode selection
                            self.viewModel.shouldShowModeSelection = false
                        } label: {
                            continueLabelView
                        }
                    } else {
                        // Paired mode button
                        Button {
                            print("DEBUG: PAIRED button pressed")
                            // Set the app mode
                            self.viewModel.appMode = .paired
                            // Force navigation to message management
                            self.viewModel.navigateToMessageManagement()
                            // Hide the mode selection
                            self.viewModel.shouldShowModeSelection = false
                        } label: {
                            continueLabelView
                        }
                    }
                }
                .padding(.bottom, 50)
                .opacity(animateButtons ? 1.0 : 0)
                .offset(y: animateButtons ? 0 : 20)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: animateButtons)
            }
        }
        .onAppear {
            // Set initial mode to current app mode
            self.selectedMode = self.viewModel.appMode
            
            // Animate buttons appearing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation {
                    self.animateButtons = true
                }
            }
        }
    }
}

#Preview {
    ModeSelectionView(viewModel: AppViewModel())
        .preferredColorScheme(.dark)
}