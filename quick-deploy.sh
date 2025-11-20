#!/bin/bash

# Quick deployment script for The Bible application
# Uploads changed files and restarts the service
# Usage: ./quick-deploy.sh root@139.162.145.166

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check if server address is provided
if [ -z "$1" ]; then
    SERVER="root@139.162.145.166"
    echo -e "${YELLOW}Using default server: $SERVER${NC}"
else
    SERVER=$1
fi

APP_DIR="/opt/thebible"
APP_USER="thebible"

echo -e "${GREEN}=== Quick Deploy - The Bible ===${NC}\n"
echo "Server: $SERVER"
echo "Target directory: $APP_DIR"
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Check if rsync is available
if ! command -v rsync &> /dev/null; then
    echo -e "${RED}Error: rsync is required but not installed${NC}"
    echo "Install it with: brew install rsync (on macOS)"
    exit 1
fi

# Upload static files (HTML, CSS, JS)
echo -e "${YELLOW}[1/3] Uploading static files...${NC}"
rsync -avz --progress \
    static/ \
    $SERVER:$APP_DIR/static/

# Upload source files (in case of changes)
echo -e "${YELLOW}[2/3] Uploading source files...${NC}"
rsync -avz --progress \
    --exclude='target' \
    src/ \
    Cargo.toml \
    Cargo.lock \
    $SERVER:$APP_DIR/

# Set proper permissions
echo -e "${YELLOW}[3/3] Setting permissions...${NC}"
ssh $SERVER "chown -R $APP_USER:$APP_USER $APP_DIR/static $APP_DIR/src $APP_DIR/Cargo.toml $APP_DIR/Cargo.lock 2>/dev/null || true"

# Check if we need to rebuild (if Rust files changed)
echo -e "\n${YELLOW}Checking if rebuild is needed...${NC}"
NEEDS_REBUILD=false

# Check if any Rust source files changed
if ssh $SERVER "[ -f $APP_DIR/Cargo.toml ] && [ -f $APP_DIR/target/release/server ]"; then
    # Compare modification times
    LOCAL_CARGO=$(stat -f %m Cargo.toml 2>/dev/null || stat -c %Y Cargo.toml 2>/dev/null)
    REMOTE_CARGO=$(ssh $SERVER "stat -c %Y $APP_DIR/Cargo.toml 2>/dev/null || echo 0")
    
    if [ "$LOCAL_CARGO" -gt "$REMOTE_CARGO" ]; then
        NEEDS_REBUILD=true
    fi
else
    NEEDS_REBUILD=true
fi

if [ "$NEEDS_REBUILD" = true ]; then
    echo -e "${YELLOW}Rebuilding application (this may take a few minutes)...${NC}"
    ssh $SERVER "cd $APP_DIR && export PATH=\"/root/.cargo/bin:\$PATH\" && cargo build --release && chown -R $APP_USER:$APP_USER target/"
    
    if ssh $SERVER "[ ! -f $APP_DIR/target/release/server ]"; then
        echo -e "${RED}Error: Build failed${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Build successful!${NC}"
    echo -e "${YELLOW}Restarting service...${NC}"
    ssh $SERVER "systemctl restart thebible"
else
    echo -e "${GREEN}No rebuild needed (only static files changed)${NC}"
    echo -e "${YELLOW}Restarting service to ensure changes are loaded...${NC}"
    ssh $SERVER "systemctl restart thebible"
fi

# Wait a moment for service to start
sleep 2

# Check service status
echo -e "\n${YELLOW}Checking service status...${NC}"
if ssh $SERVER "systemctl is-active --quiet thebible"; then
    echo -e "${GREEN}✓ Service is running!${NC}"
else
    echo -e "${RED}✗ Service failed to start${NC}"
    echo "Check logs with: ssh $SERVER 'journalctl -u thebible -n 50'"
    exit 1
fi

echo -e "\n${GREEN}=== Deployment Complete! ===${NC}\n"
echo "Your changes have been deployed successfully."
echo ""
echo "View logs:"
echo "  ssh $SERVER 'journalctl -u thebible -f'"
echo ""
echo "Check status:"
echo "  ssh $SERVER 'systemctl status thebible'"

