#!/bin/bash

# Script to verify files are uploaded and fix if needed
# Run this on your Linode server: sudo ./verify-and-fix-upload.sh

set -e

APP_DIR="/opt/thebible"
SERVER_IP="${1:-}"

echo "=== Verifying Application Files ==="

# Check if running on server or locally
if [ -f "/opt/thebible/Cargo.toml" ]; then
    echo "Running on server - checking files..."
    cd $APP_DIR
    
    echo "Files in $APP_DIR:"
    ls -la
    
    echo ""
    echo "Checking for required files:"
    
    if [ ! -f "Cargo.toml" ]; then
        echo "ERROR: Cargo.toml not found!"
        echo "Please upload files using one of these methods:"
        echo ""
        echo "From your local machine:"
        echo "  rsync -avz --progress src/ static/ Cargo.toml Cargo.lock \\"
        echo "    root@YOUR_LINODE_IP:/opt/thebible/"
        exit 1
    fi
    
    if [ ! -d "src" ]; then
        echo "ERROR: src/ directory not found!"
        exit 1
    fi
    
    if [ ! -d "static" ]; then
        echo "ERROR: static/ directory not found!"
        exit 1
    fi
    
    echo "✓ All required files found!"
    echo ""
    echo "You can now build with:"
    echo "  cd /opt/thebible"
    echo "  export PATH=\"/root/.cargo/bin:\$PATH\""
    echo "  cargo build --release"
    
else
    # Running locally - help upload files
    if [ -z "$SERVER_IP" ]; then
        echo "Usage: $0 root@your-linode-ip"
        echo ""
        echo "This script will help you upload files to your Linode server."
        exit 1
    fi
    
    echo "Running locally - preparing to upload files to $SERVER_IP"
    echo ""
    
    # Check if required files exist locally
    if [ ! -f "Cargo.toml" ]; then
        echo "ERROR: Cargo.toml not found in current directory!"
        echo "Please run this script from the TheBible project directory."
        exit 1
    fi
    
    echo "Files to upload:"
    echo "  - Cargo.toml"
    echo "  - Cargo.lock"
    echo "  - src/ directory"
    echo "  - static/ directory"
    echo ""
    
    read -p "Continue with upload? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
    
    echo "Uploading files..."
    
    # Create directory on server
    ssh $SERVER_IP "mkdir -p $APP_DIR && chown thebible:thebible $APP_DIR 2>/dev/null || chown root:root $APP_DIR"
    
    # Upload files
    rsync -avz --progress \
        --exclude='target' \
        --exclude='.git' \
        --exclude='*.md' \
        --exclude='.env' \
        --exclude='.DS_Store' \
        src/ \
        static/ \
        Cargo.toml \
        Cargo.lock \
        $SERVER_IP:$APP_DIR/
    
    echo ""
    echo "✓ Files uploaded successfully!"
    echo ""
    echo "Next steps on your server:"
    echo "  ssh $SERVER_IP"
    echo "  cd /opt/thebible"
    echo "  export PATH=\"/root/.cargo/bin:\$PATH\""
    echo "  cargo build --release"
fi

