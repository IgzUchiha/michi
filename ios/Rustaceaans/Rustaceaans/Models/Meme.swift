import Foundation

struct Meme: Identifiable, Codable {
    let id: Int
    let imageUrl: String
    let caption: String
    let tags: String  // API returns string, not array
    let creatorAddress: String
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

struct User: Codable {
    let address: String
    let username: String?
    let email: String?
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
