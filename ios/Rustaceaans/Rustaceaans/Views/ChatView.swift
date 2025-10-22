import SwiftUI

struct ChatView: View {
    let conversation: Conversation
    @ObservedObject var messagesManager: MessagesManager
    @EnvironmentObject var walletManager: WalletManager
    
    @State private var messageText = ""
    @State private var showingMemeSelector = false
    @State private var isSending = false
    
    var body: some View {
        ZStack {
            // Background - Instagram style white
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Messages list
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(messagesManager.currentMessages) { message in
                                MessageBubble(
                                    message: message,
                                    isFromCurrentUser: message.senderId == walletManager.walletAddress
                                )
                                .id(message.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messagesManager.currentMessages.count) {
                        // Auto-scroll to bottom on new message
                        if let lastMessage = messagesManager.currentMessages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onAppear {
                        // Scroll to bottom when view appears
                        if let lastMessage = messagesManager.currentMessages.last {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Input bar
                VStack(spacing: 0) {
                    Divider()
                    
                    HStack(spacing: 12) {
                        // Meme share button
                        Button(action: { showingMemeSelector = true }) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 24))
                                .foregroundColor(.purple)
                        }
                        
                        // Text input
                        TextField("Message...", text: $messageText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color(.systemGray6))
                            .cornerRadius(20)
                        
                        // Send button
                        Button(action: sendMessage) {
                            ZStack {
                                Circle()
                                    .fill(
                                        messageText.isEmpty ?
                                        LinearGradient(
                                            colors: [Color.gray.opacity(0.3)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ) :
                                        LinearGradient(
                                            colors: [Color(hex: "7f33a5"), Color(hex: "cc4d80")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: 36, height: 36)
                                
                                if isSending {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.7)
                                } else {
                                    Image(systemName: "arrow.up")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .disabled(messageText.isEmpty || isSending)
                    }
                    .padding()
                    .background(Color.white)
                }
            }
        }
        .navigationTitle(conversation.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingMemeSelector) {
            MemeSelectorSheet(
                messagesManager: messagesManager,
                walletManager: walletManager,
                recipientId: conversation.otherUserId,
                isPresented: $showingMemeSelector
            )
        }
        .task {
            await loadMessages()
            startPolling()
        }
        .onDisappear {
            messagesManager.stopPolling()
        }
    }
    
    private func loadMessages() async {
        guard let currentUserId = walletManager.walletAddress else { return }
        await messagesManager.loadMessages(
            currentUserId: currentUserId,
            otherUserId: conversation.otherUserId
        )
    }
    
    private func startPolling() {
        guard let currentUserId = walletManager.walletAddress else { return }
        messagesManager.startPolling(
            currentUserId: currentUserId,
            otherUserId: conversation.otherUserId,
            interval: 3.0
        )
    }
    
    private func sendMessage() {
        guard let senderId = walletManager.walletAddress else { return }
        guard !messageText.isEmpty else { return }
        
        let text = messageText
        messageText = ""
        isSending = true
        
        Task {
            do {
                try await messagesManager.sendTextMessage(
                    text,
                    from: senderId,
                    to: conversation.otherUserId
                )
                await MainActor.run {
                    isSending = false
                }
            } catch {
                await MainActor.run {
                    isSending = false
                    messageText = text // Restore message on error
                }
                print("❌ Failed to send message: \(error)")
            }
        }
    }
}

// MARK: - Instagram-Style Message Bubble

struct MessageBubble: View {
    let message: Message
    let isFromCurrentUser: Bool
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isFromCurrentUser { Spacer(minLength: 80) }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 2) {
                // Message content based on type
                switch message.content.type {
                case .text:
                    if let text = message.content.text {
                        Text(text)
                            .font(.system(size: 16))
                            .foregroundColor(isFromCurrentUser ? .white : .primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                isFromCurrentUser ?
                                LinearGradient(
                                    colors: [Color(hex: "7f33a5"), Color(hex: "cc4d80")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) :
                                LinearGradient(
                                    colors: [Color(hex: "F0F0F0")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    }
                    
                case .meme:
                    MemeMessageContent(message: message, isFromCurrentUser: isFromCurrentUser)
                    
                case .image:
                    if let mediaUrl = message.content.mediaUrl {
                        AsyncImage(url: URL(string: mediaUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(maxWidth: 250, maxHeight: 250)
                                .clipped()
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 250, height: 250)
                                .overlay(ProgressView())
                        }
                        .cornerRadius(18)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    }
                    
                case .video:
                    VStack(spacing: 8) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                        Text("Video")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    .frame(width: 200, height: 150)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(18)
                }
                
                // Timestamp
                Text(message.formattedTime)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if !isFromCurrentUser { Spacer(minLength: 60) }
        }
    }
}

// MARK: - Meme Message Content

struct MemeMessageContent: View {
    let message: Message
    let isFromCurrentUser: Bool
    @State private var meme: Meme?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let memeUrl = message.content.mediaUrl {
                AsyncImage(url: URL(string: memeUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: 250, maxHeight: 250)
                        .clipped()
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 250, height: 250)
                        .overlay(ProgressView())
                }
            }
            
            if let text = message.content.text {
                Text(text)
                    .font(.caption)
                    .foregroundColor(isFromCurrentUser ? .white.opacity(0.9) : .secondary)
                    .padding(.horizontal, 8)
            }
        }
        .padding(8)
        .background(
            isFromCurrentUser ?
            LinearGradient(
                colors: [Color(hex: "7f33a5"), Color(hex: "cc4d80")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ) :
            LinearGradient(
                colors: [Color(.systemGray5)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Meme Selector Sheet

struct MemeSelectorSheet: View {
    @ObservedObject var messagesManager: MessagesManager
    @ObservedObject var walletManager: WalletManager
    let recipientId: String
    @Binding var isPresented: Bool
    
    @State private var memes: [Meme] = []
    @State private var isLoading = true
    @State private var isSending = false
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "F8F8F9"), Color(hex: "E6EBF0")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                if isLoading {
                    ProgressView("Loading memes...")
                } else if memes.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No memes available")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ForEach(memes) { meme in
                                Button(action: {
                                    shareMeme(meme)
                                }) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        AsyncImage(url: URL(string: meme.imageUrl)) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Rectangle()
                                                .fill(Color.gray.opacity(0.2))
                                                .overlay(ProgressView())
                                        }
                                        .frame(height: 180)
                                        .clipped()
                                        .cornerRadius(12)
                                        
                                        Text(meme.caption)
                                            .font(.caption)
                                            .foregroundColor(.primary)
                                            .lineLimit(2)
                                    }
                                    .padding(8)
                                    .background(Color.white)
                                    .cornerRadius(16)
                                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                                }
                                .disabled(isSending)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Share a Meme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
            .task {
                await loadMemes()
            }
        }
    }
    
    private func loadMemes() async {
        do {
            memes = try await APIService.shared.fetchMemes()
            isLoading = false
        } catch {
            print("❌ Failed to load memes: \(error)")
            isLoading = false
        }
    }
    
    private func shareMeme(_ meme: Meme) {
        guard let senderId = walletManager.walletAddress else { return }
        
        isSending = true
        
        Task {
            do {
                try await messagesManager.sendMeme(
                    meme,
                    from: senderId,
                    to: recipientId
                )
                
                await MainActor.run {
                    isSending = false
                    isPresented = false
                }
            } catch {
                await MainActor.run {
                    isSending = false
                }
                print("❌ Failed to share meme: \(error)")
            }
        }
    }
}
