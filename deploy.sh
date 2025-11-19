#!/bin/bash
# Deployment script for The Bible web server
# Usage: ./deploy.sh [production|staging]

set -e

ENVIRONMENT=${1:-production}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🚀 Deploying The Bible web server ($ENVIRONMENT)..."

# Check if .env exists
if [ ! -f "$SCRIPT_DIR/.env" ]; then
    echo "❌ Error: .env file not found!"
    echo "Please create .env file with your configuration."
    exit 1
fi

# Build release binary
echo "📦 Building release binary..."
cd "$SCRIPT_DIR"
cargo build --release

if [ ! -f "$SCRIPT_DIR/target/release/server" ]; then
    echo "❌ Error: Build failed!"
    exit 1
fi

echo "✅ Build successful!"

# Check if systemd service exists
if systemctl list-unit-files | grep -q "thebible.service"; then
    echo "🔄 Restarting service..."
    sudo systemctl restart thebible
    sudo systemctl status thebible --no-pager
    echo "✅ Deployment complete!"
else
    echo "⚠️  Systemd service not found. Please set it up first."
    echo "See DEPLOYMENT.md for instructions."
fi

