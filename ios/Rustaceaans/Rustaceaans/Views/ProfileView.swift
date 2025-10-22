import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var walletManager: WalletManager
    @State private var userMemes: [Meme] = []
    @State private var pendingRewards = "0"
    @State private var totalEarned = "0"
    @State private var isLoading = false
    @State private var isClaiming = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.95, green: 0.95, blue: 0.97),
                        Color(red: 0.90, green: 0.92, blue: 0.95)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Profile Header
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.5, green: 0.2, blue: 0.6),
                                                Color(red: 0.8, green: 0.3, blue: 0.5)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 100, height: 100)
                                    .shadow(color: Color.purple.opacity(0.3), radius: 10, x: 0, y: 5)
                                
                                Image(systemName: "person.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(spacing: 4) {
                                Text(authManager.userName ?? "User")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                Text(authManager.userEmail ?? "user@example.com")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.top, 20)
                        
                        // Wallet Card
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Wallet")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            if walletManager.isConnected {
                                VStack(spacing: 12) {
                                    HStack {
                                        Image(systemName: "creditcard.fill")
                                            .foregroundColor(.purple)
                                        Text(walletManager.walletAddress?.prefix(10) ?? "" + "...")
                                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    }
                                    
                                    Button(action: {
                                        walletManager.disconnectWallet()
                                    }) {
                                        Text("Disconnect")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.red)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 44)
                                            .background(Color.red.opacity(0.1))
                                            .cornerRadius(12)
                                    }
                                }
                            } else {
                                Button(action: {
                                    walletManager.connectWallet(with: authManager)
                                }) {
                                    HStack {
                                        Image(systemName: "wallet.pass.fill")
                                        Text("Connect Wallet")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
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
                                    .cornerRadius(14)
                                }
                            }
                        }
                        .padding(20)
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                        .padding(.horizontal, 20)
                        
                        // Rewards Card
                        if walletManager.isConnected {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Rewards")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                HStack(spacing: 20) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Pending")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.secondary)
                                        Text("\(pendingRewards) ETH")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(.green)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    Divider()
                                        .frame(height: 40)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Total Earned")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.secondary)
                                        Text("\(totalEarned) ETH")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(.purple)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                
                                Button(action: {
                                    Task {
                                        await claimRewards()
                                    }
                                }) {
                                    HStack {
                                        if isClaiming {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            Text("Claiming...")
                                        } else {
                                            Image(systemName: "gift.fill")
                                            Text("Claim Rewards")
                                        }
                                    }
                                    .font(.system(size: 16, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(
                                        LinearGradient(
                                            colors: pendingRewards == "0" || isClaiming ?
                                                [Color.gray, Color.gray] :
                                                [Color.green, Color.green.opacity(0.7)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .foregroundColor(.white)
                                    .cornerRadius(14)
                                }
                                .disabled(pendingRewards == "0" || isClaiming)
                            }
                            .padding(20)
                            .background(Color.white)
                            .cornerRadius(20)
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                            .padding(.horizontal, 20)
                        }
                        
                        // My Memes Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("My Memes (\(userMemes.count))")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 20)
                            
                            if isLoading {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            } else if userMemes.isEmpty {
                                VStack(spacing: 8) {
                                    Image(systemName: "photo.on.rectangle.angled")
                                        .font(.system(size: 50))
                                        .foregroundColor(.gray)
                                    Text("No memes yet")
                                        .font(.system(size: 16))
                                        .foregroundColor(.secondary)
                                    Text("Start uploading to see them here")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(40)
                                .background(Color.white)
                                .cornerRadius(20)
                                .padding(.horizontal, 20)
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(userMemes) { meme in
                                            NavigationLink(destination: MemeDetailView(meme: meme)) {
                                                MemeCard(meme: meme)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                        }
                        
                        // Sign Out Button
                        Button(action: {
                            authManager.signOut()
                            walletManager.disconnectWallet()
                        }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Sign Out")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.white)
                            .foregroundColor(.red)
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await loadProfile()
            }
        }
    }
    
    func loadProfile() async {
        guard let address = walletManager.walletAddress else { return }
        
        isLoading = true
        
        do {
            // Load user's memes
            userMemes = try await APIService.shared.fetchUserMemes(address: address)
            
            // Load rewards
            let rewards = try await APIService.shared.fetchRewards(address: address)
            pendingRewards = rewards.pendingRewards
            totalEarned = rewards.totalEarned
        } catch {
            print("Failed to load profile: \(error)")
        }
        
        isLoading = false
    }
    
    func claimRewards() async {
        isClaiming = true
        
        do {
            try await walletManager.claimRewards()
            await loadProfile() // Refresh rewards
        } catch {
            print("Failed to claim rewards: \(error)")
        }
        
        isClaiming = false
    }
}

// Custom Meme Card Component
struct MemeCard: View {
    let meme: Meme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: URL(string: meme.imageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        ProgressView()
                    )
            }
            .frame(width: 160, height: 160)
            .clipped()
            .cornerRadius(16)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(meme.caption)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .frame(width: 160, alignment: .leading)
                
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                        Text("\(meme.likes)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                        Text("\(meme.commentCount)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .frame(width: 160)
        .padding(12)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}
