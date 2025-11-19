#!/bin/bash

# Post-build setup script - Run this on your Linode server after build completes
# Usage: sudo ./post-build-setup.sh

set -e

APP_DIR="/opt/thebible"
APP_USER="thebible"
APP_NAME="thebible"
APP_PORT="3000"

echo "=== Post-Build Setup ==="

cd $APP_DIR

# Step 1: Verify binary exists
echo "[1/6] Verifying binary..."
if [ ! -f "$APP_DIR/target/release/server" ]; then
    echo "ERROR: Binary not found at $APP_DIR/target/release/server"
    exit 1
fi

ls -lh target/release/server
echo "✓ Binary found"

# Step 2: Set proper ownership
echo "[2/6] Setting ownership..."
chown -R $APP_USER:$APP_USER target/
chown -R $APP_USER:$APP_USER .
echo "✓ Ownership set"

# Step 3: Ensure .env file exists
echo "[3/6] Checking .env file..."
if [ ! -f "$APP_DIR/.env" ]; then
    echo "Creating .env file..."
    cat > $APP_DIR/.env << EOF
HOST=127.0.0.1
PORT=$APP_PORT
BIBLE_API_BASE_URL=https://bible.helloao.org/api
RUST_LOG=info
EOF
    chown $APP_USER:$APP_USER $APP_DIR/.env
    chmod 600 $APP_DIR/.env
    echo "✓ .env file created"
else
    echo "✓ .env file exists"
fi

# Step 4: Create/update systemd service
echo "[4/6] Setting up systemd service..."
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
echo "✓ Systemd service configured"

# Step 5: Configure Nginx (if not already done)
echo "[5/6] Configuring Nginx..."
if [ ! -f "/etc/nginx/sites-available/${APP_NAME}" ]; then
    cat > /etc/nginx/sites-available/${APP_NAME} << EOF
server {
    listen 80;
    server_name _;

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
        
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
EOF

    if [ ! -L "/etc/nginx/sites-enabled/${APP_NAME}" ]; then
        ln -s /etc/nginx/sites-available/${APP_NAME} /etc/nginx/sites-enabled/
    fi
    
    # Remove default site if it exists
    rm -f /etc/nginx/sites-enabled/default
    
    nginx -t
    systemctl restart nginx
    echo "✓ Nginx configured"
else
    echo "✓ Nginx already configured"
fi

# Step 6: Start the service
echo "[6/6] Starting service..."
systemctl restart ${APP_NAME}
sleep 2

if systemctl is-active --quiet ${APP_NAME}; then
    echo "✓ Service is running!"
else
    echo "⚠ Service may have issues. Check with: systemctl status ${APP_NAME}"
fi

# Summary
echo ""
echo "=== Setup Complete! ==="
echo ""
echo "Service Status:"
systemctl status ${APP_NAME} --no-pager -l | head -15
echo ""
echo "Next Steps:"
echo "1. Test locally: curl http://127.0.0.1:$APP_PORT/health"
echo "2. Test via domain: curl http://$(hostname -I | awk '{print $1}')/health"
echo "3. View logs: journalctl -u ${APP_NAME} -f"
echo "4. Set up SSL: certbot --nginx -d your-domain.com"
echo ""
echo "Your server should now be accessible!"

