import Foundation
import AuthenticationServices

class AuthManager: NSObject, ObservableObject {
    @Published var isAuthenticated = false
    @Published var userEmail: String?
    @Published var userName: String?
    @Published var userId: String?  // OAuth provider user ID
    @Published var oauthProvider: String?  // "apple", "google", etc.
    @Published var lastError: String?
    
    // MARK: - Sign in with Apple (Real OAuth)
    func signInWithApple() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
    
    // MARK: - Sign in with Google (via Web3Auth)
    // This will be handled by WalletManager's Web3Auth integration
    
    // MARK: - Sign Out
    func signOut() {
        isAuthenticated = false
        userEmail = nil
        userName = nil
        userId = nil
        oauthProvider = nil
        lastError = nil
        print("✅ User signed out")
    }
}

// MARK: - ASAuthorizationControllerDelegate
extension AuthManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            DispatchQueue.main.async {
                // Store OAuth info
                self.userId = appleIDCredential.user  // Unique Apple ID
                self.oauthProvider = "apple"
                self.userEmail = appleIDCredential.email ?? "user@privaterelay.appleid.com"
                self.userName = appleIDCredential.fullName?.givenName ?? "Apple User"
                self.isAuthenticated = true
                self.lastError = nil
                
                print("✅ Sign in with Apple successful")
                print("OAuth ID: \(appleIDCredential.user)")
                print("Email: \(self.userEmail ?? "none")")
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        DispatchQueue.main.async {
            let nsError = error as NSError
            
            // Handle specific error codes
            if nsError.code == 1000 {
                // User cancelled or Sign in with Apple not configured
                self.lastError = "Sign in cancelled or not available. Please use Demo mode or configure Sign in with Apple in Xcode."
                print("⚠️ Apple Sign In Error 1000 - likely simulator limitation or missing capability")
                print("💡 Solution: Enable 'Sign in with Apple' capability in Xcode or use Demo mode")
            } else if nsError.code == 1001 {
                // User cancelled explicitly
                self.lastError = "Sign in cancelled by user"
                print("ℹ️ User cancelled Apple Sign In")
            } else {
                self.lastError = "Sign in failed: \(error.localizedDescription)"
                print("❌ Sign in with Apple failed: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension AuthManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Get the key window for iOS 13+
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        let window = windowScene?.windows.first
        return window ?? ASPresentationAnchor()
    }
}
