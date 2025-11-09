//
//  ConversationView.swift
//  OmniTAKTest
//
//  Message thread UI with bubbles, send button, input field
//

import SwiftUI

struct ConversationView: View {
    @ObservedObject var chatManager: ChatManager
    let conversation: Conversation

    @State private var messageText = ""
    @State private var scrollProxy: ScrollViewProxy?
    @FocusState private var isInputFocused: Bool

    var messages: [ChatMessage] {
        chatManager.getMessages(for: conversation.id)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Messages list
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { message in
                            MessageBubble(
                                message: message,
                                isFromSelf: message.isFromSelf
                            )
                            .id(message.id)
                        }
                    }
                    .padding()
                }
                .onAppear {
                    scrollProxy = proxy
                    scrollToBottom()
                    // Mark conversation as read
                    chatManager.markConversationAsRead(conversationId: conversation.id)
                }
                .onChange(of: messages.count) { _ in
                    scrollToBottom()
                }
            }

            Divider()

            // Message input
            HStack(spacing: 12) {
                TextField("Message", text: $messageText)
                    .textFieldStyle(.roundedBorder)
                    .focused($isInputFocused)

                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue)
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
        }
        .navigationTitle(conversation.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        chatManager.sendMessage(text: text, to: conversation.id)
        messageText = ""
        scrollToBottom()
    }

    private func scrollToBottom() {
        guard let lastMessage = messages.last else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation {
                scrollProxy?.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ChatMessage
    let isFromSelf: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isFromSelf {
                Spacer()
            }

            VStack(alignment: isFromSelf ? .trailing : .leading, spacing: 4) {
                // Sender name (only for received messages)
                if !isFromSelf {
                    Text(message.senderCallsign)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.leading, 12)
                }

                // Message bubble
                HStack(alignment: .bottom, spacing: 4) {
                    Text(message.messageText)
                        .font(.body)
                        .foregroundColor(isFromSelf ? .white : .primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(isFromSelf ? Color.blue : Color(.systemGray5))
                        )

                    // Status indicator for sent messages
                    if isFromSelf {
                        statusIcon
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }

                // Timestamp
                Text(formatTimestamp(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 12)
            }

            if !isFromSelf {
                Spacer()
            }
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch message.status {
        case .sending:
            Image(systemName: "clock")
        case .sent:
            Image(systemName: "checkmark")
        case .delivered:
            Image(systemName: "checkmark.circle")
        case .failed:
            Image(systemName: "exclamationmark.circle")
                .foregroundColor(.red)
        }
    }

    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Preview

struct ConversationView_Previews: PreviewProvider {
    static var previews: some View {
        let chatManager = ChatManager.shared
        let conversation = Conversation(
            title: "Test User",
            participants: [
                ChatParticipant(id: "test-1", callsign: "Test User")
            ]
        )

        NavigationView {
            ConversationView(chatManager: chatManager, conversation: conversation)
        }
    }
}
