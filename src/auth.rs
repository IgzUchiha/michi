use actix_web::{dev::ServiceRequest, Error, HttpMessage, HttpResponse, web};
use actix_web_httpauth::extractors::bearer::BearerAuth;
use bcrypt::{hash, verify, DEFAULT_COST};
use chrono::{Duration, Utc};
use jsonwebtoken::{decode, encode, DecodingKey, EncodingKey, Header, Validation};
use serde::{Deserialize, Serialize};
use sqlx::PgPool;
use validator::Validate;

// JWT Claims
#[derive(Debug, Serialize, Deserialize)]
pub struct Claims {
    pub sub: i32,        // user_id
    pub email: String,
    pub username: String,
    pub exp: i64,        // expiration time
    pub iat: i64,        // issued at
}

// Request/Response Models
#[derive(Debug, Deserialize, Validate)]
pub struct RegisterRequest {
    #[validate(length(min = 3, max = 50))]
    pub username: String,
    
    #[validate(email)]
    pub email: String,
    
    #[validate(length(min = 8))]
    pub password: String,
    
    pub display_name: Option<String>,
    pub wallet_address: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct LoginRequest {
    pub email: String,
    pub password: String,
}

#[derive(Debug, Serialize)]
pub struct AuthResponse {
    pub user: UserResponse,
    pub token: String,
    pub expires_at: String,
}

#[derive(Debug, Serialize, Clone)]
pub struct UserResponse {
    pub user_id: i32,
    pub username: String,
    pub email: String,
    pub display_name: Option<String>,
    pub bio: Option<String>,
    pub profile_picture_url: Option<String>,
    pub wallet_address: Option<String>,
    pub followers_count: i32,
    pub following_count: i32,
    pub posts_count: i32,
    pub created_at: chrono::NaiveDateTime,
}

// Database User Model
#[derive(Debug, sqlx::FromRow)]
pub struct User {
    pub user_id: i32,
    pub username: String,
    pub email: String,
    pub password_hash: String,
    pub display_name: Option<String>,
    pub bio: Option<String>,
    pub profile_picture_url: Option<String>,
    pub wallet_address: Option<String>,
    pub followers_count: Option<i32>,
    pub following_count: Option<i32>,
    pub posts_count: Option<i32>,
    pub is_active: Option<bool>,
    pub created_at: Option<chrono::NaiveDateTime>,
}

impl User {
    pub fn to_response(&self) -> UserResponse {
        UserResponse {
            user_id: self.user_id,
            username: self.username.clone(),
            email: self.email.clone(),
            display_name: self.display_name.clone(),
            bio: self.bio.clone(),
            profile_picture_url: self.profile_picture_url.clone(),
            wallet_address: self.wallet_address.clone(),
            followers_count: self.followers_count.unwrap_or(0),
            following_count: self.following_count.unwrap_or(0),
            posts_count: self.posts_count.unwrap_or(0),
            created_at: self.created_at.unwrap_or_else(|| chrono::NaiveDateTime::from_timestamp_opt(0, 0).unwrap()),
        }
    }
}

// JWT Helper Functions
pub fn create_jwt(user: &User, secret: &str) -> Result<String, jsonwebtoken::errors::Error> {
    let expiration = Utc::now()
        .checked_add_signed(Duration::days(7))
        .expect("valid timestamp")
        .timestamp();

    let claims = Claims {
        sub: user.user_id,
        email: user.email.clone(),
        username: user.username.clone(),
        exp: expiration,
        iat: Utc::now().timestamp(),
    };

    encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(secret.as_ref()),
    )
}

pub fn decode_jwt(token: &str, secret: &str) -> Result<Claims, jsonwebtoken::errors::Error> {
    let token_data = decode::<Claims>(
        token,
        &DecodingKey::from_secret(secret.as_ref()),
        &Validation::default(),
    )?;

    Ok(token_data.claims)
}

// Auth Endpoints

/// POST /auth/register
pub async fn register(
    pool: web::Data<PgPool>,
    body: web::Json<RegisterRequest>,
    jwt_secret: web::Data<String>,
) -> Result<HttpResponse, Error> {
    // Validate input
    if let Err(e) = body.validate() {
        return Ok(HttpResponse::BadRequest().json(serde_json::json!({
            "error": "Validation failed",
            "details": e.to_string()
        })));
    }

    // Check if email already exists
    let existing_email = sqlx::query!(
        "SELECT user_id FROM users WHERE email = $1",
        body.email
    )
    .fetch_optional(pool.get_ref())
    .await
    .map_err(|e| {
        eprintln!("Database error: {}", e);
        actix_web::error::ErrorInternalServerError("Database error")
    })?;

    if existing_email.is_some() {
        return Ok(HttpResponse::BadRequest().json(serde_json::json!({
            "error": "Email already registered"
        })));
    }

    // Check if username already exists
    let existing_username = sqlx::query!(
        "SELECT user_id FROM users WHERE username = $1",
        body.username
    )
    .fetch_optional(pool.get_ref())
    .await
    .map_err(|e| {
        eprintln!("Database error: {}", e);
        actix_web::error::ErrorInternalServerError("Database error")
    })?;

    if existing_username.is_some() {
        return Ok(HttpResponse::BadRequest().json(serde_json::json!({
            "error": "Username already taken"
        })));
    }

    // Hash password
    let password_hash = hash(&body.password, DEFAULT_COST)
        .map_err(|_| actix_web::error::ErrorInternalServerError("Failed to hash password"))?;

    // Create user
    let user = sqlx::query_as!(
        User,
        r#"
        INSERT INTO users (username, email, password_hash, display_name, wallet_address)
        VALUES ($1, $2, $3, $4, $5)
        RETURNING 
            user_id, username, email, password_hash, display_name, bio, 
            profile_picture_url, wallet_address, 
            followers_count, following_count, posts_count, 
            is_active, created_at
        "#,
        body.username,
        body.email,
        password_hash,
        body.display_name,
        body.wallet_address
    )
    .fetch_one(pool.get_ref())
    .await
    .map_err(|e| {
        eprintln!("Database error: {}", e);
        actix_web::error::ErrorInternalServerError("Failed to create user")
    })?;

    // Generate JWT token
    let token = create_jwt(&user, &jwt_secret)
        .map_err(|_| actix_web::error::ErrorInternalServerError("Failed to generate token"))?;

    // Create session
    let expires_at = Utc::now() + Duration::days(7);
    sqlx::query!(
        "INSERT INTO sessions (user_id, token, expires_at) VALUES ($1, $2, $3)",
        user.user_id,
        token,
        expires_at.naive_utc()
    )
    .execute(pool.get_ref())
    .await
    .ok(); // Ignore session creation errors

    println!("✅ New user registered: {} ({})", user.username, user.email);

    Ok(HttpResponse::Ok().json(AuthResponse {
        user: user.to_response(),
        token,
        expires_at: expires_at.to_rfc3339(),
    }))
}

/// POST /auth/login
pub async fn login(
    pool: web::Data<PgPool>,
    body: web::Json<LoginRequest>,
    jwt_secret: web::Data<String>,
) -> Result<HttpResponse, Error> {
    // Find user by email
    let user = sqlx::query_as!(
        User,
        r#"
        SELECT 
            user_id, username, email, password_hash, display_name, bio, 
            profile_picture_url, wallet_address, 
            followers_count, following_count, posts_count, 
            is_active, created_at
        FROM users 
        WHERE email = $1 AND is_active = TRUE
        "#,
        body.email
    )
    .fetch_optional(pool.get_ref())
    .await
    .map_err(|e| {
        eprintln!("Database error: {}", e);
        actix_web::error::ErrorInternalServerError("Database error")
    })?;

    let user = match user {
        Some(u) => u,
        None => {
            return Ok(HttpResponse::Unauthorized().json(serde_json::json!({
                "error": "Invalid email or password"
            })));
        }
    };

    // Verify password
    let valid = verify(&body.password, &user.password_hash)
        .map_err(|_| actix_web::error::ErrorInternalServerError("Failed to verify password"))?;

    if !valid {
        return Ok(HttpResponse::Unauthorized().json(serde_json::json!({
            "error": "Invalid email or password"
        })));
    }

    // Update last login
    sqlx::query!(
        "UPDATE users SET last_login_at = NOW() WHERE user_id = $1",
        user.user_id
    )
    .execute(pool.get_ref())
    .await
    .ok();

    // Generate JWT token
    let token = create_jwt(&user, &jwt_secret)
        .map_err(|_| actix_web::error::ErrorInternalServerError("Failed to generate token"))?;

    // Create session
    let expires_at = Utc::now() + Duration::days(7);
    sqlx::query!(
        "INSERT INTO sessions (user_id, token, expires_at) VALUES ($1, $2, $3)",
        user.user_id,
        token,
        expires_at.naive_utc()
    )
    .execute(pool.get_ref())
    .await
    .ok();

    println!("✅ User logged in: {} ({})", user.username, user.email);

    Ok(HttpResponse::Ok().json(AuthResponse {
        user: user.to_response(),
        token,
        expires_at: expires_at.to_rfc3339(),
    }))
}

/// GET /auth/me
pub async fn get_current_user(
    pool: web::Data<PgPool>,
    req: actix_web::HttpRequest,
) -> Result<HttpResponse, Error> {
    // Get user_id from request extensions (set by middleware)
    let user_id = req
        .extensions()
        .get::<i32>()
        .copied()
        .ok_or_else(|| actix_web::error::ErrorUnauthorized("Unauthorized"))?;

    // Fetch user from database
    let user = sqlx::query_as!(
        User,
        r#"
        SELECT 
            user_id, username, email, password_hash, display_name, bio, 
            profile_picture_url, wallet_address, 
            followers_count, following_count, posts_count, 
            is_active, created_at
        FROM users 
        WHERE user_id = $1 AND is_active = TRUE
        "#,
        user_id
    )
    .fetch_optional(pool.get_ref())
    .await
    .map_err(|e| {
        eprintln!("Database error: {}", e);
        actix_web::error::ErrorInternalServerError("Database error")
    })?;

    match user {
        Some(u) => Ok(HttpResponse::Ok().json(u.to_response())),
        None => Ok(HttpResponse::NotFound().json(serde_json::json!({
            "error": "User not found"
        }))),
    }
}

/// POST /auth/logout
pub async fn logout(
    pool: web::Data<PgPool>,
    req: actix_web::HttpRequest,
) -> Result<HttpResponse, Error> {
    // Get token from Authorization header
    if let Some(auth_header) = req.headers().get("Authorization") {
        if let Ok(auth_str) = auth_header.to_str() {
            if let Some(token) = auth_str.strip_prefix("Bearer ") {
                // Invalidate session
                sqlx::query!(
                    "UPDATE sessions SET is_active = FALSE WHERE token = $1",
                    token
                )
                .execute(pool.get_ref())
                .await
                .ok();
            }
        }
    }

    Ok(HttpResponse::Ok().json(serde_json::json!({
        "message": "Logged out successfully"
    })))
}

#[derive(Debug, Deserialize)]
pub struct UpdateProfileRequest {
    pub display_name: Option<String>,
    pub bio: Option<String>,
    pub profile_picture_url: Option<String>,
}

/// PUT /auth/profile - Update user profile
pub async fn update_profile(
    pool: web::Data<PgPool>,
    req: actix_web::HttpRequest,
    body: web::Json<UpdateProfileRequest>,
) -> Result<HttpResponse, Error> {
    // Get user_id from request extensions (set by middleware)
    let user_id = req
        .extensions()
        .get::<i32>()
        .copied()
        .ok_or_else(|| actix_web::error::ErrorUnauthorized("Unauthorized"))?;

    // Update user profile
    sqlx::query!(
        r#"
        UPDATE users 
        SET display_name = COALESCE($1, display_name),
            bio = COALESCE($2, bio),
            profile_picture_url = COALESCE($3, profile_picture_url)
        WHERE user_id = $4
        "#,
        body.display_name,
        body.bio,
        body.profile_picture_url,
        user_id
    )
    .execute(pool.get_ref())
    .await
    .map_err(|e| {
        eprintln!("Database error: {}", e);
        actix_web::error::ErrorInternalServerError("Failed to update profile")
    })?;

    // Fetch updated user
    let user = sqlx::query_as!(
        User,
        r#"
        SELECT 
            user_id, username, email, password_hash, display_name, bio, 
            profile_picture_url, wallet_address, 
            followers_count, following_count, posts_count, 
            is_active, created_at
        FROM users 
        WHERE user_id = $1
        "#,
        user_id
    )
    .fetch_one(pool.get_ref())
    .await
    .map_err(|e| {
        eprintln!("Database error: {}", e);
        actix_web::error::ErrorInternalServerError("Failed to fetch user")
    })?;

    println!("✏️ Profile updated for user_id: {}", user_id);

    Ok(HttpResponse::Ok().json(user.to_response()))
}

// JWT Middleware
pub async fn jwt_middleware(
    mut req: ServiceRequest,
    credentials: BearerAuth,
) -> Result<ServiceRequest, (Error, ServiceRequest)> {
    let token = credentials.token();
    
    // Get JWT secret from app data
    let jwt_secret = match req.app_data::<web::Data<String>>() {
        Some(secret) => secret.as_ref().clone(),
        None => {
            return Err((
                actix_web::error::ErrorInternalServerError("JWT secret not configured"),
                req,
            ));
        }
    };

    // Decode and validate token
    let claims = match decode_jwt(token, &jwt_secret) {
        Ok(c) => c,
        Err(e) => {
            eprintln!("JWT decode error: {}", e);
            return Err((actix_web::error::ErrorUnauthorized("Invalid token"), req));
        }
    };

    // Check if token is expired
    if claims.exp < Utc::now().timestamp() {
        return Err((actix_web::error::ErrorUnauthorized("Token expired"), req));
    }

    // Store user_id in request extensions for later use
    req.extensions_mut().insert(claims.sub);

    Ok(req)
}
