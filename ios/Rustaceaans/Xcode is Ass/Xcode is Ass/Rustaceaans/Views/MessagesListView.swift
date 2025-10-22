import SwiftUI

struct MessagesListView: View {
    @StateObject private var messagesManager = MessagesManager()
    @EnvironmentObject var walletManager: WalletManager
    @State private var showingNewMessageSheet = false
    @State private var newMessageAddress = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color(hex: "F8F8F9"), Color(hex: "E6EBF0")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                if messagesManager.conversations.isEmpty && !messagesManager.isLoading {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "message.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.purple.opacity(0.3))
                        
                        Text("No Messages Yet")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Start a conversation by sharing\nmemes with other users!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button(action: { showingNewMessageSheet = true }) {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                Text("New Message")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "7f33a5"), Color(hex: "cc4d80")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(25)
                            .shadow(color: Color.purple.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                    }
                    .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(messagesManager.conversations) { conversation in
                                NavigationLink(destination: ChatView(
                                    conversation: conversation,
                                    messagesManager: messagesManager
                                )) {
                                    VStack(spacing: 0) {
                                        InstagramStyleConversationRow(conversation: conversation)
                                        
                                        Divider()
                                            .padding(.leading, 80)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .refreshable {
                        await loadConversations()
                    }
                }
                
                if messagesManager.isLoading {
                    ProgressView()
                }
            }
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNewMessageSheet = true }) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.purple)
                    }
                }
            }
            .sheet(isPresented: $showingNewMessageSheet) {
                NewMessageSheet(
                    messagesManager: messagesManager,
                    walletManager: walletManager,
                    isPresented: $showingNewMessageSheet
                )
            }
            .task {
                await loadConversations()
            }
        }
    }
    
    private func loadConversations() async {
        guard let userId = walletManager.walletAddress else {
            print("⚠️ No wallet connected")
            return
        }
        
        await messagesManager.loadConversations(for: userId)
    }
}

// MARK: - Instagram-Style Conversation Row

struct InstagramStyleConversationRow: View {
    let conversation: Conversation
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar (Instagram style - simple circle)
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "7f33a5"), Color(hex: "cc4d80")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 56, height: 56)
                .overlay(
                    Text(conversation.displayName.prefix(1).uppercased())
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                )
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                // Name and time
                HStack {
                    Text(conversation.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if let lastMsg = conversation.lastMessage {
                        Text(lastMsg.formattedTime)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                
                // Last message preview
                HStack {
                    Text(conversation.lastMessagePreview)
                        .font(.system(size: 15))
                        .foregroundColor(conversation.unreadCount > 0 ? .primary : .secondary)
                        .fontWeight(conversation.unreadCount > 0 ? .medium : .regular)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if conversation.unreadCount > 0 {
                        Circle()
                            .fill(Color(hex: "7f33a5"))
                            .frame(width: 8, height: 8)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
    }
}

// MARK: - New Message Sheet

struct NewMessageSheet: View {
    @ObservedObject var messagesManager: MessagesManager
    @ObservedObject var walletManager: WalletManager
    @Binding var isPresented: Bool
    
    @State private var searchQuery = ""
    @State private var searchResults: [User] = []
    @State private var allUsers: [User] = []
    @State private var isSearching = false
    @State private var selectedUser: User?
    @State private var messageText = ""
    @State private var isSending = false
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
                    // Search for users
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Search users:")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            TextField("Name or email", text: $searchQuery)
                                .textFieldStyle(PlainTextFieldStyle())
                                .autocapitalization(.none)
                                .onChange(of: searchQuery) {
                                    performSearch()
                                }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        
                        // Search results or all users
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(searchQuery.isEmpty ? allUsers : searchResults) { user in
                                    Button(action: {
                                        selectedUser = user
                                        searchQuery = ""
                                    }) {
                                        HStack(spacing: 12) {
                                            Circle()
                                                .fill(Color.purple.opacity(0.3))
                                                .frame(width: 44, height: 44)
                                                .overlay(
                                                    Text(user.displayName.prefix(1))
                                                        .font(.headline)
                                                        .foregroundColor(.purple)
                                                )
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(user.displayName)
                                                    .font(.subheadline)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.primary)
                                                
                                                if let email = user.email {
                                                    Text(email)
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.right")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        .padding()
                                        .background(Color.white)
                                        .cornerRadius(12)
                                    }
                                }
                            }
                        }
                        .frame(maxHeight: 200)
                    }
                    
                    // Selected user
                    if let user = selectedUser {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Sending to:")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(Color.purple.opacity(0.3))
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Text(user.displayName.prefix(1))
                                            .font(.headline)
                                            .foregroundColor(.purple)
                                    )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(user.displayName)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    
                                    if let email = user.email {
                                        Text(email)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Button(action: { selectedUser = nil }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                    }
                    
                    // Message field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Message:")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        TextEditor(text: $messageText)
                            .frame(minHeight: 120)
                            .padding(8)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                    
                    Spacer()
                    
                    // Send button
                    Button(action: sendMessage) {
                        HStack(spacing: 12) {
                            if isSending {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 20))
                            }
                            Text("Send")
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
                    .disabled(selectedUser == nil || messageText.isEmpty || isSending)
                    .opacity((selectedUser == nil || messageText.isEmpty || isSending) ? 0.6 : 1.0)
                }
                .padding()
            }
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
            .task {
                await loadUsers()
            }
        }
    }
    
    private func loadUsers() async {
        do {
            allUsers = try await APIService.shared.getAllUsers()
            // Filter out current user
            if let myWallet = walletManager.walletAddress {
                allUsers = allUsers.filter { $0.walletAddress != myWallet }
            }
        } catch {
            print("❌ Failed to load users: \(error)")
        }
    }
    
    private func performSearch() {
        guard !searchQuery.isEmpty else {
            searchResults = []
            return
        }
        
        Task {
            do {
                var results = try await APIService.shared.searchUsers(query: searchQuery)
                // Filter out current user
                if let myWallet = walletManager.walletAddress {
                    results = results.filter { $0.walletAddress != myWallet }
                }
                await MainActor.run {
                    searchResults = results
                }
            } catch {
                print("❌ Search failed: \(error)")
            }
        }
    }
    
    private func sendMessage() {
        guard let senderId = walletManager.walletAddress else {
            errorMessage = "No wallet connected"
            return
        }
        
        guard let recipient = selectedUser else {
            errorMessage = "Please select a user"
            return
        }
        
        guard !messageText.isEmpty else {
            errorMessage = "Please enter a message"
            return
        }
        
        isSending = true
        errorMessage = nil
        
        Task {
            do {
                try await messagesManager.sendTextMessage(
                    messageText,
                    from: senderId,
                    to: recipient.walletAddress
                )
                
                await MainActor.run {
                    isSending = false
                    isPresented = false
                }
            } catch {
                await MainActor.run {
                    isSending = false
                    errorMessage = "Failed to send: \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
