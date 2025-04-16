//
//  MessageQueueView.swift
//  LEDMESSENGER
//
//  Created by Claude AI on 4/12/2025.
//

import SwiftUI

/// View for displaying the message queue
struct MessageQueueView: View {
    @ObservedObject var viewModel: MessageViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Message queue list
            if viewModel.messages.isEmpty {
                emptyQueueView
            } else {
                messageListView
            }
        }
    }
    
    /// View for empty queue state
    private var emptyQueueView: some View {
        VStack(spacing: 15) {
            Spacer()
            
            Text("No messages in queue")
                .font(.system(size: 18))
                .foregroundColor(.gray)
            
            Text("Click '+' to create a message")
                .font(.system(size: 14))
                .foregroundColor(.gray.opacity(0.7))
            
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding(.horizontal, 20)
    }
    
    /// List of messages in the queue
    private var messageListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.messages) { message in
                    MessageCardView(message: message) {
                        Task {
                            await viewModel.sendMessageToWall(message.id)
                        }
                    } onCancel: {
                        viewModel.cancelMessage(message.id)
                    } onEdit: {
                        // Set up editing state
                        viewModel.editingMessageId = message.id
                        viewModel.newMessageText = message.text
                        viewModel.newMessageIdentifier = message.identifier
                        viewModel.newMessageLabelType = message.labelType
                        viewModel.newMessageCustomLabel = message.customLabel
                        viewModel.showingNewMessageSheet = true
                        
                        // Notify ContentView to show the sheet
                        NotificationCenter.default.post(
                            name: .editMessageRequested,
                            object: nil
                        )
                    }
                    .transition(.opacity)
                    .animation(.easeInOut, value: message.status)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct MessageQueueView_Previews: PreviewProvider {
    static var previews: some View {
        // Sample message view model for preview
        let settingsManager = SettingsManager()
        let oscService = OSCService(
            host: settingsManager.settings.osc.host,
            port: settingsManager.settings.osc.port
        )
        let resolumeService = ResolumeOSCService(
            oscService: oscService,
            layer: settingsManager.settings.osc.layer,
            startingClip: settingsManager.settings.osc.startingClip,
            clearClip: settingsManager.settings.osc.clearClip
        )
        
        let sampleViewModel = MessageViewModel(
            resolumeService: resolumeService,
            settingsManager: settingsManager
        )
        
        return MessageQueueView(viewModel: sampleViewModel)
            .previewLayout(.sizeThatFits)
            .background(Theme.backgroundGradient)
    }
}