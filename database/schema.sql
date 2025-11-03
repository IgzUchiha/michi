-- Rustaceaans Database Schema
-- Instagram-style social media with crypto features

-- ============================================
-- USERS TABLE
-- ============================================
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    email_verified BOOLEAN DEFAULT FALSE,
    password_hash VARCHAR(255) NOT NULL,
    
    -- Profile Info
    display_name VARCHAR(100),
    bio TEXT,
    profile_picture_url TEXT,
    
    -- Crypto/Blockchain
    wallet_address VARCHAR(42) UNIQUE,
    
    -- OAuth Integration (optional)
    oauth_provider VARCHAR(50),
    oauth_id VARCHAR(255),
    
    -- Stats
    followers_count INTEGER DEFAULT 0,
    following_count INTEGER DEFAULT 0,
    posts_count INTEGER DEFAULT 0,
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    is_verified BOOLEAN DEFAULT FALSE,
    account_type VARCHAR(20) DEFAULT 'personal', -- personal, business, creator
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login_at TIMESTAMP
);

-- Indexes for users
CREATE INDEX idx_username ON users(username);
CREATE INDEX idx_email ON users(email);
CREATE INDEX idx_wallet_address ON users(wallet_address);

-- ============================================
-- POSTS TABLE
-- ============================================
CREATE TABLE posts (
    post_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    
    -- Content
    caption TEXT,
    media_type VARCHAR(20) NOT NULL, -- image, video, carousel
    media_url TEXT NOT NULL,
    thumbnail_url TEXT,
    
    -- Metadata
    tags TEXT[], -- Array of hashtags
    location VARCHAR(255),
    
    -- Engagement
    likes_count INTEGER DEFAULT 0,
    comments_count INTEGER DEFAULT 0,
    shares_count INTEGER DEFAULT 0,
    views_count INTEGER DEFAULT 0,
    
    -- Crypto Features
    nft_token_id VARCHAR(255),
    nft_contract_address VARCHAR(42),
    tips_enabled BOOLEAN DEFAULT TRUE,
    tips_received DECIMAL(18, 8) DEFAULT 0,
    
    -- Status
    is_published BOOLEAN DEFAULT TRUE,
    is_archived BOOLEAN DEFAULT FALSE,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for posts
CREATE INDEX idx_user_posts ON posts(user_id, created_at DESC);
CREATE INDEX idx_created_at ON posts(created_at DESC);

-- ============================================
-- FOLLOWS TABLE
-- ============================================
CREATE TABLE follows (
    follow_id SERIAL PRIMARY KEY,
    follower_user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    following_user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Prevent duplicate follows
    UNIQUE(follower_user_id, following_user_id)
);

-- Indexes for follows
CREATE INDEX idx_follower ON follows(follower_user_id);
CREATE INDEX idx_following ON follows(following_user_id);

-- ============================================
-- LIKES TABLE
-- ============================================
CREATE TABLE likes (
    like_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    post_id INTEGER NOT NULL REFERENCES posts(post_id) ON DELETE CASCADE,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Prevent duplicate likes
    UNIQUE(user_id, post_id)
);

-- Indexes for likes
CREATE INDEX idx_user_likes ON likes(user_id);
CREATE INDEX idx_post_likes ON likes(post_id);

-- ============================================
-- COMMENTS TABLE
-- ============================================
CREATE TABLE comments (
    comment_id SERIAL PRIMARY KEY,
    post_id INTEGER NOT NULL REFERENCES posts(post_id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    parent_comment_id INTEGER REFERENCES comments(comment_id) ON DELETE CASCADE,
    
    -- Content
    text TEXT NOT NULL,
    
    -- Engagement
    likes_count INTEGER DEFAULT 0,
    replies_count INTEGER DEFAULT 0,
    
    -- Status
    is_edited BOOLEAN DEFAULT FALSE,
    is_deleted BOOLEAN DEFAULT FALSE,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for comments
CREATE INDEX idx_post_comments ON comments(post_id, created_at DESC);
CREATE INDEX idx_user_comments ON comments(user_id);
CREATE INDEX idx_parent_comment ON comments(parent_comment_id);

-- ============================================
-- MESSAGES TABLE
-- ============================================
CREATE TABLE messages (
    message_id SERIAL PRIMARY KEY,
    sender_user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    receiver_user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    
    -- Content
    message_type VARCHAR(20) DEFAULT 'text', -- text, image, video, post_share
    content TEXT,
    media_url TEXT,
    shared_post_id INTEGER REFERENCES posts(post_id),
    
    -- Status
    is_read BOOLEAN DEFAULT FALSE,
    is_deleted_by_sender BOOLEAN DEFAULT FALSE,
    is_deleted_by_receiver BOOLEAN DEFAULT FALSE,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMP
);

-- Indexes for messages
CREATE INDEX idx_sender_messages ON messages(sender_user_id, created_at DESC);
CREATE INDEX idx_receiver_messages ON messages(receiver_user_id, created_at DESC);
CREATE INDEX idx_conversation ON messages(sender_user_id, receiver_user_id, created_at DESC);

-- ============================================
-- STORIES TABLE (Instagram-style)
-- ============================================
CREATE TABLE stories (
    story_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    
    -- Content
    media_type VARCHAR(20) NOT NULL, -- image, video
    media_url TEXT NOT NULL,
    thumbnail_url TEXT,
    
    -- Engagement
    views_count INTEGER DEFAULT 0,
    
    -- Expiration (24 hours)
    expires_at TIMESTAMP NOT NULL,
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for stories
CREATE INDEX idx_user_stories ON stories(user_id, created_at DESC);
CREATE INDEX idx_active_stories ON stories(is_active, expires_at);

-- ============================================
-- STORY_VIEWS TABLE
-- ============================================
CREATE TABLE story_views (
    view_id SERIAL PRIMARY KEY,
    story_id INTEGER NOT NULL REFERENCES stories(story_id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Prevent duplicate views
    UNIQUE(story_id, user_id)
);

-- Indexes for story_views
CREATE INDEX idx_story_views ON story_views(story_id);

-- ============================================
-- NOTIFICATIONS TABLE
-- ============================================
CREATE TABLE notifications (
    notification_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    
    -- Content
    notification_type VARCHAR(50) NOT NULL, -- like, comment, follow, mention, etc.
    actor_user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    
    -- Related Objects
    post_id INTEGER REFERENCES posts(post_id) ON DELETE CASCADE,
    comment_id INTEGER REFERENCES comments(comment_id) ON DELETE CASCADE,
    
    -- Message
    message TEXT,
    
    -- Status
    is_read BOOLEAN DEFAULT FALSE,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for notifications
CREATE INDEX idx_user_notifications ON notifications(user_id, is_read, created_at DESC);

-- ============================================
-- CRYPTO_TRANSACTIONS TABLE
-- ============================================
CREATE TABLE crypto_transactions (
    transaction_id SERIAL PRIMARY KEY,
    from_user_id INTEGER REFERENCES users(user_id),
    to_user_id INTEGER REFERENCES users(user_id),
    
    -- Transaction Details
    transaction_type VARCHAR(50) NOT NULL, -- tip, reward, nft_purchase
    amount DECIMAL(18, 8) NOT NULL,
    currency VARCHAR(10) NOT NULL, -- ETH, BTC, etc.
    
    -- Blockchain Data
    blockchain_tx_hash VARCHAR(66),
    blockchain_network VARCHAR(50), -- mainnet, sepolia, etc.
    contract_address VARCHAR(42),
    
    -- Related Objects
    post_id INTEGER REFERENCES posts(post_id),
    
    -- Status
    status VARCHAR(20) DEFAULT 'pending', -- pending, confirmed, failed
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    confirmed_at TIMESTAMP
);

-- Indexes for crypto_transactions
CREATE INDEX idx_from_user ON crypto_transactions(from_user_id);
CREATE INDEX idx_to_user ON crypto_transactions(to_user_id);
CREATE INDEX idx_tx_hash ON crypto_transactions(blockchain_tx_hash);

-- ============================================
-- SESSIONS TABLE (for auth tokens)
-- ============================================
CREATE TABLE sessions (
    session_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    
    -- Session Data
    token VARCHAR(255) UNIQUE NOT NULL,
    refresh_token VARCHAR(255) UNIQUE,
    
    -- Device Info
    device_type VARCHAR(50),
    device_name VARCHAR(100),
    ip_address VARCHAR(45),
    user_agent TEXT,
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL,
    last_activity_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for sessions
CREATE INDEX idx_token ON sessions(token);
CREATE INDEX idx_user_sessions ON sessions(user_id, is_active);

-- ============================================
-- TRIGGERS FOR AUTO-UPDATE TIMESTAMPS
-- ============================================

-- Users updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_posts_updated_at BEFORE UPDATE ON posts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_comments_updated_at BEFORE UPDATE ON comments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- SAMPLE DATA (for testing)
-- ============================================

-- Insert demo users
INSERT INTO users (username, email, password_hash, display_name, bio, wallet_address) VALUES
('demo_user', 'demo@rustaceaans.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5ztJ.6Gu5NTNq', 'Demo User', 'Test account for Rustaceaans', '0x1234567890123456789012345678901234567890'),
('alice', 'alice@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5ztJ.6Gu5NTNq', 'Alice Wonder', 'Crypto enthusiast', '0x2234567890123456789012345678901234567890'),
('bob', 'bob@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5ztJ.6Gu5NTNq', 'Bob Builder', 'Building the future', '0x3234567890123456789012345678901234567890');
