import SwiftUI

struct FeedView: View {
    @EnvironmentObject var walletManager: WalletManager
    @State private var memes: [Meme] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack {
                // Wallet connection banner
                if !walletManager.isConnected {
                    Button(action: {
                        walletManager.connectWallet()
                    }) {
                        HStack {
                            Image(systemName: "wallet.pass")
                            Text("Connect Wallet to Like & Tip")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding()
                }
                
                // Meme feed
                if isLoading {
                    ProgressView("Loading memes...")
                } else if let error = errorMessage {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.red)
                        Text(error)
                            .foregroundColor(.secondary)
                        Button("Retry") {
                            Task {
                                await loadMemes()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    List(memes) { meme in
                        NavigationLink(destination: MemeDetailView(meme: meme)) {
                            MemeRowView(meme: meme)
                        }
                    }
                    .refreshable {
                        await loadMemes()
                    }
                }
            }
            .navigationTitle("Meme Feed")
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
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: URL(string: meme.imageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(ProgressView())
            }
            .frame(height: 200)
            .clipped()
            .cornerRadius(10)
            
            Text(meme.caption)
                .font(.headline)
            
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                Text("\(meme.likes)")
                
                Spacer()
                
                Image(systemName: "bubble.left")
                Text("\(meme.comments.count)")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}
