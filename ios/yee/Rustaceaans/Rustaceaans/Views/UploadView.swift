import SwiftUI
import PhotosUI

struct UploadView: View {
    @EnvironmentObject var walletManager: WalletManager
    @State private var selectedImage: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var caption = ""
    @State private var tags = ""
    @State private var isUploading = false
    @State private var showSuccess = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section("Select Image") {
                    PhotosPicker(selection: $selectedImage, matching: .images) {
                        if let imageData = selectedImageData,
                           let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 200)
                        } else {
                            Label("Choose Photo", systemImage: "photo")
                        }
                    }
                    .onChange(of: selectedImage) { newValue in
                        Task {
                            if let data = try? await newValue?.loadTransferable(type: Data.self) {
                                selectedImageData = data
                            }
                        }
                    }
                }
                
                Section("Meme Details") {
                    TextField("Caption", text: $caption)
                    TextField("Tags (comma separated)", text: $tags)
                }
                
                Section {
                    if !walletManager.isConnected {
                        Button("Connect Wallet First") {
                            walletManager.connectWallet()
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        Button(action: {
                            Task {
                                await uploadMeme()
                            }
                        }) {
                            if isUploading {
                                HStack {
                                    ProgressView()
                                    Text("Uploading...")
                                }
                            } else {
                                Text("Upload Meme")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .disabled(selectedImageData == nil || caption.isEmpty || isUploading)
                    }
                }
                
                if showSuccess {
                    Section {
                        Text("✅ Meme uploaded successfully!")
                            .foregroundColor(.green)
                    }
                }
                
                if let error = errorMessage {
                    Section {
                        Text("❌ \(error)")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Upload Meme")
        }
    }
    
    func uploadMeme() async {
        guard let imageData = selectedImageData,
              let image = UIImage(data: imageData),
              let address = walletManager.walletAddress else {
            return
        }
        
        isUploading = true
        errorMessage = nil
        
        do {
            let tagArray = tags.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
            
            let response = try await APIService.shared.uploadMeme(
                image: image,
                caption: caption,
                tags: tagArray,
                walletAddress: address
            )
            
            if response.success {
                showSuccess = true
                
                // Reset form
                selectedImage = nil
                selectedImageData = nil
                caption = ""
                tags = ""
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    showSuccess = false
                }
            } else {
                errorMessage = response.message ?? "Upload failed"
            }
        } catch {
            errorMessage = "Failed to upload: \(error.localizedDescription)"
        }
        
        isUploading = false
    }
}
