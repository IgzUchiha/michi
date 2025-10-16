import SwiftUI

struct MemeDetailView: View {
    let meme: Meme
    @EnvironmentObject var walletManager: WalletManager
    @State private var newComment = ""
    @State private var isLiking = false
    @State private var showTipSuccess = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Meme image
                AsyncImage(url: URL(string: meme.imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(ProgressView())
                }
                .cornerRadius(10)
                
                // Caption
                Text(meme.caption)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                // Tags
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(meme.tagsArray, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(15)
                        }
                    }
                }
                
                // Like & Tip button
                HStack {
                    Button(action: {
                        Task {
                            await likeAndTip()
                        }
                    }) {
                        HStack {
                            Image(systemName: isLiking ? "hourglass" : "heart.fill")
                            Text(isLiking ? "Sending..." : "Like & Tip 0.001 ETH")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(walletManager.isConnected ? Color.red : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(!walletManager.isConnected || isLiking)
                    
                    Text("\(meme.likes)")
                        .font(.headline)
                        .padding()
                }
                
                if showTipSuccess {
                    Text("✅ Tip sent successfully!")
                        .foregroundColor(.green)
                        .padding()
                }
                
                Divider()
                
                // Comments section
                Text("Comments (\(meme.commentCount))")
                    .font(.headline)
                
                Text("Comments feature coming soon!")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
                
                // Add comment
                if walletManager.isConnected {
                    HStack {
                        TextField("Add a comment...", text: $newComment)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button("Post") {
                            Task {
                                await postComment()
                            }
                        }
                        .disabled(newComment.isEmpty)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Meme Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func likeAndTip() async {
        guard let address = walletManager.walletAddress else { return }
        
        isLiking = true
        
        do {
            // Send tip via smart contract
            try await walletManager.sendTip(amount: "0.001", to: meme.creatorAddress)
            
            // Record like in backend
            try await APIService.shared.likeMeme(id: meme.id, walletAddress: address)
            
            showTipSuccess = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                showTipSuccess = false
            }
        } catch {
            print("Failed to like and tip: \(error)")
        }
        
        isLiking = false
    }
    
    func postComment() async {
        guard let address = walletManager.walletAddress else { return }
        
        do {
            try await APIService.shared.addComment(
                memeId: meme.id,
                content: newComment,
                walletAddress: address
            )
            newComment = ""
        } catch {
            print("Failed to post comment: \(error)")
        }
    }
}
