import Foundation
import Combine
import CryptoKit
// Uncomment after adding Web3Auth SDK via SPM:
// import Web3Auth

class WalletManager: ObservableObject {
    @Published var isConnected = false
    @Published var walletAddress: String?
    @Published var privateKey: String?
    @Published var userInfo: [String: Any]?
    
    private let contractAddress = "0xd1C2AceaA918b2E9eBE3e60Ad7B35618e7330486"
    
    // Web3Auth instance - uncomment after adding SDK
    // private var web3Auth: Web3Auth?
    
    // MARK: - Configuration
    // Replace with your actual Web3Auth Client ID from https://dashboard.web3auth.io
    private let web3AuthClientId = "BEJLnbxGvKH2o7iuQBNmz0HB_vDTJknX2Atx5hXtwGgky4C_grTEmHWKtu79TBBgYfFfD_9G8FVnJfTTeJG9ork"
    private let redirectUrl = "com.rustaceaans.app://auth" // Update with your bundle ID
    
    init() {
        // Initialize Web3Auth - uncomment after adding SDK
        /*
        web3Auth = Web3Auth(W3AInitParams(
            clientId: web3AuthClientId,
            network: .sapphire_mainnet, // Use .sapphire_devnet for testing
            redirectUrl: redirectUrl
        ))
        */
        
        // For demo purposes only - remove when Web3Auth is integrated
        print("⚠️ WalletManager: Using mock connection. Please integrate Web3Auth SDK.")
    }
    
    // MARK: - Web3Auth Integration
    func connectWallet(with authManager: AuthManager) {
        Task {
            await connectWithWeb3Auth(authManager: authManager)
        }
    }
    
    @MainActor
    private func connectWithWeb3Auth(authManager: AuthManager) async {
        // Uncomment when Web3Auth SDK is added:
        /*
        do {
            // Use the OAuth provider from AuthManager
            let loginProvider: Web3AuthProvider
            if authManager.oauthProvider == "apple" {
                loginProvider = .APPLE
            } else {
                loginProvider = .GOOGLE
            }
            
            let result = try await web3Auth?.login(
                W3ALoginParams(
                    loginProvider: loginProvider
                )
            )
            
            // Extract wallet information
            if let privKey = result?.privKey {
                self.privateKey = privKey
                self.walletAddress = try await deriveAddress(from: privKey)
                self.userInfo = result?.userInfo
                self.isConnected = true
                
                print("✅ Web3Auth login successful")
                print("Address: \(self.walletAddress ?? "unknown")")
            }
        } catch {
            print("❌ Web3Auth login failed: \(error.localizedDescription)")
            await mockConnect() // Fallback to mock for development
        }
        */
        
        // Temporary: Generate unique address from OAuth ID until Web3Auth SDK is added
        await generateUniqueWallet(authManager: authManager)
    }
    
    @MainActor
    private func generateUniqueWallet(authManager: AuthManager) async {
        guard let userId = authManager.userId,
              let provider = authManager.oauthProvider else {
            print("❌ No OAuth credentials available")
            return
        }
        
        // Generate deterministic wallet address from OAuth ID
        // This creates UNIQUE addresses for each user
        let combined = "\(provider)_\(userId)"
        let hash = combined.sha256Hash()
        let address = "0x" + String(hash.prefix(40))
        
        self.walletAddress = address
        self.isConnected = true
        
        print("✅ Unique wallet generated for OAuth user")
        print("Provider: \(provider)")
        print("Address: \(address)")
        
        // Register user with backend
        await registerUserWithBackend(authManager: authManager)
    }
    
    private func registerUserWithBackend(authManager: AuthManager) async {
        guard let walletAddress = self.walletAddress,
              let userId = authManager.userId,
              let provider = authManager.oauthProvider else {
            return
        }
        
        do {
            let user = try await APIService.shared.registerUser(
                walletAddress: walletAddress,
                email: authManager.userEmail,
                name: authManager.userName,
                oauthProvider: provider,
                oauthId: userId
            )
            print("✅ User registered with backend: \(user.displayName)")
        } catch {
            print("❌ Failed to register user: \(error)")
        }
    }
    
    func disconnectWallet() {
        // Uncomment when Web3Auth SDK is added:
        /*
        Task {
            do {
                try await web3Auth?.logout()
                await MainActor.run {
                    self.walletAddress = nil
                    self.privateKey = nil
                    self.userInfo = nil
                    self.isConnected = false
                }
                print("✅ Wallet disconnected")
            } catch {
                print("❌ Logout failed: \(error.localizedDescription)")
            }
        }
        */
        
        // Mock implementation
        walletAddress = nil
        privateKey = nil
        userInfo = nil
        isConnected = false
    }
    
    // MARK: - Smart Contract Interactions
    func sendTip(amount: String, to: String) async throws {
        guard self.privateKey != nil else {
            print("⚠️ Mock transaction: Would send \(amount) ETH to \(to)")
            try await Task.sleep(nanoseconds: 2_000_000_000)
            return
        }
        
        // TODO: Implement actual Web3 transaction
        // Use web3.swift or similar library to:
        // 1. Create transaction
        // 2. Sign with privateKey
        // 3. Send to blockchain
        try await Task.sleep(nanoseconds: 2_000_000_000)
    }
    
    func claimRewards() async throws {
        guard self.privateKey != nil else {
            print("⚠️ Mock transaction: Would claim rewards")
            try await Task.sleep(nanoseconds: 2_000_000_000)
            return
        }
        
        // TODO: Implement actual smart contract call
        try await Task.sleep(nanoseconds: 2_000_000_000)
    }
    
    // MARK: - Helper Functions
    private func deriveAddress(from privateKey: String) async throws -> String {
        // TODO: Derive Ethereum address from private key
        // This is a placeholder - implement proper key derivation
        return "0x" + String(privateKey.prefix(40))
    }
}

// MARK: - String SHA256 Extension
extension String {
    func sha256Hash() -> String {
        let data = Data(self.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
