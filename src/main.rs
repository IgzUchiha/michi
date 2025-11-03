use actix_web::{web, App, HttpResponse, HttpServer, Responder, middleware};
use actix_cors::Cors;
use actix_files as fs;
use actix_multipart::Multipart;
use actix_web_httpauth::middleware::HttpAuthentication;
use futures_util::stream::StreamExt as _;
use serde::{Deserialize, Serialize};
use sqlx::postgres::PgPoolOptions;
use std::io::Write;
use std::sync::Mutex;
use std::collections::HashMap;

// Authentication module
mod auth;

// MARK: - User Models
#[derive(Serialize, Deserialize, Clone)]
pub struct User {
    pub wallet_address: String,
    pub email: Option<String>,
    pub name: Option<String>,
    pub profile_picture: Option<String>,
    pub bio: Option<String>,
    pub oauth_provider: String, // "google", "apple", "email"
    pub oauth_id: String,       // Unique ID from OAuth provider
    pub created_at: String,
    #[serde(default)]
    pub followers_count: i32,
    #[serde(default)]
    pub following_count: i32,
}

#[derive(Serialize, Deserialize)]
pub struct RegisterUserRequest {
    pub wallet_address: String,
    pub email: Option<String>,
    pub name: Option<String>,
    pub profile_picture: Option<String>,
    pub bio: Option<String>,
    pub oauth_provider: String,
    pub oauth_id: String,
}

#[derive(Serialize, Deserialize)]
pub struct UpdateProfileRequest {
    pub name: Option<String>,
    pub bio: Option<String>,
    pub profile_picture: Option<String>,
}

#[derive(Serialize, Deserialize)]
pub struct SearchUsersRequest {
    pub query: String, // Search by email or name
}

#[derive(Serialize, Deserialize, Clone)]
pub struct Meme {
    id: i32,
    caption: String,
    tags: String,
    image: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    video: Option<String>,
    #[serde(default)]
    media_type: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    evm_address: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    user: Option<User>,
    #[serde(default)]
    likes: i32,
    #[serde(default)]
    comment_count: i32,
    #[serde(default)]
    is_liked: bool,
    created_at: String,
}

// Comment Models
#[derive(Serialize, Deserialize, Clone)]
pub struct Comment {
    id: i32,
    post_id: i32,
    user_id: String,
    user: Option<User>,
    text: String,
    created_at: String,
    likes: i32,
    is_liked: bool,
}

#[derive(Serialize, Deserialize)]
pub struct AddCommentRequest {
    user_id: String,
    text: String,
}

// Follow Models
#[derive(Serialize, Deserialize, Clone)]
pub struct Follow {
    follower_id: String,
    following_id: String,
    created_at: String,
}

#[derive(Serialize, Deserialize)]
pub struct FollowRequest {
    follower_id: String,
    following_id: String,
}

// MARK: - Message Models
#[derive(Serialize, Deserialize, Clone, Debug)]
#[serde(rename_all = "lowercase")]
pub enum MessageContentType {
    Text,
    Meme,
    Image,
    Video,
}

#[derive(Serialize, Deserialize, Clone)]
pub struct MessageContent {
    #[serde(rename = "type")]
    content_type: MessageContentType,
    #[serde(skip_serializing_if = "Option::is_none")]
    text: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    meme_id: Option<i32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    media_url: Option<String>,
}

#[derive(Serialize, Deserialize, Clone)]
pub struct Message {
    id: i32,
    sender_id: String,
    receiver_id: String,
    content: MessageContent,
    timestamp: String,
    is_read: bool,
}

#[derive(Serialize, Deserialize)]
pub struct SendMessageRequest {
    sender_id: String,
    receiver_id: String,
    content: MessageContent,
}

#[derive(Serialize, Deserialize)]
pub struct Conversation {
    id: String,
    other_user_id: String,
    other_user_name: Option<String>,
    last_message: Option<Message>,
    unread_count: i32,
    updated_at: String,
}

// In-memory storage for demo purposes
struct AppState {
    memes: Mutex<Vec<Meme>>,
    next_id: Mutex<i32>,
    messages: Mutex<Vec<Message>>,
    next_message_id: Mutex<i32>,
    users: Mutex<Vec<User>>,
    comments: Mutex<Vec<Comment>>,
    next_comment_id: Mutex<i32>,
    follows: Mutex<Vec<Follow>>,
}

async fn get_memes(data: web::Data<AppState>) -> impl Responder {
    let memes = data.memes.lock().unwrap();
    let mut sorted_memes = memes.clone();
    // Sort by popularity: likes + comment_count (descending)
    sorted_memes.sort_by(|a, b| {
        let score_a = a.likes + a.comment_count;
        let score_b = b.likes + b.comment_count;
        score_b.cmp(&score_a)
    });
    HttpResponse::Ok().json(sorted_memes)
}

async fn like_meme(
    path: web::Path<i32>,
    data: web::Data<AppState>,
) -> impl Responder {
    let meme_id = path.into_inner();
    let mut memes = data.memes.lock().unwrap();
    
    if let Some(meme) = memes.iter_mut().find(|m| m.id == meme_id) {
        meme.likes += 1;
        HttpResponse::Ok().json(meme.clone())
    } else {
        HttpResponse::NotFound().json(serde_json::json!({
            "error": "Meme not found"
        }))
    }
}

async fn upload_meme(
    mut payload: Multipart,
    data: web::Data<AppState>,
) -> Result<HttpResponse, actix_web::Error> {
    let mut caption = String::new();
    let mut tags = String::new();
    let mut image_url = String::new();
    let mut evm_address: Option<String> = None;

    // Process multipart form data
    while let Some(item) = payload.next().await {
        let mut field = item?;
        let content_disposition = field.content_disposition();
        let field_name = content_disposition.get_name().unwrap_or("");

        match field_name {
            "caption" => {
                while let Some(chunk) = field.next().await {
                    let data = chunk?;
                    caption.push_str(std::str::from_utf8(&data).unwrap_or(""));
                }
            }
            "tags" => {
                while let Some(chunk) = field.next().await {
                    let data = chunk?;
                    tags.push_str(std::str::from_utf8(&data).unwrap_or(""));
                }
            }
            "image_url" => {
                while let Some(chunk) = field.next().await {
                    let data = chunk?;
                    image_url.push_str(std::str::from_utf8(&data).unwrap_or(""));
                }
            }
            "evm_address" => {
                let mut addr = String::new();
                while let Some(chunk) = field.next().await {
                    let data = chunk?;
                    addr.push_str(std::str::from_utf8(&data).unwrap_or(""));
                }
                if !addr.is_empty() {
                    evm_address = Some(addr);
                }
            }
            "image" => {
                // Handle file upload - save to uploads directory
                let filename = content_disposition
                    .get_filename()
                    .unwrap_or("upload.jpg")
                    .to_string();
                
                let filepath = format!("./uploads/{}", filename);
                
                // Create uploads directory if it doesn't exist
                std::fs::create_dir_all("./uploads").ok();
                
                let mut f = std::fs::File::create(&filepath)?;
                while let Some(chunk) = field.next().await {
                    let data = chunk?;
                    f.write_all(&data)?;
                }
                
                // Return the API URL for the uploaded file
                image_url = format!("http://127.0.0.1:8000/uploads/{}", filename);
            }
            _ => {}
        }
    }

    // Create new meme
    let mut next_id = data.next_id.lock().unwrap();
    let id = *next_id;
    *next_id += 1;
    drop(next_id);

    let new_meme = Meme {
        id,
        caption,
        tags,
        image: image_url,
        video: None,
        media_type: "image".to_string(),
        evm_address,
        user: None,
        likes: 0,
        comment_count: 0,
        is_liked: false,
        created_at: chrono::Utc::now().to_rfc3339(),
    };

    let mut memes = data.memes.lock().unwrap();
    memes.push(new_meme.clone());
    drop(memes);

    Ok(HttpResponse::Ok().json(new_meme))
}

// MARK: - User Endpoints

async fn register_user(
    body: web::Json<RegisterUserRequest>,
    data: web::Data<AppState>,
) -> impl Responder {
    let mut users = data.users.lock().unwrap();
    
    // Check if user already exists by OAuth ID
    if let Some(existing_user) = users.iter().find(|u| u.oauth_id == body.oauth_id && u.oauth_provider == body.oauth_provider) {
        println!("✅ User already registered: {}", existing_user.wallet_address);
        return HttpResponse::Ok().json(existing_user.clone());
    }
    
    // Create new user
    let new_user = User {
        wallet_address: body.wallet_address.clone(),
        email: body.email.clone(),
        name: body.name.clone(),
        profile_picture: body.profile_picture.clone(),
        bio: body.bio.clone(),
        oauth_provider: body.oauth_provider.clone(),
        oauth_id: body.oauth_id.clone(),
        created_at: chrono::Utc::now().to_rfc3339(),
        followers_count: 0,
        following_count: 0,
    };
    
    users.push(new_user.clone());
    println!("🆕 New user registered: {} ({})", new_user.wallet_address, new_user.email.as_deref().unwrap_or("no email"));
    
    HttpResponse::Ok().json(new_user)
}

async fn search_users(
    query: web::Query<SearchUsersRequest>,
    data: web::Data<AppState>,
) -> impl Responder {
    let users = data.users.lock().unwrap();
    let search_query = query.query.to_lowercase();
    
    let results: Vec<User> = users
        .iter()
        .filter(|u| {
            if let Some(email) = &u.email {
                if email.to_lowercase().contains(&search_query) {
                    return true;
                }
            }
            if let Some(name) = &u.name {
                if name.to_lowercase().contains(&search_query) {
                    return true;
                }
            }
            u.wallet_address.to_lowercase().contains(&search_query)
        })
        .cloned()
        .collect();
    
    println!("🔍 User search for '{}': {} results", search_query, results.len());
    
    HttpResponse::Ok().json(results)
}

async fn get_all_users(data: web::Data<AppState>) -> impl Responder {
    let users = data.users.lock().unwrap();
    let user_list: Vec<User> = users.clone();
    
    println!("📋 Fetched all users: {} total", user_list.len());
    
    HttpResponse::Ok().json(user_list)
}

async fn get_user_by_wallet(
    wallet: web::Path<String>,
    data: web::Data<AppState>,
) -> impl Responder {
    let users = data.users.lock().unwrap();
    let wallet_address = wallet.into_inner();
    
    if let Some(user) = users.iter().find(|u| u.wallet_address == wallet_address) {
        HttpResponse::Ok().json(user.clone())
    } else {
        HttpResponse::NotFound().json(serde_json::json!({
            "error": "User not found"
        }))
    }
}

async fn update_user_profile(
    wallet: web::Path<String>,
    body: web::Json<UpdateProfileRequest>,
    data: web::Data<AppState>,
) -> impl Responder {
    let mut users = data.users.lock().unwrap();
    let wallet_address = wallet.into_inner();
    
    if let Some(user) = users.iter_mut().find(|u| u.wallet_address == wallet_address) {
        if let Some(name) = &body.name {
            user.name = Some(name.clone());
        }
        if let Some(bio) = &body.bio {
            user.bio = Some(bio.clone());
        }
        if let Some(profile_picture) = &body.profile_picture {
            user.profile_picture = Some(profile_picture.clone());
        }
        
        println!("✏️ Updated profile for {}", wallet_address);
        HttpResponse::Ok().json(user.clone())
    } else {
        HttpResponse::NotFound().json(serde_json::json!({
            "error": "User not found"
        }))
    }
}

// MARK: - Follow Endpoints

async fn follow_user(
    body: web::Json<FollowRequest>,
    data: web::Data<AppState>,
) -> impl Responder {
    let mut follows = data.follows.lock().unwrap();
    
    // Check if already following
    if follows.iter().any(|f| f.follower_id == body.follower_id && f.following_id == body.following_id) {
        return HttpResponse::BadRequest().json(serde_json::json!({
            "error": "Already following"
        }));
    }
    
    let new_follow = Follow {
        follower_id: body.follower_id.clone(),
        following_id: body.following_id.clone(),
        created_at: chrono::Utc::now().to_rfc3339(),
    };
    
    follows.push(new_follow);
    drop(follows);
    
    // Update follower counts
    let mut users = data.users.lock().unwrap();
    if let Some(follower) = users.iter_mut().find(|u| u.wallet_address == body.follower_id) {
        follower.following_count += 1;
    }
    if let Some(following) = users.iter_mut().find(|u| u.wallet_address == body.following_id) {
        following.followers_count += 1;
    }
    
    println!("👥 {} followed {}", body.follower_id, body.following_id);
    
    HttpResponse::Ok().json(serde_json::json!({
        "message": "Successfully followed"
    }))
}

async fn unfollow_user(
    body: web::Json<FollowRequest>,
    data: web::Data<AppState>,
) -> impl Responder {
    let mut follows = data.follows.lock().unwrap();
    
    let initial_len = follows.len();
    follows.retain(|f| !(f.follower_id == body.follower_id && f.following_id == body.following_id));
    
    if follows.len() == initial_len {
        return HttpResponse::NotFound().json(serde_json::json!({
            "error": "Not following"
        }));
    }
    
    drop(follows);
    
    // Update follower counts
    let mut users = data.users.lock().unwrap();
    if let Some(follower) = users.iter_mut().find(|u| u.wallet_address == body.follower_id) {
        follower.following_count = follower.following_count.saturating_sub(1);
    }
    if let Some(following) = users.iter_mut().find(|u| u.wallet_address == body.following_id) {
        following.followers_count = following.followers_count.saturating_sub(1);
    }
    
    println!("👋 {} unfollowed {}", body.follower_id, body.following_id);
    
    HttpResponse::Ok().json(serde_json::json!({
        "message": "Successfully unfollowed"
    }))
}

async fn check_following(
    path: web::Path<(String, String)>,
    data: web::Data<AppState>,
) -> impl Responder {
    let (follower_id, following_id) = path.into_inner();
    let follows = data.follows.lock().unwrap();
    
    let is_following = follows.iter().any(|f| f.follower_id == follower_id && f.following_id == following_id);
    
    HttpResponse::Ok().json(serde_json::json!({
        "is_following": is_following
    }))
}

async fn get_followers(
    user_id: web::Path<String>,
    data: web::Data<AppState>,
) -> impl Responder {
    let follows = data.follows.lock().unwrap();
    let users = data.users.lock().unwrap();
    let target_user = user_id.into_inner();
    
    let follower_ids: Vec<String> = follows
        .iter()
        .filter(|f| f.following_id == target_user)
        .map(|f| f.follower_id.clone())
        .collect();
    
    let followers: Vec<User> = users
        .iter()
        .filter(|u| follower_ids.contains(&u.wallet_address))
        .cloned()
        .collect();
    
    HttpResponse::Ok().json(followers)
}

async fn get_following(
    user_id: web::Path<String>,
    data: web::Data<AppState>,
) -> impl Responder {
    let follows = data.follows.lock().unwrap();
    let users = data.users.lock().unwrap();
    let target_user = user_id.into_inner();
    
    let following_ids: Vec<String> = follows
        .iter()
        .filter(|f| f.follower_id == target_user)
        .map(|f| f.following_id.clone())
        .collect();
    
    let following: Vec<User> = users
        .iter()
        .filter(|u| following_ids.contains(&u.wallet_address))
        .cloned()
        .collect();
    
    HttpResponse::Ok().json(following)
}

async fn get_user_posts(
    user_id: web::Path<String>,
    data: web::Data<AppState>,
) -> impl Responder {
    let memes = data.memes.lock().unwrap();
    let target_user = user_id.into_inner();
    
    let user_posts: Vec<Meme> = memes
        .iter()
        .filter(|m| m.evm_address.as_ref().map_or(false, |addr| addr == &target_user))
        .cloned()
        .collect();
    
    HttpResponse::Ok().json(user_posts)
}

async fn get_following_feed(
    user_id: web::Path<String>,
    data: web::Data<AppState>,
) -> impl Responder {
    let follows = data.follows.lock().unwrap();
    let memes = data.memes.lock().unwrap();
    let target_user = user_id.into_inner();
    
    // Get list of users being followed
    let following_ids: Vec<String> = follows
        .iter()
        .filter(|f| f.follower_id == target_user)
        .map(|f| f.following_id.clone())
        .collect();
    
    // Get posts from followed users
    let mut feed_posts: Vec<Meme> = memes
        .iter()
        .filter(|m| m.evm_address.as_ref().map_or(false, |addr| following_ids.contains(addr)))
        .cloned()
        .collect();
    
    // Sort by created_at (newest first)
    feed_posts.sort_by(|a, b| b.created_at.cmp(&a.created_at));
    
    HttpResponse::Ok().json(feed_posts)
}

// MARK: - Comment Endpoints

async fn get_comments(
    post_id: web::Path<i32>,
    data: web::Data<AppState>,
) -> impl Responder {
    let comments = data.comments.lock().unwrap();
    let users = data.users.lock().unwrap();
    let target_post = post_id.into_inner();
    
    let mut post_comments: Vec<Comment> = comments
        .iter()
        .filter(|c| c.post_id == target_post)
        .cloned()
        .collect();
    
    // Attach user info to comments
    for comment in &mut post_comments {
        if let Some(user) = users.iter().find(|u| u.wallet_address == comment.user_id) {
            comment.user = Some(user.clone());
        }
    }
    
    HttpResponse::Ok().json(post_comments)
}

async fn add_comment(
    post_id: web::Path<i32>,
    body: web::Json<AddCommentRequest>,
    data: web::Data<AppState>,
) -> impl Responder {
    let mut comments = data.comments.lock().unwrap();
    let mut next_id = data.next_comment_id.lock().unwrap();
    
    let new_comment = Comment {
        id: *next_id,
        post_id: post_id.into_inner(),
        user_id: body.user_id.clone(),
        user: None,
        text: body.text.clone(),
        created_at: chrono::Utc::now().to_rfc3339(),
        likes: 0,
        is_liked: false,
    };
    
    *next_id += 1;
    comments.push(new_comment.clone());
    drop(comments);
    drop(next_id);
    
    // Update comment count on post
    let mut memes = data.memes.lock().unwrap();
    if let Some(meme) = memes.iter_mut().find(|m| m.id == new_comment.post_id) {
        meme.comment_count += 1;
    }
    
    println!("💬 New comment on post {}", new_comment.post_id);
    
    HttpResponse::Ok().json(new_comment)
}

// MARK: - Message Endpoints

async fn send_message(
    body: web::Json<SendMessageRequest>,
    data: web::Data<AppState>,
) -> impl Responder {
    let mut messages = data.messages.lock().unwrap();
    let mut next_id = data.next_message_id.lock().unwrap();
    
    let new_message = Message {
        id: *next_id,
        sender_id: body.sender_id.clone(),
        receiver_id: body.receiver_id.clone(),
        content: body.content.clone(),
        timestamp: chrono::Utc::now().to_rfc3339(),
        is_read: false,
    };
    
    *next_id += 1;
    messages.push(new_message.clone());
    
    println!("📨 Message sent from {} to {}", body.sender_id, body.receiver_id);
    
    HttpResponse::Ok().json(new_message)
}

async fn get_conversations(
    user_id: web::Path<String>,
    data: web::Data<AppState>,
) -> impl Responder {
    let messages = data.messages.lock().unwrap();
    let current_user = user_id.into_inner();
    
    // Find all unique conversation partners
    let mut conversation_map: HashMap<String, Vec<Message>> = HashMap::new();
    
    for message in messages.iter() {
        if message.sender_id == current_user {
            conversation_map
                .entry(message.receiver_id.clone())
                .or_insert_with(Vec::new)
                .push(message.clone());
        } else if message.receiver_id == current_user {
            conversation_map
                .entry(message.sender_id.clone())
                .or_insert_with(Vec::new)
                .push(message.clone());
        }
    }
    
    // Build conversation objects
    let mut conversations: Vec<Conversation> = conversation_map
        .into_iter()
        .map(|(other_user, mut msgs)| {
            // Sort messages by timestamp (newest first)
            msgs.sort_by(|a, b| b.timestamp.cmp(&a.timestamp));
            
            let last_message = msgs.first().cloned();
            let unread_count = msgs
                .iter()
                .filter(|m| m.receiver_id == current_user && !m.is_read)
                .count() as i32;
            
            let updated_at = last_message
                .as_ref()
                .map(|m| m.timestamp.clone())
                .unwrap_or_else(|| chrono::Utc::now().to_rfc3339());
            
            Conversation {
                id: format!("{}_{}", current_user, other_user),
                other_user_id: other_user.clone(),
                other_user_name: None, // Could be enhanced with user profiles
                last_message,
                unread_count,
                updated_at,
            }
        })
        .collect();
    
    // Sort by updated_at (most recent first)
    conversations.sort_by(|a, b| b.updated_at.cmp(&a.updated_at));
    
    HttpResponse::Ok().json(conversations)
}

async fn get_messages(
    path: web::Path<(String, String)>,
    data: web::Data<AppState>,
) -> impl Responder {
    let (current_user, other_user) = path.into_inner();
    let messages = data.messages.lock().unwrap();
    
    // Get all messages between these two users
    let conversation_messages: Vec<Message> = messages
        .iter()
        .filter(|m| {
            (m.sender_id == current_user && m.receiver_id == other_user)
                || (m.sender_id == other_user && m.receiver_id == current_user)
        })
        .cloned()
        .collect();
    
    println!("💬 Fetched {} messages between {} and {}", 
        conversation_messages.len(), current_user, other_user);
    
    HttpResponse::Ok().json(conversation_messages)
}

async fn mark_messages_read(
    path: web::Path<(String, String)>,
    data: web::Data<AppState>,
) -> impl Responder {
    let (current_user, other_user) = path.into_inner();
    let mut messages = data.messages.lock().unwrap();
    
    let mut marked_count = 0;
    
    for message in messages.iter_mut() {
        if message.receiver_id == current_user && message.sender_id == other_user && !message.is_read {
            message.is_read = true;
            marked_count += 1;
        }
    }
    
    println!("✅ Marked {} messages as read", marked_count);
    
    HttpResponse::Ok().json(serde_json::json!({
        "marked_count": marked_count
    }))
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    // Initialize with some sample memes
    let initial_memes = vec![
        Meme {
            id: 1,
            caption: "Doge".to_string(),
            tags: "classic, crypto".to_string(),
            image: "https://i.kym-cdn.com/entries/icons/original/000/013/564/doge.jpg".to_string(),
            video: None,
            media_type: "image".to_string(),
            evm_address: Some("0x39D0F19273036293764262aCb5115F223aEF8f79".to_string()),
            user: None,
            likes: 12,
            comment_count: 3,
            is_liked: false,
            created_at: chrono::Utc::now().to_rfc3339(),
        },
        Meme {
            id: 2,
            caption: "Pepe the Frog".to_string(),
            tags: "classic, rare".to_string(),
            image: "https://i.kym-cdn.com/entries/icons/original/000/017/618/pepefroggie.jpg".to_string(),
            video: None,
            media_type: "image".to_string(),
            evm_address: Some("0x2555ea784eBDb81C1704f8b749Dbbc68aDaCB723".to_string()),
            user: None,
            likes: 8,
            comment_count: 1,
            is_liked: false,
            created_at: chrono::Utc::now().to_rfc3339(),
        },
    ];

    let app_state = web::Data::new(AppState {
        memes: Mutex::new(initial_memes),
        next_id: Mutex::new(3),
        messages: Mutex::new(Vec::new()),
        next_message_id: Mutex::new(1),
        users: Mutex::new(Vec::new()),
        comments: Mutex::new(Vec::new()),
        next_comment_id: Mutex::new(1),
        follows: Mutex::new(Vec::new()),
    });

    // Load environment variables
    dotenv::dotenv().ok();
    
    // Setup database connection (optional - for auth system)
    let database_url = std::env::var("DATABASE_URL").ok();
    let pool = if let Some(db_url) = database_url {
        match PgPoolOptions::new()
            .max_connections(5)
            .connect(&db_url)
            .await
        {
            Ok(pool) => {
                println!("✅ Connected to PostgreSQL database");
                Some(web::Data::new(pool))
            }
            Err(e) => {
                println!("⚠️  Database connection failed: {}", e);
                println!("   Falling back to in-memory storage");
                None
            }
        }
    } else {
        println!("ℹ️  No DATABASE_URL found, using in-memory storage");
        None
    };

    // JWT Secret for authentication
    let jwt_secret = std::env::var("JWT_SECRET")
        .unwrap_or_else(|_| "dev_secret_key_change_in_production".to_string());
    let jwt_secret = web::Data::new(jwt_secret);

    // Get port from environment variable or default to 8000
    let port = std::env::var("PORT").unwrap_or_else(|_| "8000".to_string());
    let bind_address = format!("0.0.0.0:{}", port);
    
    println!("🚀 Server starting on {}", bind_address);
    println!("📁 Uploads will be saved to ./uploads/");
    if pool.is_some() {
        println!("🔐 Authentication system enabled");
    }
    
    let pool_clone = pool.clone();
    let jwt_secret_clone = jwt_secret.clone();
    
    HttpServer::new(move || {
        let cors = Cors::default()
            .allow_any_origin()
            .allow_any_method()
            .allow_any_header()
            .max_age(3600);

        let mut app = App::new()
            .app_data(app_state.clone())
            .app_data(jwt_secret_clone.clone())
            .wrap(cors)
            .wrap(middleware::Logger::default());

        // Add database-based auth routes if database is available
        if let Some(ref pool_data) = pool_clone {
            app = app
                .app_data(pool_data.clone())
                // Authentication routes (no auth required)
                .route("/auth/register", web::post().to(auth::register))
                .route("/auth/login", web::post().to(auth::login))
                .route("/auth/logout", web::post().to(auth::logout))
                // Protected auth routes
                .service(
                    web::scope("/auth")
                        .wrap(HttpAuthentication::bearer(auth::jwt_middleware))
                        .route("/me", web::get().to(auth::get_current_user))
                        .route("/profile", web::put().to(auth::update_profile))
                );
        }

        app
            // Legacy user routes (for backwards compatibility)
            .route("/users/register", web::post().to(register_user))
            .route("/users/search", web::get().to(search_users))
            .route("/users", web::get().to(get_all_users))
            .route("/users/{wallet}", web::get().to(get_user_by_wallet))
            .route("/users/{wallet}", web::put().to(update_user_profile))
            .route("/users/{user_id}/posts", web::get().to(get_user_posts))
            .route("/users/{user_id}/followers", web::get().to(get_followers))
            .route("/users/{user_id}/following", web::get().to(get_following))
            // Meme/Post routes
            .route("/memes", web::get().to(get_memes))
            .route("/memes", web::post().to(upload_meme))
            .route("/memes/upload", web::post().to(upload_meme))
            .route("/memes/{id}/like", web::post().to(like_meme))
            .route("/memes/{post_id}/comments", web::get().to(get_comments))
            .route("/memes/{post_id}/comments", web::post().to(add_comment))
            // Feed routes
            .route("/feed/{user_id}", web::get().to(get_following_feed))
            // Follow routes
            .route("/follow", web::post().to(follow_user))
            .route("/follow", web::delete().to(unfollow_user))
            .route("/follow/check/{follower_id}/{following_id}", web::get().to(check_following))
            // Message routes
            .route("/messages/send", web::post().to(send_message))
            .route("/messages/conversations/{user_id}", web::get().to(get_conversations))
            .route("/messages/{user_id}/{other_user_id}", web::get().to(get_messages))
            .route("/messages/read/{user_id}/{other_user_id}", web::put().to(mark_messages_read))
            // Serve uploaded files
            .service(fs::Files::new("/uploads", "./uploads").show_files_listing())
    })
    .bind(&bind_address)?
    .run()
    .await
}