import Foundation
import UIKit

class APIService {
    static let shared = APIService()
    
    // Update this to your production API URL
    // For simulator testing with local backend: use your Mac's IP address
    // To find your IP: System Settings > Network > Wi-Fi > Details > IP Address
    private let baseURL = "http://127.0.0.1:8000"
    
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
    
    func uploadMeme(image: UIImage, caption: String, tags: [String], walletAddress: String) async throws -> UploadResponse {
        let url = URL(string: "\(baseURL)/memes/upload")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add image
        if let imageData = image.jpegData(compressionQuality: 0.8) {
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
        
        // Add wallet address
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"creator_address\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(walletAddress)\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(UploadResponse.self, from: data)
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
}
