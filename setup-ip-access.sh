#!/bin/bash

# Setup Nginx for IP address access (HTTP only - no SSL)
# This allows you to access the site via IP while waiting for DNS/SSL
# Run this on your Linode server: sudo ./setup-ip-access.sh

set -e

APP_PORT="3000"
LINODE_IP=$(hostname -I | awk '{print $1}')

echo "=== Setting up IP Access (HTTP Only) ==="
echo "Your Linode IP: $LINODE_IP"
echo ""
echo "⚠ Note: This will allow HTTP access via IP address"
echo "   SSL/HTTPS requires a domain name"
echo ""

# Update Nginx configuration to accept IP access
cat > /etc/nginx/sites-available/thebible << EOF
# IP Access Configuration (HTTP only)
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;  # Accept any hostname/IP

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

# Test Nginx configuration
echo "Testing Nginx configuration..."
nginx -t

# Reload Nginx
echo "Reloading Nginx..."
systemctl reload nginx

echo ""
echo "✓ Configuration updated!"
echo ""
echo "You can now access your site at:"
echo "  http://$LINODE_IP"
echo ""
echo "⚠ Browser will show 'Not Secure' warning - this is normal for HTTP"
echo ""
echo "To set up SSL/HTTPS with your domain:"
echo "1. Configure DNS to point your domain to: $LINODE_IP"
echo "2. Wait for DNS propagation (5-60 minutes)"
echo "3. Run: sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com"
echo ""

