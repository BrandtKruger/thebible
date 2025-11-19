#!/bin/bash

# The Bible - Linode Ubuntu Deployment Script
# This script automates the deployment of The Bible web server to Ubuntu Linode

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration variables
APP_NAME="thebible"
APP_USER="thebible"
APP_DIR="/opt/thebible"
APP_PORT="3000"
DOMAIN_NAME="krugerbdg.com"
NGINX_SITE="thebible"

echo -e "${GREEN}=== The Bible - Linode Deployment Script ===${NC}\n"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root or with sudo${NC}"
    exit 1
fi

# Step 1: Update system
echo -e "${YELLOW}[1/12] Updating system packages...${NC}"
apt update && apt upgrade -y

# Step 2: Install required packages
echo -e "${YELLOW}[2/12] Installing required packages...${NC}"
apt install -y \
    curl \
    build-essential \
    pkg-config \
    libssl-dev \
    nginx \
    certbot \
    python3-certbot-nginx \
    git \
    ufw

# Step 3: Install Rust
echo -e "${YELLOW}[3/12] Installing Rust...${NC}"
if ! command -v rustc &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env
    rustup default stable
else
    echo "Rust already installed, skipping..."
fi

# Step 4: Create application user
echo -e "${YELLOW}[4/12] Creating application user...${NC}"
if id "$APP_USER" &>/dev/null; then
    echo "User $APP_USER already exists, skipping..."
else
    useradd -r -s /bin/false -d $APP_DIR $APP_USER
fi

# Step 5: Create application directory
echo -e "${YELLOW}[5/12] Creating application directory...${NC}"
mkdir -p $APP_DIR
chown $APP_USER:$APP_USER $APP_DIR

# Step 6: Check if application files exist
echo -e "${YELLOW}[6/12] Checking application files...${NC}"
if [ ! -f "$APP_DIR/Cargo.toml" ]; then
    echo -e "${RED}Error: Application files not found in $APP_DIR${NC}"
    echo "Please upload your application files to $APP_DIR first."
    echo "You can use:"
    echo "  - Git: cd $APP_DIR && git clone <your-repo-url> ."
    echo "  - SCP: scp -r /path/to/TheBible/* root@your-server:$APP_DIR/"
    echo "  - SFTP: Upload files to $APP_DIR"
    exit 1
fi

# Step 7: Create .env file if it doesn't exist
echo -e "${YELLOW}[7/12] Configuring environment variables...${NC}"
if [ ! -f "$APP_DIR/.env" ]; then
    cat > $APP_DIR/.env << EOF
HOST=127.0.0.1
PORT=$APP_PORT
BIBLE_API_BASE_URL=https://bible.helloao.org/api
RUST_LOG=info
EOF
    chown $APP_USER:$APP_USER $APP_DIR/.env
    chmod 600 $APP_DIR/.env
    echo "Created .env file with default values"
else
    echo ".env file already exists, skipping..."
fi

# Step 8: Build the application
echo -e "${YELLOW}[8/12] Building application (this may take several minutes)...${NC}"
cd $APP_DIR

# Install Rust for the application user if needed
if [ ! -f "/home/$APP_USER/.cargo/bin/cargo" ] && [ ! -f "/root/.cargo/bin/cargo" ]; then
    echo "Installing Rust for build..."
    # Install Rust system-wide or for root
    if [ ! -f "/root/.cargo/bin/cargo" ]; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source /root/.cargo/env
    fi
fi

# Build as root (since thebible user doesn't have Rust installed)
# We'll change ownership after build
echo "Building application..."
export PATH="/root/.cargo/bin:$PATH"
cargo build --release

# Change ownership of build artifacts
chown -R $APP_USER:$APP_USER target/

# Verify binary exists
if [ ! -f "$APP_DIR/target/release/server" ]; then
    echo -e "${RED}Error: Build failed - binary not found${NC}"
    exit 1
fi

echo -e "${GREEN}Build successful!${NC}"

# Step 9: Create systemd service
echo -e "${YELLOW}[9/12] Creating systemd service...${NC}"
cat > /etc/systemd/system/${APP_NAME}.service << EOF
[Unit]
Description=The Bible Web Server
After=network.target

[Service]
Type=simple
User=$APP_USER
Group=$APP_USER
WorkingDirectory=$APP_DIR
EnvironmentFile=$APP_DIR/.env
ExecStart=$APP_DIR/target/release/server
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=$APP_NAME

# Security hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$APP_DIR

# Resource limits
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable ${APP_NAME}

# Step 10: Configure Nginx
echo -e "${YELLOW}[10/12] Configuring Nginx...${NC}"
cat > /etc/nginx/sites-available/${NGINX_SITE} << EOF
server {
    listen 80;
    server_name $DOMAIN_NAME www.$DOMAIN_NAME;

    # Increase body size for large requests
    client_max_body_size 10M;

    location / {
        proxy_pass http://127.0.0.1:$APP_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
EOF

# Enable site
if [ ! -L /etc/nginx/sites-enabled/${NGINX_SITE} ]; then
    ln -s /etc/nginx/sites-available/${NGINX_SITE} /etc/nginx/sites-enabled/
fi

# Test Nginx configuration
nginx -t

# Step 11: Configure firewall
echo -e "${YELLOW}[11/12] Configuring firewall...${NC}"
ufw --force enable
ufw allow 22/tcp comment 'SSH'
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'

# Step 12: Start services
echo -e "${YELLOW}[12/12] Starting services...${NC}"
systemctl restart nginx
systemctl start ${APP_NAME}

# Wait a moment for service to start
sleep 2

# Check service status
if systemctl is-active --quiet ${APP_NAME}; then
    echo -e "${GREEN}Service is running!${NC}"
else
    echo -e "${RED}Service failed to start. Check logs with: sudo journalctl -u ${APP_NAME}${NC}"
    exit 1
fi

# Summary
echo -e "\n${GREEN}=== Deployment Complete! ===${NC}\n"
echo "Application: $APP_NAME"
echo "Directory: $APP_DIR"
echo "Service: ${APP_NAME}.service"
echo "Port: $APP_PORT"
echo "Domain: $DOMAIN_NAME"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Set up SSL certificate:"
echo "   sudo certbot --nginx -d $DOMAIN_NAME -d www.$DOMAIN_NAME"
echo ""
echo "2. Check service status:"
echo "   sudo systemctl status ${APP_NAME}"
echo ""
echo "3. View logs:"
echo "   sudo journalctl -u ${APP_NAME} -f"
echo ""
echo "4. Test the application:"
echo "   curl http://127.0.0.1:$APP_PORT/health"
echo "   curl http://$DOMAIN_NAME/health"
echo ""
echo -e "${GREEN}Deployment successful!${NC}"

