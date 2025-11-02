use std::env;
use std::path::Path;
use uuid::Uuid;

pub enum StorageBackend {
    S3(S3Storage),
    Local(LocalStorage),
}

pub struct S3Storage {
    client: aws_sdk_s3::Client,
    bucket: String,
    region: String,
}

pub struct LocalStorage {
    upload_dir: String,
}

impl StorageBackend {
    pub async fn new() -> Self {
        let storage_type = env::var("STORAGE_TYPE").unwrap_or_else(|_| "local".to_string());
        
        match storage_type.as_str() {
            "s3" => {
                println!("☁️ Using S3 storage");
                let config = aws_config::load_from_env().await;
                let client = aws_sdk_s3::Client::new(&config);
                let bucket = env::var("S3_BUCKET").expect("S3_BUCKET must be set");
                let region = env::var("AWS_REGION").unwrap_or_else(|_| "us-east-1".to_string());
                
                StorageBackend::S3(S3Storage {
                    client,
                    bucket,
                    region,
                })
            }
            _ => {
                println!("📁 Using local storage");
                let upload_dir = env::var("UPLOAD_DIR").unwrap_or_else(|_| "./uploads".to_string());
                StorageBackend::Local(LocalStorage { upload_dir })
            }
        }
    }
    
    pub async fn upload_file(&self, data: &[u8], filename: &str) -> Result<String, String> {
        match self {
            StorageBackend::S3(s3) => s3.upload_file(data, filename).await,
            StorageBackend::Local(local) => local.upload_file(data, filename).await,
        }
    }
    
    pub async fn delete_file(&self, url: &str) -> Result<(), String> {
        match self {
            StorageBackend::S3(s3) => s3.delete_file(url).await,
            StorageBackend::Local(local) => local.delete_file(url).await,
        }
    }
}

impl S3Storage {
    async fn upload_file(&self, data: &[u8], filename: &str) -> Result<String, String> {
        let key = format!("uploads/{}", filename);
        
        self.client
            .put_object()
            .bucket(&self.bucket)
            .key(&key)
            .body(data.to_vec().into())
            .content_type(Self::get_content_type(filename))
            .send()
            .await
            .map_err(|e| format!("Failed to upload to S3: {}", e))?;
        
        // Return public URL
        let url = format!(
            "https://{}.s3.{}.amazonaws.com/{}",
            self.bucket, self.region, key
        );
        
        Ok(url)
    }
    
    async fn delete_file(&self, url: &str) -> Result<(), String> {
        // Extract key from URL
        let key = url.split("/").last().unwrap_or("");
        
        self.client
            .delete_object()
            .bucket(&self.bucket)
            .key(key)
            .send()
            .await
            .map_err(|e| format!("Failed to delete from S3: {}", e))?;
        
        Ok(())
    }
    
    fn get_content_type(filename: &str) -> &'static str {
        let extension = Path::new(filename)
            .extension()
            .and_then(|s| s.to_str())
            .unwrap_or("");
        
        match extension.to_lowercase().as_str() {
            "jpg" | "jpeg" => "image/jpeg",
            "png" => "image/png",
            "gif" => "image/gif",
            "webp" => "image/webp",
            _ => "application/octet-stream",
        }
    }
}

impl LocalStorage {
    async fn upload_file(&self, data: &[u8], filename: &str) -> Result<String, String> {
        use std::io::Write;
        
        // Create uploads directory if it doesn't exist
        std::fs::create_dir_all(&self.upload_dir)
            .map_err(|e| format!("Failed to create upload directory: {}", e))?;
        
        let file_path = format!("{}/{}", self.upload_dir, filename);
        
        let mut file = std::fs::File::create(&file_path)
            .map_err(|e| format!("Failed to create file: {}", e))?;
        
        file.write_all(data)
            .map_err(|e| format!("Failed to write file: {}", e))?;
        
        // Return URL (assumes server is serving /uploads)
        let base_url = env::var("API_BASE_URL")
            .unwrap_or_else(|_| "http://127.0.0.1:8000".to_string());
        
        Ok(format!("{}/uploads/{}", base_url, filename))
    }
    
    async fn delete_file(&self, url: &str) -> Result<(), String> {
        // Extract filename from URL
        let filename = url.split("/").last().unwrap_or("");
        let file_path = format!("{}/{}", self.upload_dir, filename);
        
        std::fs::remove_file(&file_path)
            .map_err(|e| format!("Failed to delete file: {}", e))?;
        
        Ok(())
    }
}

// Helper function to generate unique filenames
pub fn generate_filename(original: &str) -> String {
    let extension = Path::new(original)
        .extension()
        .and_then(|s| s.to_str())
        .unwrap_or("jpg");
    
    format!("{}_{}.{}", Uuid::new_v4(), chrono::Utc::now().timestamp(), extension)
}
