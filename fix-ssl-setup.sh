#!/bin/bash

# Fix SSL setup - DNS and Certbot configuration
# Run this on your Linode server: sudo ./fix-ssl-setup.sh

set -e

DOMAIN="TheBibl.com"
APP_PORT="3000"

echo "=== SSL Setup Troubleshooting ==="

# Step 1: Get current Linode IP
LINODE_IP=$(hostname -I | awk '{print $1}')
echo "Your Linode IP: $LINODE_IP"
echo ""

# Step 2: Check what IP the domain points to
echo "Checking DNS for $DOMAIN..."
DOMAIN_IP=$(dig +short $DOMAIN | tail -1)
echo "Domain $DOMAIN currently points to: $DOMAIN_IP"
echo ""

if [ "$DOMAIN_IP" != "$LINODE_IP" ]; then
    echo "⚠ WARNING: Domain is pointing to $DOMAIN_IP, not your Linode IP $LINODE_IP"
    echo ""
    echo "You need to update your DNS records:"
    echo "1. Go to your domain registrar (where you bought krugerbdg.com)"
    echo "2. Update the A record for krugerbdg.com to point to: $LINODE_IP"
    echo "3. Update the A record for www.krugerbdg.com to point to: $LINODE_IP"
    echo "4. Wait 5-15 minutes for DNS to propagate"
    echo "5. Verify with: dig +short krugerbdg.com"
    echo ""
    read -p "Have you updated DNS? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Please update DNS first, then run this script again."
        exit 1
    fi
fi

# Step 3: Verify Nginx is running and accessible
echo "Checking Nginx..."
if ! systemctl is-active --quiet nginx; then
    echo "Starting Nginx..."
    systemctl start nginx
fi

# Step 4: Update Nginx config with proper server_name
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

nginx -t
systemctl reload nginx

# Step 5: Check firewall
echo "Checking firewall..."
if ufw status | grep -q "Status: active"; then
    echo "Firewall is active, ensuring ports are open..."
    ufw allow 80/tcp
    ufw allow 443/tcp
fi

# Step 6: Test HTTP access
echo "Testing HTTP access..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost/health | grep -q "200"; then
    echo "✓ Local HTTP access working"
else
    echo "⚠ Local HTTP access may have issues"
fi

# Step 7: Try Certbot again
echo ""
echo "=== Ready for SSL Setup ==="
echo ""
echo "Your Linode IP: $LINODE_IP"
echo "Domain should point to: $LINODE_IP"
echo ""
echo "Verify DNS is correct:"
echo "  dig +short krugerbdg.com"
echo ""
echo "Then run Certbot:"
echo "  certbot --nginx -d $DOMAIN -d www.$DOMAIN"
echo ""
echo "Or use standalone mode (stops Nginx temporarily):"
echo "  certbot certonly --standalone -d $DOMAIN -d www.$DOMAIN"

