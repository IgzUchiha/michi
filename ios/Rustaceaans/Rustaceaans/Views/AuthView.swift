import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var walletManager: WalletManager
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var showingEmailSignIn = false
    
    var body: some View {
        ZStack {
            // Gradient Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.2, green: 0.1, blue: 0.5),
                    Color(red: 0.5, green: 0.2, blue: 0.6),
                    Color(red: 0.8, green: 0.3, blue: 0.5)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Animated floating elements
            GeometryReader { geometry in
                ForEach(0..<20) { index in
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: CGFloat.random(in: 20...100))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                        .blur(radius: 5)
                }
            }
            
            VStack(spacing: 40) {
                Spacer()
                
                // Logo with animation
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 140, height: 140)
                            .blur(radius: 10)
                        
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 70, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, .white.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    
                    VStack(spacing: 8) {
                        Text("Rustaceaans")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Share memes, earn crypto 🚀")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                
                Spacer()
                
                // Authentication info
                VStack(spacing: 12) {
                    Text("Secure Login")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                    
                    Text("Each user gets a unique EVM wallet address")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, 16)
                
                VStack(spacing: 16) {
                    // Email Sign In (Works immediately - no config needed)
                    Button(action: { showingEmailSignIn = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 20, weight: .semibold))
                            Text("Sign in with Email")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "7f33a5"), Color(hex: "cc4d80")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(color: Color.purple.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal, 32)
                    
                    // Sign in with Apple button with custom styling
                    SignInWithAppleButton(
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            handleSignIn(result: result)
                        }
                    )
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 56)
                    .cornerRadius(16)
                    .padding(.horizontal, 32)
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                }
                
                Spacer()
                    .frame(height: 60)
            }
            
            // Error alert
            if showError {
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.yellow)
                        Text(errorMessage)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(12)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .sheet(isPresented: $showingEmailSignIn) {
            EmailSignInSheet(
                authManager: authManager,
                walletManager: walletManager,
                isPresented: $showingEmailSignIn
            )
        }
    }
    
    private func handleSignIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                // Set OAuth credentials in authManager
                authManager.userId = appleIDCredential.user
                authManager.oauthProvider = "apple"
                authManager.userEmail = appleIDCredential.email ?? "user@privaterelay.appleid.com"
                authManager.userName = appleIDCredential.fullName?.givenName ?? "Apple User"
                authManager.isAuthenticated = true
                
                // Now connect wallet - this will generate unique address and register user
                walletManager.connectWallet(with: authManager)
                
                print("✅ User authenticated via Apple Sign In")
            }
        case .failure(let error):
            // Check if authManager has a more detailed error message
            let message = authManager.lastError ?? "Sign in failed: \(error.localizedDescription)"
            withAnimation {
                errorMessage = message
                showError = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                withAnimation {
                    showError = false
                }
            }
        }
    }
}

// MARK: - Email Sign In Sheet
struct EmailSignInSheet: View {
    @ObservedObject var authManager: AuthManager
    @ObservedObject var walletManager: WalletManager
    @Binding var isPresented: Bool
    
    @State private var email = ""
    @State private var name = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "F8F8F9"), Color(hex: "E6EBF0")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Info
                    VStack(spacing: 12) {
                        Image(systemName: "envelope.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.purple)
                        
                        Text("Sign in with Email")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Enter your email to create a unique account with an EVM wallet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 40)
                    
                    // Form
                    VStack(spacing: 16) {
                        // Email field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            
                            TextField("your@email.com", text: $email)
                                .textFieldStyle(PlainTextFieldStyle())
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        
                        // Name field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name (optional)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            
                            TextField("Your name", text: $name)
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                    }
                    .padding(.horizontal)
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                    
                    Spacer()
                    
                    // Sign in button
                    Button(action: signIn) {
                        HStack(spacing: 12) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 20))
                            }
                            Text(isLoading ? "Signing In..." : "Sign In")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "7f33a5"), Color(hex: "cc4d80")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: Color.purple.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .disabled(email.isEmpty || isLoading)
                    .opacity((email.isEmpty || isLoading) ? 0.6 : 1.0)
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Email Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private func signIn() {
        guard !email.isEmpty else {
            errorMessage = "Please enter your email"
            return
        }
        
        guard email.contains("@") && email.contains(".") else {
            errorMessage = "Please enter a valid email"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Create unique OAuth ID from email
        let oauthId = "email_" + email.lowercased()
        
        // Set auth credentials
        authManager.userId = oauthId
        authManager.oauthProvider = "email"
        authManager.userEmail = email
        authManager.userName = name.isEmpty ? nil : name
        authManager.isAuthenticated = true
        
        // Generate wallet and register user
        walletManager.connectWallet(with: authManager)
        
        print("✅ User signed in with email: \(email)")
        
        // Close sheet
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isPresented = false
        }
    }
}
