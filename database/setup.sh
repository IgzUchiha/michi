#!/bin/bash

echo "🗄️  Rustaceaans Database Setup"
echo "=============================="
echo ""

# Check if PostgreSQL is installed
if ! command -v psql &> /dev/null; then
    echo "❌ PostgreSQL not found"
    echo "📥 Installing PostgreSQL..."
    brew install postgresql@14
    brew services start postgresql@14
    echo "✅ PostgreSQL installed and started"
else
    echo "✅ PostgreSQL found"
fi

# Create database
echo ""
echo "📊 Creating database..."
createdb rustaceaans 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✅ Database 'rustaceaans' created"
else
    echo "ℹ️  Database 'rustaceaans' already exists"
fi

# Run schema
echo ""
echo "📝 Running schema..."
psql rustaceaans < schema.sql

if [ $? -eq 0 ]; then
    echo "✅ Schema created successfully"
else
    echo "❌ Failed to create schema"
    exit 1
fi

# Generate JWT secret
echo ""
echo "🔐 Generating JWT secret..."
JWT_SECRET=$(openssl rand -base64 32)

# Update .env file
echo ""
echo "📄 Creating .env configuration..."
cat > ../.env << EOF
# Database
DATABASE_URL=postgresql://$(whoami)@localhost/rustaceaans

# JWT Authentication
JWT_SECRET=$JWT_SECRET
JWT_EXPIRY=7d

# Server
PORT=8000
RUST_LOG=info

# Storage (optional - for S3)
# AWS_ACCESS_KEY_ID=your_key
# AWS_SECRET_ACCESS_KEY=your_secret
# AWS_REGION=us-east-1
# S3_BUCKET=rustaceaans-uploads
EOF

echo "✅ .env file created"

# Test connection
echo ""
echo "🧪 Testing database connection..."
psql rustaceaans -c "SELECT COUNT(*) as user_count FROM users;" > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "✅ Database connection successful!"
else
    echo "❌ Database connection failed"
    exit 1
fi

echo ""
echo "🎉 Setup complete!"
echo ""
echo "📋 Next steps:"
echo "   1. Update Rust backend to use database"
echo "   2. Run: cargo run"
echo "   3. Test authentication endpoints"
echo ""
echo "🔗 Database URL: postgresql://$(whoami)@localhost/rustaceaans"
echo "🔑 JWT Secret: $JWT_SECRET"
echo ""
