import SwiftUI

struct MemeDetailView: View {
    let meme: Meme
    @EnvironmentObject var walletManager: WalletManager
    @State private var newComment = ""
    @State private var isLiking = false
    @State private var showTipSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            Color(red: 0.98, green: 0.98, blue: 0.99)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Meme image
                    AsyncImage(url: URL(string: meme.imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        ZStack {
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            ProgressView()
                                .scaleEffect(1.5)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 5)
                    
                    // Content Card
                    VStack(alignment: .leading, spacing: 16) {
                        // Caption
                        Text(meme.caption)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.primary)
                        
                        // Creator info
                        HStack(spacing: 8) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.purple)
                            Text((meme.creatorAddress.map { String($0.prefix(10)) } ?? "Unknown") + "...")
                                .font(.system(size: 14, weight: .medium, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        
                        // Tags
                        if !meme.tagsArray.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(meme.tagsArray, id: \.self) { tag in
                                        Text("#\(tag)")
                                            .font(.system(size: 13, weight: .medium))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                LinearGradient(
                                                    colors: [
                                                        Color(red: 0.5, green: 0.2, blue: 0.6).opacity(0.15),
                                                        Color(red: 0.8, green: 0.3, blue: 0.5).opacity(0.15)
                                                    ],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .foregroundColor(.purple)
                                            .cornerRadius(12)
                                    }
                                }
                            }
                        }
                        
                        // Stats
                        HStack(spacing: 24) {
                            HStack(spacing: 6) {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.red)
                                Text("\(meme.likes)")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                            }
                            
                            HStack(spacing: 6) {
                                Image(systemName: "bubble.left.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.blue)
                                Text("\(meme.commentCount)")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    
                    // Like & Tip Button
                    Button(action: {
                        Task {
                            await likeAndTip()
                        }
                    }) {
                        HStack(spacing: 12) {
                            if isLiking {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                Text("Sending...")
                            } else {
                                Image(systemName: "heart.circle.fill")
                                    .font(.system(size: 20))
                                Text("Like & Tip 0.001 ETH")
                            }
                        }
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: walletManager.isConnected && !isLiking ?
                                    [Color.red, Color.red.opacity(0.8)] :
                                    [Color.gray, Color.gray],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(color: Color.red.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .disabled(!walletManager.isConnected || isLiking)
                    
                    // Success Message
                    if showTipSuccess {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.green)
                            Text("Tip sent successfully!")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(16)
                    }
                    
                    // Error Message
                    if showError {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.orange)
                            Text(errorMessage)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primary)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(16)
                    }
                    
                    // Comments Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Comments (\(meme.commentCount))")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("Comments feature coming soon!")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                        
                        // Add comment
                        if walletManager.isConnected {
                            HStack(spacing: 12) {
                                TextField("Add a comment...", text: $newComment)
                                    .font(.system(size: 15))
                                    .padding(14)
                                    .background(Color(red: 0.95, green: 0.95, blue: 0.97))
                                    .cornerRadius(12)
                                
                                Button(action: {
                                    Task {
                                        await postComment()
                                    }
                                }) {
                                    Image(systemName: "paperplane.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.white)
                                        .frame(width: 48, height: 48)
                                        .background(
                                            LinearGradient(
                                                colors: newComment.isEmpty ?
                                                    [Color.gray, Color.gray] :
                                                    [
                                                        Color(red: 0.5, green: 0.2, blue: 0.6),
                                                        Color(red: 0.8, green: 0.3, blue: 0.5)
                                                    ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .cornerRadius(12)
                                }
                                .disabled(newComment.isEmpty)
                            }
                        } else {
                            Text("Connect your wallet to comment")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .italic()
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                }
                .padding(16)
            }
        }
        .navigationTitle("Meme")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func likeAndTip() async {
        guard let address = walletManager.walletAddress else {
            withAnimation {
                errorMessage = "Please connect your wallet first"
                showError = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    showError = false
                }
            }
            return
        }
        
        isLiking = true
        showError = false
        showTipSuccess = false
        
        do {
            // Send tip via smart contract
            try await walletManager.sendTip(amount: "0.001", to: meme.creatorAddress ?? "0x0000000000000000000000000000000000000000")
            
            // Record like in backend
            try await APIService.shared.likeMeme(id: meme.id, walletAddress: address)
            
            withAnimation(.spring()) {
                showTipSuccess = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                withAnimation {
                    showTipSuccess = false
                }
            }
        } catch {
            withAnimation {
                errorMessage = "Failed to send tip: \(error.localizedDescription)"
                showError = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                withAnimation {
                    showError = false
                }
            }
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
            withAnimation {
                newComment = ""
            }
        } catch {
            withAnimation {
                errorMessage = "Failed to post comment: \(error.localizedDescription)"
                showError = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    showError = false
                }
            }
        }
    }
}
