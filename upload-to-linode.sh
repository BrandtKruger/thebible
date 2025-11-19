#!/bin/bash

# Script to upload The Bible application files to Linode server
# Usage: ./upload-to-linode.sh root@your-linode-ip

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check if server address is provided
if [ -z "$1" ]; then
    echo -e "${RED}Usage: $0 root@your-linode-ip${NC}"
    echo "Example: $0 root@192.0.2.1"
    exit 1
fi

SERVER=$1
APP_DIR="/opt/thebible"

echo -e "${GREEN}=== Uploading The Bible to Linode ===${NC}\n"
echo "Server: $SERVER"
echo "Target directory: $APP_DIR"
echo ""

# Check if rsync is available
if ! command -v rsync &> /dev/null; then
    echo -e "${YELLOW}rsync not found, using scp instead...${NC}\n"
    USE_SCP=true
else
    USE_SCP=false
fi

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo -e "${YELLOW}Uploading files...${NC}"

if [ "$USE_SCP" = true ]; then
    # Using SCP
    echo "Creating directory on server..."
    ssh $SERVER "mkdir -p $APP_DIR && chown thebible:thebible $APP_DIR 2>/dev/null || true"
    
    echo "Uploading files (this may take a few minutes)..."
    scp -r \
        --exclude='target' \
        --exclude='.git' \
        --exclude='.cursor' \
        --exclude='*.md' \
        --exclude='.env' \
        src/ static/ Cargo.toml Cargo.lock \
        $SERVER:$APP_DIR/
else
    # Using rsync (preferred - faster and more efficient)
    echo "Creating directory on server..."
    ssh $SERVER "mkdir -p $APP_DIR && chown thebible:thebible $APP_DIR 2>/dev/null || true"
    
    echo "Uploading files (this may take a few minutes)..."
    rsync -avz --progress \
        --exclude='target' \
        --exclude='.git' \
        --exclude='.cursor' \
        --exclude='*.md' \
        --exclude='.env' \
        --exclude='node_modules' \
        --exclude='.DS_Store' \
        src/ \
        static/ \
        Cargo.toml \
        Cargo.lock \
        $SERVER:$APP_DIR/
fi

echo -e "\n${GREEN}Files uploaded successfully!${NC}\n"

# Set proper permissions
echo -e "${YELLOW}Setting permissions...${NC}"
ssh $SERVER "chown -R thebible:thebible $APP_DIR 2>/dev/null || chown -R root:root $APP_DIR"

echo -e "\n${GREEN}=== Upload Complete ===${NC}\n"
echo "Next steps:"
echo "1. SSH into your server:"
echo "   ssh $SERVER"
echo ""
echo "2. Run the deployment script:"
echo "   cd $APP_DIR"
echo "   chmod +x linode-deploy.sh"
echo "   ./linode-deploy.sh"
echo ""
echo "Or if you've already run the script, just rebuild:"
echo "   cd $APP_DIR"
echo "   sudo -u thebible bash -c 'source ~/.cargo/env && cargo build --release'"
echo "   sudo systemctl restart thebible"

