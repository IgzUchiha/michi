use sqlx::{Pool, Postgres, postgres::PgPoolOptions};
use std::env;

pub type DbPool = Pool<Postgres>;

pub async fn create_pool() -> Result<DbPool, sqlx::Error> {
    let database_url = env::var("DATABASE_URL")
        .unwrap_or_else(|_| {
            println!("⚠️ DATABASE_URL not set, using SQLite fallback");
            "postgresql://localhost/rustaceaans".to_string()
        });
    
    println!("🔗 Connecting to database...");
    
    let pool = PgPoolOptions::new()
        .max_connections(5)
        .connect(&database_url)
        .await?;
    
    println!("✅ Database connected!");
    
    Ok(pool)
}

pub async fn run_migrations(pool: &DbPool) -> Result<(), sqlx::Error> {
    println!("🔄 Running database migrations...");
    
    sqlx::query(
        r#"
        CREATE TABLE IF NOT EXISTS users (
            id SERIAL PRIMARY KEY,
            wallet_address VARCHAR(42) UNIQUE NOT NULL,
            email VARCHAR(255),
            name VARCHAR(255),
            oauth_provider VARCHAR(50) NOT NULL,
            oauth_id VARCHAR(255) NOT NULL,
            created_at TIMESTAMP NOT NULL DEFAULT NOW(),
            UNIQUE(oauth_provider, oauth_id)
        )
        "#
    )
    .execute(pool)
    .await?;
    
    sqlx::query(
        r#"
        CREATE TABLE IF NOT EXISTS memes (
            id SERIAL PRIMARY KEY,
            caption TEXT NOT NULL,
            tags TEXT NOT NULL,
            image_url TEXT NOT NULL,
            evm_address VARCHAR(42),
            likes INTEGER NOT NULL DEFAULT 0,
            comment_count INTEGER NOT NULL DEFAULT 0,
            created_at TIMESTAMP NOT NULL DEFAULT NOW()
        )
        "#
    )
    .execute(pool)
    .await?;
    
    sqlx::query(
        r#"
        CREATE TABLE IF NOT EXISTS messages (
            id SERIAL PRIMARY KEY,
            sender_id VARCHAR(42) NOT NULL,
            receiver_id VARCHAR(42) NOT NULL,
            content_type VARCHAR(20) NOT NULL,
            content_text TEXT,
            content_meme_id INTEGER,
            content_media_url TEXT,
            is_read BOOLEAN NOT NULL DEFAULT FALSE,
            created_at TIMESTAMP NOT NULL DEFAULT NOW()
        )
        "#
    )
    .execute(pool)
    .await?;
    
    // Add indexes for performance
    sqlx::query("CREATE INDEX IF NOT EXISTS idx_messages_sender ON messages(sender_id)")
        .execute(pool)
        .await?;
    
    sqlx::query("CREATE INDEX IF NOT EXISTS idx_messages_receiver ON messages(receiver_id)")
        .execute(pool)
        .await?;
    
    sqlx::query("CREATE INDEX IF NOT EXISTS idx_users_wallet ON users(wallet_address)")
        .execute(pool)
        .await?;
    
    println!("✅ Migrations complete!");
    
    Ok(())
}
