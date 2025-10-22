import Foundation

// MARK: - Message Content Types
enum MessageContentType: String, Codable {
    case text
    case meme
    case image
    case video
}

struct MessageContent: Codable {
    let type: MessageContentType
    let text: String?
    let memeId: Int?
    let mediaUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case type
        case text
        case memeId = "meme_id"
        case mediaUrl = "media_url"
    }
}

// MARK: - Message Model
struct Message: Identifiable, Codable {
    let id: Int
    let senderId: String
    let receiverId: String
    let content: MessageContent
    let timestamp: String
    var isRead: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case senderId = "sender_id"
        case receiverId = "receiver_id"
        case content
        case timestamp
        case isRead = "is_read"
    }
    
    // Helper to format timestamp
    var formattedTime: String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: timestamp) {
            let displayFormatter = DateFormatter()
            displayFormatter.timeStyle = .short
            displayFormatter.dateStyle = .none
            return displayFormatter.string(from: date)
        }
        return ""
    }
    
    var isFromCurrentUser: Bool {
        // Will be set based on current user's wallet address
        return false
    }
}

// MARK: - Conversation Model
struct Conversation: Identifiable, Codable {
    let id: String
    let otherUserId: String
    let otherUserName: String?
    let lastMessage: Message?
    let unreadCount: Int
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case otherUserId = "other_user_id"
        case otherUserName = "other_user_name"
        case lastMessage = "last_message"
        case unreadCount = "unread_count"
        case updatedAt = "updated_at"
    }
    
    var displayName: String {
        if let name = otherUserName {
            return name
        }
        // Show truncated address if no name
        return String(otherUserId.prefix(8)) + "..."
    }
    
    var lastMessagePreview: String {
        guard let lastMsg = lastMessage else {
            return "No messages yet"
        }
        
        switch lastMsg.content.type {
        case .text:
            return lastMsg.content.text ?? ""
        case .meme:
            return "🎭 Shared a meme"
        case .image:
            return "📷 Shared an image"
        case .video:
            return "🎥 Shared a video"
        }
    }
}

// MARK: - Request Models
struct SendMessageRequest: Codable {
    let senderId: String
    let receiverId: String
    let content: MessageContent
    
    enum CodingKeys: String, CodingKey {
        case senderId = "sender_id"
        case receiverId = "receiver_id"
        case content
    }
}

struct MarkReadRequest: Codable {
    let userId: String
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
    }
}
