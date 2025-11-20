#!/bin/bash

# SSL Setup for krugerbdg.com
# Run this on your Linode server: sudo ./setup-krugerbdg-ssl.sh

set -e

DOMAIN="krugerbdg.com"
APP_PORT="3000"
LINODE_IP="139.162.145.166"

echo "=== SSL Setup for krugerbdg.com ==="
echo "Expected Linode IP: $LINODE_IP"
echo ""

# Step 1: Get actual Linode IP
ACTUAL_IP=$(hostname -I | awk '{print $1}')
echo "Your Linode IP: $ACTUAL_IP"
echo ""

# Step 2: Check DNS
echo "=== Checking DNS Configuration ==="
echo ""

DOMAIN_IP=$(dig +short $DOMAIN A 2>/dev/null | tail -1 || echo "")
WWW_IP=$(dig +short www.$DOMAIN A 2>/dev/null | tail -1 || echo "")

if [ -z "$DOMAIN_IP" ]; then
    echo "❌ Error: $DOMAIN is not resolving"
    echo ""
    echo "Please configure DNS first:"
    echo "1. Go to your domain registrar (where you bought krugerbdg.com)"
    echo "2. Add A record for main domain:"
    echo "   - Name: @ (or krugerbdg.com or leave blank)"
    echo "   - Type: A"
    echo "   - Value: $ACTUAL_IP"
    echo "   - TTL: 3600"
    echo ""
    echo "3. Add A record for www subdomain:"
    echo "   - Name: www"
    echo "   - Type: A"
    echo "   - Value: $ACTUAL_IP"
    echo "   - TTL: 3600"
    echo ""
    echo "4. Wait 5-60 minutes for DNS propagation"
    echo "5. Verify with: dig +short $DOMAIN"
    echo ""
    read -p "Have you configured DNS? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Please configure DNS first, then run this script again."
        exit 1
    fi
    
    echo ""
    echo "Waiting 10 seconds, then checking again..."
    sleep 10
    DOMAIN_IP=$(dig +short $DOMAIN A 2>/dev/null | tail -1 || echo "")
    WWW_IP=$(dig +short www.$DOMAIN A 2>/dev/null | tail -1 || echo "")
fi

if [ -z "$DOMAIN_IP" ]; then
    echo "❌ DNS still not resolving. Please wait longer for propagation."
    echo "   Check with: dig +short $DOMAIN"
    exit 1
fi

echo "✓ $DOMAIN resolves to: $DOMAIN_IP"
if [ -n "$WWW_IP" ]; then
    echo "✓ www.$DOMAIN resolves to: $WWW_IP"
    if [ "$WWW_IP" != "$DOMAIN_IP" ]; then
        echo "⚠ Warning: www subdomain points to different IP"
    fi
else
    echo "⚠ www.$DOMAIN not resolving (recommended to add)"
    echo "   You can still proceed, but users won't be able to access www.$DOMAIN"
fi

if [ "$DOMAIN_IP" != "$ACTUAL_IP" ] && [ "$DOMAIN_IP" != "$LINODE_IP" ]; then
    echo ""
    echo "⚠ Warning: Domain points to $DOMAIN_IP"
    echo "   Expected: $ACTUAL_IP or $LINODE_IP"
    echo ""
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Step 3: Update Nginx configuration
echo ""
echo "=== Updating Nginx Configuration ==="
echo ""

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
echo "Testing Nginx configuration..."
nginx -t
echo "Reloading Nginx..."
systemctl reload nginx

echo "✓ Nginx configured for $DOMAIN and www.$DOMAIN"
echo ""

# Step 4: Get SSL certificate
echo "=== Getting SSL Certificate ==="
echo ""
echo "This will get SSL certificates for:"
echo "  - $DOMAIN"
if [ -n "$WWW_IP" ]; then
    echo "  - www.$DOMAIN"
fi
echo ""
echo "You will be prompted for:"
echo "  - Email address (for renewal notices)"
echo "  - Agreement to terms of service"
echo "  - Whether to redirect HTTP to HTTPS (recommended: Yes)"
echo ""

# Check if certbot is installed
if ! command -v certbot &> /dev/null; then
    echo "Installing Certbot..."
    apt update
    apt install -y certbot python3-certbot-nginx
fi

# Get certificate - include www if it resolves
if [ -n "$WWW_IP" ]; then
    echo "Getting certificate for both $DOMAIN and www.$DOMAIN..."
    certbot --nginx -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos --redirect --email admin@$DOMAIN 2>/dev/null || \
    certbot --nginx -d $DOMAIN -d www.$DOMAIN
else
    echo "Getting certificate for $DOMAIN only (www not configured)..."
    certbot --nginx -d $DOMAIN --non-interactive --agree-tos --redirect --email admin@$DOMAIN 2>/dev/null || \
    certbot --nginx -d $DOMAIN
fi

# Step 5: Verify SSL
echo ""
echo "=== SSL Setup Complete! ==="
echo ""
echo "✓ Your site is now available at:"
echo "  https://$DOMAIN"
if [ -n "$WWW_IP" ]; then
    echo "  https://www.$DOMAIN"
    echo ""
    echo "✓ Both URLs will work and redirect HTTP to HTTPS"
else
    echo ""
    echo "⚠ Note: www.$DOMAIN is not configured"
    echo "   Consider adding www A record for better user experience"
fi
echo ""
echo "To check certificate status:"
echo "  sudo certbot certificates"
echo ""
echo "Certificate will auto-renew. To test renewal:"
echo "  sudo certbot renew --dry-run"
echo ""
echo "=== Testing ==="
echo "Test your site:"
echo "  curl -I https://$DOMAIN"
if [ -n "$WWW_IP" ]; then
    echo "  curl -I https://www.$DOMAIN"
fi
echo ""

