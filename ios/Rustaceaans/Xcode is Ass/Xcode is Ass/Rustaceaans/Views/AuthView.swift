import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Logo
            Image(systemName: "photo.stack.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("Rust Meme")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Share memes, earn crypto")
                .font(.title3)
                .foregroundColor(.secondary)
            
            Spacer()
            
            // Demo mode button for simulator
            Button(action: {
                authManager.userEmail = "demo@rustmeme.com"
                authManager.userName = "Demo User"
                authManager.isAuthenticated = true
            }) {
                HStack {
                    Image(systemName: "person.circle.fill")
                    Text("Continue as Demo User")
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.horizontal, 40)
            
            // Sign in with Apple button
            SignInWithAppleButton(
                onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                },
                onCompletion: { result in
                    switch result {
                    case .success(let authorization):
                        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                            authManager.userEmail = appleIDCredential.email
                            authManager.userName = appleIDCredential.fullName?.givenName
                            authManager.isAuthenticated = true
                        }
                    case .failure(let error):
                        print("Sign in failed: \(error.localizedDescription)")
                    }
                }
            )
            .frame(height: 50)
            .cornerRadius(10)
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding()
    }
}
