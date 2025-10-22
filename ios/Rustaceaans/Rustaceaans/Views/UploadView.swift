import SwiftUI
import PhotosUI

struct UploadView: View {
    @EnvironmentObject var walletManager: WalletManager
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedImage: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var caption = ""
    @State private var tags = ""
    @State private var isUploading = false
    @State private var uploadProgress: Double = 0.0
    @State private var showSuccess = false
    @State private var errorMessage: String?
    
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
                    VStack(spacing: 24) {
                        // Image Picker Card
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Select Image")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            PhotosPicker(selection: $selectedImage, matching: .images) {
                                if let imageData = selectedImageData,
                                   let uiImage = UIImage(data: imageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 300)
                                        .clipped()
                                        .cornerRadius(16)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(
                                                    LinearGradient(
                                                        colors: [
                                                            Color(red: 0.5, green: 0.2, blue: 0.6),
                                                            Color(red: 0.8, green: 0.3, blue: 0.5)
                                                        ],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ),
                                                    lineWidth: 3
                                                )
                                        )
                                } else {
                                    VStack(spacing: 16) {
                                        Image(systemName: "photo.on.rectangle.angled")
                                            .font(.system(size: 60))
                                            .foregroundStyle(
                                                LinearGradient(
                                                    colors: [
                                                        Color(red: 0.5, green: 0.2, blue: 0.6),
                                                        Color(red: 0.8, green: 0.3, blue: 0.5)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                        
                                        Text("Tap to choose a photo")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 250)
                                    .background(Color.white)
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [10]))
                                    )
                                }
                            }
                            .onChange(of: selectedImage) { _, newValue in
                                Task {
                                    if let data = try? await newValue?.loadTransferable(type: Data.self) {
                                        selectedImageData = data
                                        errorMessage = nil
                                    }
                                }
                            }
                        }
                        .padding(20)
                        .background(Color.white.opacity(0.7))
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Details Card
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Meme Details")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Caption")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                TextField("Add a catchy caption...", text: $caption)
                                    .font(.system(size: 16))
                                    .padding(14)
                                    .background(Color(red: 0.95, green: 0.95, blue: 0.97))
                                    .cornerRadius(12)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Tags (optional)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                TextField("funny, crypto, meme", text: $tags)
                                    .font(.system(size: 16))
                                    .padding(14)
                                    .background(Color(red: 0.95, green: 0.95, blue: 0.97))
                                    .cornerRadius(12)
                            }
                        }
                        .padding(20)
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                        .padding(.horizontal, 20)
                        
                        // Upload Button Card
                        VStack(spacing: 16) {
                            if !walletManager.isConnected {
                                Button(action: {
                                    walletManager.connectWallet(with: authManager)
                                }) {
                                    HStack {
                                        Image(systemName: "wallet.pass.fill")
                                        Text("Connect Wallet to Upload")
                                            .font(.system(size: 17, weight: .semibold))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(
                                        LinearGradient(
                                            colors: [Color.orange, Color.orange.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .foregroundColor(.white)
                                    .cornerRadius(16)
                                }
                            } else {
                                Button(action: {
                                    Task {
                                        await uploadMeme()
                                    }
                                }) {
                                    HStack(spacing: 12) {
                                        if isUploading {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            Text("Uploading...")
                                        } else {
                                            Image(systemName: "arrow.up.circle.fill")
                                                .font(.system(size: 20))
                                            Text("Upload Meme")
                                        }
                                    }
                                    .font(.system(size: 17, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(
                                        LinearGradient(
                                            colors: (selectedImageData == nil || caption.isEmpty || isUploading) ?
                                                [Color.gray, Color.gray] :
                                                [
                                                    Color(red: 0.5, green: 0.2, blue: 0.6),
                                                    Color(red: 0.8, green: 0.3, blue: 0.5)
                                                ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .foregroundColor(.white)
                                    .cornerRadius(16)
                                    .shadow(color: Color.purple.opacity(0.3), radius: 10, x: 0, y: 5)
                                }
                                .disabled(selectedImageData == nil || caption.isEmpty || isUploading)
                            }
                            
                            // Progress bar
                            if isUploading {
                                VStack(spacing: 8) {
                                    ProgressView(value: uploadProgress, total: 1.0)
                                        .progressViewStyle(LinearProgressViewStyle(tint: Color(red: 0.5, green: 0.2, blue: 0.6)))
                                    
                                    Text("Compressing and uploading your meme...")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(20)
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                        .padding(.horizontal, 20)
                        
                        // Success/Error Messages
                        if showSuccess {
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.green)
                                Text("Meme uploaded successfully!")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(16)
                            .padding(.horizontal, 20)
                        }
                        
                        if let error = errorMessage {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.red)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Upload Failed")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.primary)
                                    Text(error)
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(16)
                            .padding(.horizontal, 20)
                        }
                        
                        Spacer()
                            .frame(height: 40)
                    }
                }
            }
            .navigationTitle("Upload Meme")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    func uploadMeme() async {
        guard let imageData = selectedImageData,
              let image = UIImage(data: imageData),
              let address = walletManager.walletAddress else {
            errorMessage = "Please select an image and connect your wallet"
            return
        }
        
        isUploading = true
        errorMessage = nil
        uploadProgress = 0.0
        
        // Simulate progress for better UX
        let progressTask = Task {
            for i in 1...5 {
                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                await MainActor.run {
                    uploadProgress = Double(i) * 0.15 // Get to 75% before actual upload completes
                }
            }
        }
        
        do {
            let tagArray = tags.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
            
            let uploadedMeme = try await APIService.shared.uploadMeme(
                image: image,
                caption: caption,
                tags: tagArray,
                walletAddress: address
            )
            
            progressTask.cancel()
            uploadProgress = 1.0
            
            // Successfully uploaded meme
            print("✅ Meme uploaded successfully! ID: \(uploadedMeme.id)")
            withAnimation(.spring()) {
                showSuccess = true
            }
            
            // Reset form
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                selectedImage = nil
                selectedImageData = nil
                caption = ""
                tags = ""
                uploadProgress = 0.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                withAnimation {
                    showSuccess = false
                }
            }
        } catch let error as URLError {
            progressTask.cancel()
            withAnimation {
                switch error.code {
                case .timedOut:
                    errorMessage = "Upload timed out. Please check your connection and try again."
                case .notConnectedToInternet:
                    errorMessage = "No internet connection. Please check your network."
                case .cannotConnectToHost:
                    errorMessage = "Cannot connect to server. Please check the API URL."
                default:
                    errorMessage = "Network error: \(error.localizedDescription)"
                }
            }
        } catch {
            progressTask.cancel()
            withAnimation {
                errorMessage = "Failed to upload: \(error.localizedDescription)"
            }
        }
        
        isUploading = false
    }
}
