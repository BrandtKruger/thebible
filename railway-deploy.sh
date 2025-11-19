#!/bin/bash
# Quick Railway deployment script

set -e

echo "🚀 Deploying The Bible to Railway..."
echo ""

# Check if Railway CLI is installed
if ! command -v railway &> /dev/null; then
    echo "📦 Installing Railway CLI..."
    npm i -g @railway/cli
fi

# Check if logged in
if ! railway whoami &> /dev/null; then
    echo "🔐 Please login to Railway..."
    railway login
fi

# Check if project is initialized
if [ ! -f "railway.json" ]; then
    echo "📝 Initializing Railway project..."
    railway init
fi

# Check if environment variables are set
echo "🔑 Checking environment variables..."
if ! railway variables 2>/dev/null | grep -q "BIBLE_BRAIN_API_KEY"; then
    echo "⚠️  BIBLE_BRAIN_API_KEY not set!"
    echo "Please set it with: railway variables set BIBLE_BRAIN_API_KEY=your_key_here"
    read -p "Do you want to set it now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "Enter your BIBLE_BRAIN_API_KEY: " api_key
        railway variables set BIBLE_BRAIN_API_KEY="$api_key"
    else
        echo "Please set BIBLE_BRAIN_API_KEY before deploying"
        exit 1
    fi
fi

# Set other environment variables if not set
railway variables set HOST=0.0.0.0 2>/dev/null || true
railway variables set PORT=3000 2>/dev/null || true
railway variables set RUST_LOG=thebible=info,tower_http=info 2>/dev/null || true

echo "🚀 Deploying..."
railway up

echo ""
echo "✅ Deployment complete!"
echo ""
echo "📋 Next steps:"
echo "1. Get your deployment URL: railway domain"
echo "2. Add custom domain: railway domain add krugerbdg.com"
echo "3. Update DNS records as instructed"
echo "4. Wait for DNS propagation (5-60 minutes)"
echo ""
echo "View logs: railway logs"
echo "Open dashboard: railway dashboard"

