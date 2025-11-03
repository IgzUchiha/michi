#!/bin/bash

echo "🚀 Rustaceaans Mobile - Setup Script"
echo "===================================="
echo ""

# Check Node.js
echo "📦 Checking Node.js..."
if ! command -v node &> /dev/null; then
    echo "❌ Node.js not found. Please install Node.js 18+ from https://nodejs.org"
    exit 1
fi
echo "✅ Node.js $(node --version) found"

# Check npm
echo "📦 Checking npm..."
if ! command -v npm &> /dev/null; then
    echo "❌ npm not found. Please install npm"
    exit 1
fi
echo "✅ npm $(npm --version) found"

# Install dependencies
echo ""
echo "📥 Installing dependencies..."
npm install

if [ $? -ne 0 ]; then
    echo "❌ Failed to install dependencies"
    exit 1
fi
echo "✅ Dependencies installed"

# Create .env if not exists
echo ""
if [ ! -f .env ]; then
    echo "📝 Creating .env file..."
    cp .env.example .env
    echo "✅ .env created from template"
    echo ""
    echo "⚠️  IMPORTANT: Edit .env and update API_URL with your local IP address!"
    echo "   Find your IP:"
    echo "   - Mac: ipconfig getifaddr en0"
    echo "   - Linux: hostname -I | awk '{print \$1}'"
    echo ""
else
    echo "ℹ️  .env already exists, skipping..."
fi

# Check if backend is running
echo ""
echo "🔍 Checking if backend is running..."
if curl -s http://127.0.0.1:8000/memes > /dev/null 2>&1; then
    echo "✅ Backend is running!"
else
    echo "⚠️  Backend not detected on http://127.0.0.1:8000"
    echo "   Start it with: cd .. && cargo run"
fi

echo ""
echo "🎉 Setup complete!"
echo ""
echo "📱 Next steps:"
echo "   1. Edit .env with your local IP address"
echo "   2. Start Expo: npm start"
echo "   3. Press 'i' for iOS or 'a' for Android"
echo "   4. Or scan QR code with Expo Go"
echo ""
echo "📚 Documentation:"
echo "   - Quick Start: cat QUICKSTART.md"
echo "   - Full Docs: cat README.md"
echo ""
