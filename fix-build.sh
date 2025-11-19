#!/bin/bash

# Quick fix script for building on Linode when Rust isn't available for thebible user
# Run this on your Linode server: sudo ./fix-build.sh

set -e

APP_DIR="/opt/thebible"
APP_USER="thebible"

echo "=== Fixing Build Environment ==="

# Check if Rust is installed for root
if [ ! -f "/root/.cargo/bin/cargo" ]; then
    echo "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source /root/.cargo/env
fi

# Ensure Rust is in PATH
export PATH="/root/.cargo/bin:$PATH"

cd $APP_DIR

echo "Building application (this may take several minutes)..."
cargo build --release

echo "Setting ownership..."
chown -R $APP_USER:$APP_USER target/
chown -R $APP_USER:$APP_USER Cargo.lock 2>/dev/null || true

echo "Build complete!"
echo "Restarting service..."
systemctl restart thebible
systemctl status thebible

