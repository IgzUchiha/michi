# 🧪 API Testing Guide

## Setup & Run

### 1. Setup Database (One-time)
```bash
cd database
./setup.sh
```

### 2. Start Backend
```bash
cargo run
```

You should see:
```
✅ Connected to PostgreSQL database
🔐 Authentication system enabled
🚀 Server starting on 0.0.0.0:8000
```

## Test Authentication Endpoints

### 1. Register a New User

**POST** `http://localhost:8000/auth/register`

```bash
curl -X POST http://localhost:8000/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "password123",
    "display_name": "Test User"
  }'
```

**Response:**
```json
{
  "user": {
    "user_id": 1,
    "username": "testuser",
    "email": "test@example.com",
    "display_name": "Test User",
    "bio": null,
    "profile_picture_url": null,
    "wallet_address": null,
    "followers_count": 0,
    "following_count": 0,
    "posts_count": 0,
    "created_at": "2025-01-02T12:34:56"
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expires_at": "2025-01-09T12:34:56Z"
}
```

**Save the token** - you'll need it for authenticated requests!

### 2. Login

**POST** `http://localhost:8000/auth/login`

```bash
curl -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

**Response:** Same as register

### 3. Get Current User (Protected)

**GET** `http://localhost:8000/auth/me`

```bash
# Replace YOUR_TOKEN with the token from register/login
curl -X GET http://localhost:8000/auth/me \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Response:**
```json
{
  "user_id": 1,
  "username": "testuser",
  "email": "test@example.com",
  "display_name": "Test User",
  ...
}
```

### 4. Logout

**POST** `http://localhost:8000/auth/logout`

```bash
curl -X POST http://localhost:8000/auth/logout \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Response:**
```json
{
  "message": "Logged out successfully"
}
```

## Test with Postman

### Import Collection

Create a new Postman collection with these requests:

1. **Register**
   - Method: POST
   - URL: `http://localhost:8000/auth/register`
   - Body (JSON):
     ```json
     {
       "username": "alice",
       "email": "alice@example.com",
       "password": "secure123",
       "display_name": "Alice Wonder"
     }
     ```

2. **Login**
   - Method: POST
   - URL: `http://localhost:8000/auth/login`
   - Body (JSON):
     ```json
     {
       "email": "alice@example.com",
       "password": "secure123"
     }
     ```

3. **Get Me**
   - Method: GET
   - URL: `http://localhost:8000/auth/me`
   - Headers: `Authorization: Bearer {{token}}`

4. **Logout**
   - Method: POST
   - URL: `http://localhost:8000/auth/logout`
   - Headers: `Authorization: Bearer {{token}}`

## Error Cases

### Invalid Email
```bash
curl -X POST http://localhost:8000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"test","email":"invalid","password":"test123"}'
```

**Response:** `400 Bad Request`
```json
{
  "error": "Validation failed",
  "details": "email: invalid email format"
}
```

### Email Already Exists
```bash
curl -X POST http://localhost:8000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"test2","email":"test@example.com","password":"test123"}'
```

**Response:** `400 Bad Request`
```json
{
  "error": "Email already registered"
}
```

### Wrong Password
```bash
curl -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"wrongpassword"}'
```

**Response:** `401 Unauthorized`
```json
{
  "error": "Invalid email or password"
}
```

### Invalid Token
```bash
curl -X GET http://localhost:8000/auth/me \
  -H "Authorization: Bearer invalid_token"
```

**Response:** `401 Unauthorized`

## Database Queries

### View All Users
```bash
psql rustaceaans -c "SELECT user_id, username, email, created_at FROM users;"
```

### View All Sessions
```bash
psql rustaceaans -c "SELECT session_id, user_id, is_active, expires_at FROM sessions;"
```

### Delete Test Users
```bash
psql rustaceaans -c "DELETE FROM users WHERE email LIKE '%@example.com';"
```

## Next Steps

Once auth works:

1. ✅ Test all 4 endpoints
2. ✅ Verify tokens work
3. ✅ Update mobile app to use new auth
4. ✅ Migrate existing users (optional)

---

**Ready to test!** 🚀

Run:
```bash
cd database && ./setup.sh
cd .. && cargo run
```

Then test with curl or Postman!
