# 🔐 Authentication Implementation Guide

## What We're Building

A **proper authentication system** with database storage - no more OAuth dependency! Users can create accounts with email/password, just like Instagram.

## 📊 Database Schema

### Users Table (Instagram-style)
```
users
├── user_id (PRIMARY KEY)
├── username (UNIQUE)
├── email (UNIQUE)
├── password_hash (bcrypt)
├── display_name
├── bio
├── profile_picture_url
├── wallet_address (for crypto features)
├── followers_count
├── following_count
├── created_at
└── updated_at
```

### Other Tables
- **posts** - User content
- **follows** - Social graph
- **likes** - Engagement
- **comments** - Discussions
- **messages** - DMs
- **sessions** - Auth tokens
- **crypto_transactions** - Tips/rewards

## 🚀 Quick Setup

### 1. Install & Setup Database

```bash
cd database
./setup.sh
```

This will:
- ✅ Install PostgreSQL
- ✅ Create `rustaceaans` database
- ✅ Run schema
- ✅ Generate JWT secret
- ✅ Create `.env` file

### 2. Backend Changes Needed

Update `Cargo.toml` dependencies (already there!):
```toml
sqlx = { version = "0.7", features = ["postgres", "runtime-tokio-rustls"] }
bcrypt = "0.15"
jsonwebtoken = "9.2"
```

### 3. Authentication Endpoints

The backend will have:

#### **POST /auth/register**
```json
{
  "username": "alice",
  "email": "alice@example.com",
  "password": "securepassword",
  "wallet_address": "0x..." // optional
}
```

Response:
```json
{
  "user_id": 1,
  "username": "alice",
  "email": "alice@example.com",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

#### **POST /auth/login**
```json
{
  "email": "alice@example.com",
  "password": "securepassword"
}
```

Response:
```json
{
  "user": {
    "user_id": 1,
    "username": "alice",
    "email": "alice@example.com",
    "display_name": "Alice Wonder",
    "profile_picture_url": "https://...",
    "wallet_address": "0x..."
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expires_at": "2025-01-10T00:00:00Z"
}
```

#### **POST /auth/logout**
Headers: `Authorization: Bearer <token>`

Response:
```json
{
  "message": "Logged out successfully"
}
```

#### **GET /auth/me**
Headers: `Authorization: Bearer <token>`

Response: User object

## 📱 Mobile App Changes

### New Auth Flow

Instead of OAuth buttons, show:

```tsx
// Login Screen
<TextInput placeholder="Email" />
<TextInput placeholder="Password" secureTextEntry />
<Button title="Sign In" onPress={handleLogin} />
<Button title="Create Account" onPress={() => navigate('Register')} />
```

### API Service Updates

```typescript
// src/services/api.ts

class APIService {
  async register(data: RegisterData) {
    const response = await this.client.post('/auth/register', data);
    return response.data;
  }

  async login(email: string, password: string) {
    const response = await this.client.post('/auth/login', { 
      email, 
      password 
    });
    return response.data;
  }

  async logout() {
    await this.client.post('/auth/logout');
  }

  async getCurrentUser() {
    const response = await this.client.get('/auth/me');
    return response.data;
  }
}
```

### Store JWT Token

```typescript
// src/stores/authStore.ts

export const useAuthStore = create<AuthState>((set) => ({
  user: null,
  token: null,
  
  login: async (email: string, password: string) => {
    const data = await apiService.login(email, password);
    await AsyncStorage.setItem('auth_token', data.token);
    set({ user: data.user, token: data.token });
  },

  logout: async () => {
    await apiService.logout();
    await AsyncStorage.removeItem('auth_token');
    set({ user: null, token: null });
  },
}));
```

## 🔄 Implementation Steps

### Phase 1: Database Setup ✅
- [x] Create schema
- [x] Setup script
- [x] Test connection

### Phase 2: Backend Auth
- [ ] Add SQLx connection pool
- [ ] Create auth endpoints
  - [ ] POST /auth/register
  - [ ] POST /auth/login
  - [ ] POST /auth/logout
  - [ ] GET /auth/me
- [ ] Add JWT middleware
- [ ] Password hashing (bcrypt)
- [ ] Session management

### Phase 3: Mobile App
- [ ] Create RegisterScreen
- [ ] Update AuthScreen (email/password)
- [ ] Update API service
- [ ] Token storage (AsyncStorage)
- [ ] Auto-refresh tokens
- [ ] Handle auth errors

### Phase 4: Migration
- [ ] Migrate existing demo users
- [ ] Update all endpoints to use database
- [ ] Test thoroughly
- [ ] Deploy

## 🎯 Benefits

### Over OAuth:
- ✅ **Full control** - No external dependencies
- ✅ **Faster** - No OAuth redirects
- ✅ **Simpler** - Just email/password
- ✅ **Offline-friendly** - Works everywhere
- ✅ **Cost-free** - No OAuth provider fees

### Additional Features:
- ✅ **Email verification** (can add later)
- ✅ **Password reset** (can add later)
- ✅ **2FA** (can add later)
- ✅ **Social login** (can still add OAuth as option)

## 🔐 Security Features

1. **Password Hashing** - bcrypt with 12 rounds
2. **JWT Tokens** - Signed with secret key
3. **Session Management** - Track active sessions
4. **SQL Injection Protection** - Parameterized queries
5. **Rate Limiting** - Prevent brute force
6. **HTTPS Only** - Secure transmission

## 📝 Example User Flow

### Registration
1. User enters: email, username, password
2. Backend validates & hashes password
3. Creates user in database
4. Returns JWT token
5. User is logged in!

### Login
1. User enters: email, password
2. Backend verifies password
3. Creates new session
4. Returns JWT token
5. User is logged in!

### Making Requests
```typescript
// All API requests include token
axios.defaults.headers.common['Authorization'] = `Bearer ${token}`;
```

## 🧪 Testing

### Test Users (from schema.sql)
```
Email: demo@rustaceaans.com
Password: password123

Email: alice@example.com
Password: password123

Email: bob@example.com
Password: password123
```

## 🚀 Next Steps

1. **Run database setup**:
   ```bash
   cd database
   ./setup.sh
   ```

2. **I'll update the Rust backend** with:
   - Database connection pool
   - Auth endpoints
   - JWT middleware

3. **Update mobile app** with:
   - New auth screens
   - Token management
   - Updated API calls

Want me to implement the backend auth endpoints now? 🔧
