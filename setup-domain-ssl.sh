#!/bin/bash

# Setup SSL for domain name
# Run this on your Linode server: sudo ./setup-domain-ssl.sh

set -e

# Prompt for domain name
if [ -z "$1" ]; then
    echo "Usage: $0 <domain-name>"
    echo "Example: $0 thebibl.com"
    exit 1
fi

DOMAIN="$1"
APP_PORT="3000"
LINODE_IP=$(hostname -I | awk '{print $1}')

echo "=== SSL Setup for $DOMAIN ==="
echo "Your Linode IP: $LINODE_IP"
echo ""

# Step 1: Check DNS
echo "Checking DNS for $DOMAIN..."
DOMAIN_IP=$(dig +short $DOMAIN A 2>/dev/null | tail -1 || echo "")
WWW_IP=$(dig +short www.$DOMAIN A 2>/dev/null | tail -1 || echo "")

if [ -z "$DOMAIN_IP" ]; then
    echo "❌ Error: $DOMAIN is not resolving"
    echo ""
    echo "Please configure DNS first:"
    echo "1. Go to your domain registrar"
    echo "2. Add A record: $DOMAIN → $LINODE_IP"
    echo "3. Add A record: www.$DOMAIN → $LINODE_IP"
    echo "4. Wait 5-60 minutes for DNS propagation"
    echo "5. Verify with: dig +short $DOMAIN"
    exit 1
fi

echo "✓ $DOMAIN resolves to: $DOMAIN_IP"
if [ -n "$WWW_IP" ]; then
    echo "✓ www.$DOMAIN resolves to: $WWW_IP"
fi

if [ "$DOMAIN_IP" != "$LINODE_IP" ]; then
    echo "⚠ Warning: Domain points to $DOMAIN_IP, not your Linode IP $LINODE_IP"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Step 2: Update Nginx configuration
echo ""
echo "Updating Nginx configuration..."
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

echo ""
echo "✓ Nginx configured for $DOMAIN"
echo ""

# Step 3: Get SSL certificate
echo "Getting SSL certificate from Let's Encrypt..."
echo "This will prompt you for:"
echo "  - Email address (for renewal notices)"
echo "  - Agreement to terms"
echo "  - Whether to redirect HTTP to HTTPS (recommended: Yes)"
echo ""

certbot --nginx -d $DOMAIN -d www.$DOMAIN

# Step 4: Verify SSL
echo ""
echo "=== SSL Setup Complete! ==="
echo ""
echo "Your site is now available at:"
echo "  https://$DOMAIN"
echo "  https://www.$DOMAIN"
echo ""
echo "HTTP will automatically redirect to HTTPS"
echo ""
echo "To check certificate status:"
echo "  sudo certbot certificates"
echo ""
echo "Certificate will auto-renew. To test renewal:"
echo "  sudo certbot renew --dry-run"
echo ""

