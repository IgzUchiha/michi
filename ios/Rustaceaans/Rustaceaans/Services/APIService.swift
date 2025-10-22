import Foundation
import UIKit

class APIService {
    static let shared = APIService()
    
    // Update this to your production API URL
    // For simulator testing with local backend: use your Mac's IP address
    // To find your IP: System Settings > Network > Wi-Fi > Details > IP Address
    private let baseURL = "http://127.0.0.1:8000"
    
    // Custom URL session with longer timeout for uploads
    private lazy var uploadSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 300 // 5 minutes
        config.timeoutIntervalForResource = 600 // 10 minutes
        return URLSession(configuration: config)
    }()
    
    private init() {}
    
    // MARK: - Memes
    
    func fetchMemes() async throws -> [Meme] {
        let url = URL(string: "\(baseURL)/memes")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([Meme].self, from: data)
    }
    
    func fetchMeme(id: Int) async throws -> Meme {
        let url = URL(string: "\(baseURL)/memes/\(id)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(Meme.self, from: data)
    }
    
    func uploadMeme(image: UIImage, caption: String, tags: [String], walletAddress: String) async throws -> Meme {
        let url = URL(string: "\(baseURL)/memes")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 300 // 5 minutes
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Compress and resize image if needed
        let resizedImage = resizeImage(image: image, maxWidth: 1920, maxHeight: 1920)
        
        // Add image with better compression
        if let imageData = resizedImage.jpegData(compressionQuality: 0.7) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"image\"; filename=\"meme.jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        // Add caption
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"caption\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(caption)\r\n".data(using: .utf8)!)
        
        // Add tags
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"tags\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(tags.joined(separator: ","))\r\n".data(using: .utf8)!)
        
        // Add wallet address (backend expects "evm_address")
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"evm_address\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(walletAddress)\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await uploadSession.data(for: request)
        
        // Check for HTTP errors
        if let httpResponse = response as? HTTPURLResponse {
            print("📤 Upload response status: \(httpResponse.statusCode)")
            
            guard (200...299).contains(httpResponse.statusCode) else {
                // Print response body for debugging
                if let responseString = String(data: data, encoding: .utf8) {
                    print("❌ Server response: \(responseString)")
                }
                throw URLError(.badServerResponse)
            }
        }
        
        // Print response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("✅ Upload response: \(responseString)")
        }
        
        return try JSONDecoder().decode(Meme.self, from: data)
    }
    
    // Helper function to resize images before upload
    private func resizeImage(image: UIImage, maxWidth: CGFloat, maxHeight: CGFloat) -> UIImage {
        let size = image.size
        
        // Check if resize is needed
        if size.width <= maxWidth && size.height <= maxHeight {
            return image
        }
        
        let widthRatio = maxWidth / size.width
        let heightRatio = maxHeight / size.height
        let ratio = min(widthRatio, heightRatio)
        
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? image
    }
    
    // MARK: - Likes
    
    func likeMeme(id: Int, walletAddress: String) async throws {
        let url = URL(string: "\(baseURL)/memes/\(id)/like")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["wallet_address": walletAddress]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (_, _) = try await URLSession.shared.data(for: request)
    }
    
    // MARK: - Comments
    
    func addComment(memeId: Int, content: String, walletAddress: String) async throws {
        let url = URL(string: "\(baseURL)/memes/\(memeId)/comments")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "user_address": walletAddress,
            "content": content
        ]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (_, _) = try await URLSession.shared.data(for: request)
    }
    
    // MARK: - User
    
    func fetchUserMemes(address: String) async throws -> [Meme] {
        let url = URL(string: "\(baseURL)/users/\(address)/memes")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([Meme].self, from: data)
    }
    
    func fetchRewards(address: String) async throws -> RewardsResponse {
        let url = URL(string: "\(baseURL)/users/\(address)/rewards")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(RewardsResponse.self, from: data)
    }
    
    // MARK: - Users
    
    func registerUser(walletAddress: String, email: String?, name: String?, oauthProvider: String, oauthId: String) async throws -> User {
        let url = URL(string: "\(baseURL)/users/register")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "wallet_address": walletAddress,
            "email": email as Any,
            "name": name as Any,
            "oauth_provider": oauthProvider,
            "oauth_id": oauthId
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(User.self, from: data)
    }
    
    func searchUsers(query: String) async throws -> [User] {
        var components = URLComponents(string: "\(baseURL)/users/search")!
        components.queryItems = [URLQueryItem(name: "query", value: query)]
        
        let url = components.url!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([User].self, from: data)
    }
    
    func getAllUsers() async throws -> [User] {
        let url = URL(string: "\(baseURL)/users")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([User].self, from: data)
    }
    
    func getUserByWallet(walletAddress: String) async throws -> User {
        let url = URL(string: "\(baseURL)/users/\(walletAddress)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(User.self, from: data)
    }
    
    // MARK: - Messages
    
    func sendMessage(senderId: String, receiverId: String, content: MessageContent) async throws -> Message {
        let url = URL(string: "\(baseURL)/messages/send")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = SendMessageRequest(
            senderId: senderId,
            receiverId: receiverId,
            content: content
        )
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(Message.self, from: data)
    }
    
    func fetchConversations(userId: String) async throws -> [Conversation] {
        let url = URL(string: "\(baseURL)/messages/conversations/\(userId)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([Conversation].self, from: data)
    }
    
    func fetchMessages(currentUserId: String, otherUserId: String) async throws -> [Message] {
        let url = URL(string: "\(baseURL)/messages/\(currentUserId)/\(otherUserId)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([Message].self, from: data)
    }
    
    func markMessagesRead(currentUserId: String, otherUserId: String) async throws {
        let url = URL(string: "\(baseURL)/messages/read/\(currentUserId)/\(otherUserId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        
        let (_, _) = try await URLSession.shared.data(for: request)
    }
}
