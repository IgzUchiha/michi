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
            List {
                // User info
                Section("Account") {
                    if let name = authManager.userName {
                        HStack {
                            Text("Name")
                            Spacer()
                            Text(name)
                                .foregroundColor(.secondary)
                        }
                    }
                    if let email = authManager.userEmail {
                        HStack {
                            Text("Email")
                            Spacer()
                            Text(email)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Wallet section
                Section("Wallet") {
                    if walletManager.isConnected {
                        HStack {
                            Text("Address")
                            Spacer()
                            Text(walletManager.walletAddress?.prefix(10) ?? "" + "...")
                                .foregroundColor(.secondary)
                        }
                        
                        Button("Disconnect Wallet") {
                            walletManager.disconnectWallet()
                        }
                        .foregroundColor(.red)
                    } else {
                        Button("Connect Wallet") {
                            walletManager.connectWallet()
                        }
                    }
                }
                
                // Rewards section
                if walletManager.isConnected {
                    Section("Rewards") {
                        HStack {
                            Text("Pending Rewards")
                            Spacer()
                            Text("\(pendingRewards) ETH")
                                .foregroundColor(.green)
                        }
                        
                        HStack {
                            Text("Total Earned")
                            Spacer()
                            Text("\(totalEarned) ETH")
                                .foregroundColor(.secondary)
                        }
                        
                        Button(action: {
                            Task {
                                await claimRewards()
                            }
                        }) {
                            if isClaiming {
                                HStack {
                                    ProgressView()
                                    Text("Claiming...")
                                }
                            } else {
                                Text("Claim Rewards")
                            }
                        }
                        .disabled(pendingRewards == "0" || isClaiming)
                    }
                }
                
                // User's memes
                Section("My Memes (\(userMemes.count))") {
                    if isLoading {
                        ProgressView()
                    } else if userMemes.isEmpty {
                        Text("No memes yet")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(userMemes) { meme in
                            NavigationLink(destination: MemeDetailView(meme: meme)) {
                                HStack {
                                    AsyncImage(url: URL(string: meme.imageUrl)) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.3))
                                    }
                                    .frame(width: 60, height: 60)
                                    .clipped()
                                    .cornerRadius(8)
                                    
                                    VStack(alignment: .leading) {
                                        Text(meme.caption)
                                            .lineLimit(1)
                                        HStack {
                                            Image(systemName: "heart.fill")
                                                .foregroundColor(.red)
                                            Text("\(meme.likes)")
                                        }
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Sign out
                Section {
                    Button("Sign Out") {
                        authManager.signOut()
                        walletManager.disconnectWallet()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Profile")
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
