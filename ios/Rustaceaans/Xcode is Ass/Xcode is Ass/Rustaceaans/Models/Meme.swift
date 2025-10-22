import Foundation

// MARK: - User Model
struct User: Identifiable, Codable {
    var id: String { walletAddress }  // Use wallet as ID
    let walletAddress: String
    let email: String?
    let name: String?
    let oauthProvider: String
    let oauthId: String
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case walletAddress = "wallet_address"
        case email
        case name
        case oauthProvider = "oauth_provider"
        case oauthId = "oauth_id"
        case createdAt = "created_at"
    }
    
    var displayName: String {
        if let name = name, !name.isEmpty {
            return name
        }
        if let email = email {
            return email
        }
        return String(walletAddress.prefix(8)) + "..."
    }
}

struct Meme: Identifiable, Codable {
    let id: Int
    let imageUrl: String
    let caption: String
    let tags: String  // API returns string, not array
    let creatorAddress: String?
    let createdAt: String?  // Optional since API might not always return it
    var likes: Int
    let commentCount: Int
    
    // Computed property to convert tags string to array
    var tagsArray: [String] {
        tags.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case imageUrl = "image"  // API uses "image", not "image_url"
        case caption
        case tags
        case creatorAddress = "evm_address"  // API uses "evm_address"
        case createdAt = "created_at"
        case likes
        case commentCount = "comment_count"  // API uses "comment_count"
    }
}

struct Comment: Identifiable, Codable {
    let id: Int
    let memeId: Int
    let userAddress: String
    let content: String
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case memeId = "meme_id"
        case userAddress = "user_address"
        case content
        case createdAt = "created_at"
    }
}

struct UploadResponse: Codable {
    let success: Bool
    let memeId: Int?
    let message: String?
    
    enum CodingKeys: String, CodingKey {
        case success
        case memeId = "meme_id"
        case message
    }
}

struct RewardsResponse: Codable {
    let pendingRewards: String
    let totalEarned: String
    
    enum CodingKeys: String, CodingKey {
        case pendingRewards = "pending_rewards"
        case totalEarned = "total_earned"
    }
}
