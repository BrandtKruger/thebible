#!/bin/bash

# Verify DNS and Set Up SSL
# Run this on your Linode server: sudo ./verify-dns-and-ssl.sh

set -e

DOMAIN="thebibl.com"
EXPECTED_IP="139.162.145.166"

echo "=== DNS Verification and SSL Setup ==="
echo ""

# Step 1: Get current Linode IP
LINODE_IP=$(hostname -I | awk '{print $1}')
echo "Your Linode IP: $LINODE_IP"
echo "Expected DNS IP: $EXPECTED_IP"
echo ""

if [ "$LINODE_IP" != "$EXPECTED_IP" ]; then
    echo "⚠ WARNING: Linode IP ($LINODE_IP) doesn't match DNS IP ($EXPECTED_IP)"
    echo "You may need to update DNS records to point to: $LINODE_IP"
    echo ""
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    echo "✓ IP addresses match!"
fi

echo ""
echo "=== Checking DNS Propagation ==="
echo ""

# Check DNS records
echo "Checking $DOMAIN:"
DOMAIN_IP=$(dig +short $DOMAIN A 2>/dev/null | tail -1 || echo "")
if [ -z "$DOMAIN_IP" ]; then
    echo "  ❌ DNS not resolving yet (may need to wait for propagation)"
    echo "  → Wait 5-60 minutes and try again"
    exit 1
else
    echo "  ✓ Resolves to: $DOMAIN_IP"
    if [ "$DOMAIN_IP" = "$EXPECTED_IP" ] || [ "$DOMAIN_IP" = "$LINODE_IP" ]; then
        echo "  ✓ Correct IP address!"
    else
        echo "  ⚠ Points to different IP: $DOMAIN_IP"
    fi
fi

echo ""
echo "Checking www.$DOMAIN:"
WWW_IP=$(dig +short www.$DOMAIN A 2>/dev/null | tail -1 || echo "")
if [ -z "$WWW_IP" ]; then
    echo "  ❌ DNS not resolving yet"
else
    echo "  ✓ Resolves to: $WWW_IP"
    if [ "$WWW_IP" = "$EXPECTED_IP" ] || [ "$WWW_IP" = "$LINODE_IP" ]; then
        echo "  ✓ Correct IP address!"
    else
        echo "  ⚠ Points to different IP: $WWW_IP"
    fi
fi

echo ""
echo "=== Updating Nginx Configuration ==="
echo ""

# Update Nginx config
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
        proxy_pass http://127.0.0.1:3000;
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

# Create challenge directory
mkdir -p /var/www/html/.well-known/acme-challenge
chown -R www-data:www-data /var/www/html

# Test and reload Nginx
nginx -t
systemctl reload nginx
echo "✓ Nginx configured"

# Ensure firewall allows HTTP/HTTPS
if ufw status | grep -q "Status: active"; then
    ufw allow 80/tcp
    ufw allow 443/tcp
    echo "✓ Firewall configured"
fi

# Ensure service is running
if systemctl is-active --quiet thebible; then
    echo "✓ TheBible service is running"
else
    echo "Starting TheBible service..."
    systemctl start thebible
fi

echo ""
echo "=== Testing HTTP Access ==="
echo ""

# Test local access
if curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:3000/health | grep -q "200"; then
    echo "✓ Application responding locally"
else
    echo "⚠ Application may not be responding"
fi

# Test via domain (if DNS is working)
if [ -n "$DOMAIN_IP" ]; then
    echo "Testing via domain..."
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://$DOMAIN/health 2>/dev/null || echo "000")
    if [ "$HTTP_CODE" = "200" ]; then
        echo "✓ Domain is accessible via HTTP"
    else
        echo "⚠ Domain HTTP test returned: $HTTP_CODE"
        echo "  (This is OK if DNS just propagated)"
    fi
fi

echo ""
echo "=== Ready for SSL Certificate ==="
echo ""
echo "If DNS is resolving correctly, you can now get SSL certificate:"
echo ""
echo "  certbot --nginx -d $DOMAIN -d www.$DOMAIN"
echo ""
echo "Or run it now? (y/n)"
read -p "> " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Running Certbot..."
    certbot --nginx -d $DOMAIN -d www.$DOMAIN
    echo ""
    echo "✓ SSL certificate installed!"
    echo ""
    echo "Your site should now be available at:"
    echo "  https://$DOMAIN"
    echo "  https://www.$DOMAIN"
else
    echo ""
    echo "Run this when ready:"
    echo "  certbot --nginx -d $DOMAIN -d www.$DOMAIN"
fi

