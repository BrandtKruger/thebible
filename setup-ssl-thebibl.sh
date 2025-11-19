#!/bin/bash

# SSL Setup for TheBibl.com
# Run this on your Linode server: sudo ./setup-ssl-thebibl.sh

set -e

DOMAIN="TheBibl.com"
APP_PORT="3000"

echo "=== SSL Setup for $DOMAIN ==="

# Step 1: Get current Linode IP
LINODE_IP=$(hostname -I | awk '{print $1}')
echo "Your Linode IP: $LINODE_IP"
echo ""

# Step 2: Check DNS
echo "Checking DNS for $DOMAIN..."
DOMAIN_IP=$(dig +short $DOMAIN | tail -1 || echo "not found")
echo "Domain $DOMAIN currently points to: $DOMAIN_IP"
echo ""

if [ "$DOMAIN_IP" != "$LINODE_IP" ] && [ "$DOMAIN_IP" != "not found" ]; then
    echo "⚠ Domain is pointing to $DOMAIN_IP, not your Linode IP $LINODE_IP"
    echo "Please update DNS to point to: $LINODE_IP"
    echo ""
fi

# Step 3: Update Nginx configuration
echo "Updating Nginx configuration for $DOMAIN..."
cat > /etc/nginx/sites-available/thebible << EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;

    client_max_body_size 10M;

    # Allow Let's Encrypt challenges
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }

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

# Ensure challenge directory exists
mkdir -p /var/www/html/.well-known/acme-challenge
chown -R www-data:www-data /var/www/html

# Test and reload Nginx
nginx -t
systemctl reload nginx
echo "✓ Nginx configured"

# Step 4: Ensure firewall allows HTTP/HTTPS
echo "Checking firewall..."
if ufw status | grep -q "Status: active"; then
    ufw allow 80/tcp
    ufw allow 443/tcp
    echo "✓ Firewall configured"
fi

# Step 5: Verify service is running
if systemctl is-active --quiet thebible; then
    echo "✓ TheBible service is running"
else
    echo "⚠ TheBible service is not running. Starting it..."
    systemctl start thebible
fi

# Step 6: Test local access
echo "Testing local access..."
if curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:$APP_PORT/health | grep -q "200"; then
    echo "✓ Application is responding"
else
    echo "⚠ Application may not be responding correctly"
fi

echo ""
echo "=== Ready for SSL Certificate ==="
echo ""
echo "Your Linode IP: $LINODE_IP"
echo "Domain: $DOMAIN"
echo ""
echo "Make sure DNS is configured:"
echo "  - $DOMAIN A record → $LINODE_IP"
echo "  - www.$DOMAIN A record → $LINODE_IP"
echo ""
echo "Verify DNS:"
echo "  dig +short $DOMAIN"
echo ""
echo "When DNS is correct, run:"
echo "  certbot --nginx -d $DOMAIN -d www.$DOMAIN"
echo ""

