# 🗄️ Database Setup Guide

## Overview

This app uses **PostgreSQL** (or MySQL) for persistent data storage. The schema is designed like Instagram with proper relationships, indexes, and crypto features.

## Quick Start

### Option 1: PostgreSQL (Recommended)

```bash
# Install PostgreSQL
brew install postgresql@14

# Start PostgreSQL
brew services start postgresql@14

# Create database
createdb rustaceaans

# Run schema
psql rustaceaans < database/schema.sql
```

### Option 2: MySQL

```bash
# Install MySQL
brew install mysql

# Start MySQL
brew services start mysql

# Create database
mysql -u root -e "CREATE DATABASE rustaceaans;"

# Run schema (after converting syntax)
mysql -u root rustaceaans < database/schema_mysql.sql
```

## Database Schema

### Core Tables

1. **users** - User accounts and profiles
2. **posts** - User-generated content
3. **follows** - Social graph (who follows whom)
4. **likes** - Post engagement
5. **comments** - Post discussions
6. **messages** - Direct messaging
7. **stories** - 24-hour ephemeral content
8. **notifications** - User notifications
9. **crypto_transactions** - Blockchain transactions
10. **sessions** - Auth tokens and sessions

### Key Features

- ✅ **Auto-incrementing IDs** (user_id, post_id, etc.)
- ✅ **Timestamps** (created_at, updated_at)
- ✅ **Indexes** for fast queries
- ✅ **Foreign keys** with cascade deletes
- ✅ **Unique constraints** (prevent duplicate follows/likes)
- ✅ **Triggers** for auto-updating timestamps

## Connection Configuration

### Update `.env` file:

```bash
# Database
DATABASE_URL=postgresql://username:password@localhost/rustaceaans

# Or for MySQL
DATABASE_URL=mysql://username:password@localhost/rustaceaans

# JWT Secret (generate with: openssl rand -base64 32)
JWT_SECRET=your_secret_key_here
JWT_EXPIRY=7d
```

## Backend Integration

The Rust backend uses **SQLx** for async database queries:

```rust
// In main.rs
use sqlx::postgres::PgPoolOptions;

let pool = PgPoolOptions::new()
    .max_connections(5)
    .connect(&database_url)
    .await?;
```

## Authentication Flow

### 1. Registration
```sql
INSERT INTO users (username, email, password_hash, wallet_address)
VALUES ($1, $2, $3, $4)
RETURNING user_id, username, email;
```

### 2. Login
```sql
SELECT user_id, username, email, password_hash, wallet_address
FROM users
WHERE email = $1 AND is_active = TRUE;
```

### 3. Create Session
```sql
INSERT INTO sessions (user_id, token, expires_at)
VALUES ($1, $2, NOW() + INTERVAL '7 days')
RETURNING session_id, token;
```

## Common Queries

### Get User Feed
```sql
-- Posts from followed users
SELECT p.*, u.username, u.profile_picture_url
FROM posts p
JOIN users u ON p.user_id = u.user_id
WHERE p.user_id IN (
    SELECT following_user_id
    FROM follows
    WHERE follower_user_id = $1
)
ORDER BY p.created_at DESC
LIMIT 20;
```

### Get Post with Engagement
```sql
SELECT 
    p.*,
    u.username,
    u.profile_picture_url,
    COUNT(DISTINCT l.like_id) as likes_count,
    COUNT(DISTINCT c.comment_id) as comments_count,
    EXISTS(
        SELECT 1 FROM likes 
        WHERE post_id = p.post_id AND user_id = $2
    ) as is_liked_by_user
FROM posts p
JOIN users u ON p.user_id = u.user_id
LEFT JOIN likes l ON p.post_id = l.post_id
LEFT JOIN comments c ON p.post_id = c.post_id
WHERE p.post_id = $1
GROUP BY p.post_id, u.user_id;
```

## Migrations

Create migrations for schema changes:

```bash
# Create migration
sqlx migrate add create_users_table

# Run migrations
sqlx migrate run

# Revert migration
sqlx migrate revert
```

## Backup & Restore

### Backup
```bash
# PostgreSQL
pg_dump rustaceaans > backup_$(date +%Y%m%d).sql

# MySQL
mysqldump rustaceaans > backup_$(date +%Y%m%d).sql
```

### Restore
```bash
# PostgreSQL
psql rustaceaans < backup_20250102.sql

# MySQL
mysql rustaceaans < backup_20250102.sql
```

## Performance Tips

1. **Indexes** - Already added for common queries
2. **Connection pooling** - Use SQLx pool (max 5-10 connections)
3. **Query optimization** - Use EXPLAIN to analyze slow queries
4. **Caching** - Cache frequently accessed data (Redis optional)
5. **Pagination** - Always use LIMIT and OFFSET for lists

## Security

- ✅ **Password hashing** - bcrypt with 12 rounds
- ✅ **SQL injection protection** - Parameterized queries
- ✅ **Session tokens** - Secure random tokens
- ✅ **Foreign key constraints** - Data integrity
- ✅ **Cascade deletes** - Automatic cleanup

## Monitoring

### Check database size
```sql
SELECT pg_size_pretty(pg_database_size('rustaceaans'));
```

### Active connections
```sql
SELECT count(*) FROM pg_stat_activity;
```

### Slow queries
```sql
SELECT query, calls, total_time, mean_time
FROM pg_stat_statements
ORDER BY total_time DESC
LIMIT 10;
```

## Next Steps

1. ✅ Install PostgreSQL/MySQL
2. ✅ Create database
3. ✅ Run schema.sql
4. ✅ Update .env with DATABASE_URL
5. ✅ Update Rust backend to use database
6. ✅ Test authentication endpoints
7. ✅ Update mobile app to use new auth

---

**Ready to build!** 🚀
