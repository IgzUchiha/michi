import SwiftUI

struct FeedView: View {
    @EnvironmentObject var walletManager: WalletManager
    @EnvironmentObject var authManager: AuthManager
    @State private var memes: [Meme] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(red: 0.98, green: 0.98, blue: 0.99)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Wallet connection banner
                    if !walletManager.isConnected {
                        Button(action: {
                            walletManager.connectWallet(with: authManager)
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "wallet.pass.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Connect Wallet to Like & Tip")
                                    .font(.system(size: 15, weight: .medium))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.5, green: 0.2, blue: 0.6),
                                        Color(red: 0.8, green: 0.3, blue: 0.5)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(color: Color.purple.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    
                    // Meme feed
                    if isLoading {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Loading memes...")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let error = errorMessage {
                        VStack(spacing: 20) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.orange)
                            
                            Text("Oops!")
                                .font(.system(size: 24, weight: .bold))
                            
                            Text(error)
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            
                            Button(action: {
                                Task {
                                    await loadMemes()
                                }
                            }) {
                                Text("Try Again")
                                    .font(.system(size: 16, weight: .semibold))
                                    .frame(width: 140, height: 44)
                                    .background(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.5, green: 0.2, blue: 0.6),
                                                Color(red: 0.8, green: 0.3, blue: 0.5)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                            .padding(.top, 8)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if memes.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("No memes yet")
                                .font(.system(size: 20, weight: .semibold))
                            Text("Be the first to upload!")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(memes) { meme in
                                    NavigationLink(destination: MemeDetailView(meme: meme)) {
                                        MemeRowView(meme: meme)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .refreshable {
                            await loadMemes()
                        }
                    }
                }
            }
            .navigationTitle("Feed")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await loadMemes()
            }
        }
    }
    
    func loadMemes() async {
        isLoading = true
        errorMessage = nil
        
        do {
            memes = try await APIService.shared.fetchMemes()
        } catch {
            errorMessage = "Failed to load memes: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

struct MemeRowView: View {
    let meme: Meme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image
            AsyncImage(url: URL(string: meme.imageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
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
                        .scaleEffect(1.2)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 300)
            .clipped()
            .cornerRadius(16)
            
            // Caption and metadata
            VStack(alignment: .leading, spacing: 8) {
                Text(meme.caption)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(3)
                
                // Creator info
                HStack(spacing: 6) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.purple)
                    Text((meme.creatorAddress.map { String($0.prefix(8)) } ?? "Unknown") + "...")
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                
                // Engagement stats
                HStack(spacing: 20) {
                    HStack(spacing: 6) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                        Text("\(meme.likes)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 6) {
                        Image(systemName: "bubble.left.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                        Text("\(meme.commentCount)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Tags
                    if !meme.tags.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "tag.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.orange)
                            Text(meme.tagsArray.first ?? "")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}
