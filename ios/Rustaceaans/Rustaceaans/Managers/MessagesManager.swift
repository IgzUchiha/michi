import Foundation
import SwiftUI

class MessagesManager: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var currentMessages: [Message] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private var pollingTask: Task<Void, Never>?
    private var currentUserId: String?
    private var currentChatUserId: String?
    
    // MARK: - Conversations
    
    func loadConversations(for userId: String) async {
        currentUserId = userId
        
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        do {
            let fetchedConversations = try await APIService.shared.fetchConversations(userId: userId)
            
            await MainActor.run {
                self.conversations = fetchedConversations
                self.isLoading = false
            }
            
            print("✅ Loaded \(fetchedConversations.count) conversations")
        } catch {
            await MainActor.run {
                self.error = "Failed to load conversations: \(error.localizedDescription)"
                self.isLoading = false
            }
            print("❌ Failed to load conversations: \(error)")
        }
    }
    
    // MARK: - Messages
    
    func loadMessages(currentUserId: String, otherUserId: String) async {
        self.currentUserId = currentUserId
        self.currentChatUserId = otherUserId
        
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        do {
            let fetchedMessages = try await APIService.shared.fetchMessages(
                currentUserId: currentUserId,
                otherUserId: otherUserId
            )
            
            await MainActor.run {
                self.currentMessages = fetchedMessages
                self.isLoading = false
            }
            
            // Mark messages as read
            try? await APIService.shared.markMessagesRead(
                currentUserId: currentUserId,
                otherUserId: otherUserId
            )
            
            print("✅ Loaded \(fetchedMessages.count) messages")
        } catch {
            await MainActor.run {
                self.error = "Failed to load messages: \(error.localizedDescription)"
                self.isLoading = false
            }
            print("❌ Failed to load messages: \(error)")
        }
    }
    
    // MARK: - Send Messages
    
    func sendTextMessage(_ text: String, from senderId: String, to receiverId: String) async throws {
        let content = MessageContent(
            type: .text,
            text: text,
            memeId: nil,
            mediaUrl: nil
        )
        
        try await sendMessage(content: content, from: senderId, to: receiverId)
    }
    
    func sendMeme(_ meme: Meme, from senderId: String, to receiverId: String) async throws {
        let content = MessageContent(
            type: .meme,
            text: "Shared a meme: \(meme.caption)",
            memeId: meme.id,
            mediaUrl: meme.imageUrl
        )
        
        try await sendMessage(content: content, from: senderId, to: receiverId)
    }
    
    func sendImage(_ imageUrl: String, from senderId: String, to receiverId: String) async throws {
        let content = MessageContent(
            type: .image,
            text: nil,
            memeId: nil,
            mediaUrl: imageUrl
        )
        
        try await sendMessage(content: content, from: senderId, to: receiverId)
    }
    
    private func sendMessage(content: MessageContent, from senderId: String, to receiverId: String) async throws {
        let newMessage = try await APIService.shared.sendMessage(
            senderId: senderId,
            receiverId: receiverId,
            content: content
        )
        
        await MainActor.run {
            // Add to current messages if we're in this chat
            if currentChatUserId == receiverId {
                currentMessages.append(newMessage)
            }
        }
        
        print("✅ Message sent!")
    }
    
    // MARK: - Polling for New Messages
    
    func startPolling(currentUserId: String, otherUserId: String, interval: TimeInterval = 2.0) {
        stopPolling()
        
        pollingTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                
                guard !Task.isCancelled else { break }
                
                await loadMessages(currentUserId: currentUserId, otherUserId: otherUserId)
            }
        }
        
        print("🔄 Started polling for new messages")
    }
    
    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
        print("⏸️ Stopped polling")
    }
    
    deinit {
        stopPolling()
    }
    
    // MARK: - Helpers
    
    func totalUnreadCount() -> Int {
        conversations.reduce(0) { $0 + $1.unreadCount }
    }
}
