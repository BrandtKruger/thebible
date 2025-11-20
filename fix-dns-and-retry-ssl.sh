#!/bin/bash

# Fix DNS and Retry SSL Setup for krugerbdg.com
# Run this on your Linode server: sudo ./fix-dns-and-retry-ssl.sh

set -e

DOMAIN="krugerbdg.com"
APP_PORT="3000"
LINODE_IP="139.162.145.166"

echo "=== DNS Fix and SSL Retry for krugerbdg.com ==="
echo ""

# Step 1: Check current DNS
echo "=== Current DNS Status ==="
echo ""

DOMAIN_IP=$(dig +short $DOMAIN A 2>/dev/null | tail -1 || echo "")
WWW_IP=$(dig +short www.$DOMAIN A 2>/dev/null | tail -1 || echo "")

echo "krugerbdg.com currently points to: ${DOMAIN_IP:-'not resolving'}"
echo "www.krugerbdg.com currently points to: ${WWW_IP:-'not resolving'}"
echo ""

if [ "$DOMAIN_IP" != "$LINODE_IP" ]; then
    echo "❌ PROBLEM: krugerbdg.com is pointing to $DOMAIN_IP (old hosting provider)"
    echo "   It needs to point to: $LINODE_IP (your Linode server)"
    echo ""
    echo "=== ACTION REQUIRED ==="
    echo ""
    echo "1. Go to your domain registrar (where you bought krugerbdg.com)"
    echo "   Common registrars: Namecheap, GoDaddy, Google Domains, Cloudflare, etc."
    echo ""
    echo "2. Find DNS Management / DNS Settings"
    echo ""
    echo "3. Update the A record for krugerbdg.com:"
    echo "   - Find the A record with name: @ (or blank or krugerbdg.com)"
    echo "   - Current value: $DOMAIN_IP"
    echo "   - Change to: $LINODE_IP"
    echo "   - TTL: 3600 (or Auto)"
    echo ""
    echo "4. Verify www.krugerbdg.com is also correct:"
    echo "   - Should point to: $LINODE_IP"
    echo "   - If not, update it too"
    echo ""
    echo "5. Save the changes"
    echo ""
    echo "6. Wait 5-60 minutes for DNS propagation"
    echo ""
    echo "=== After DNS Update ==="
    echo ""
    echo "Once DNS is updated, you can:"
    echo "  A) Wait and run this script again to check"
    echo "  B) Manually verify with: dig +short krugerbdg.com"
    echo "  C) Then run: sudo ./setup-krugerbdg-ssl.sh"
    echo ""
    
    # Check if old hosting provider might have DNS control
    echo "=== Important Notes ==="
    echo ""
    echo "If you used this domain at another hosting provider:"
    echo "  1. The old hosting provider might have DNS control"
    echo "  2. You may need to:"
    echo "     - Change nameservers at your registrar to point to your registrar's DNS"
    echo "     - OR update DNS records at the old hosting provider"
    echo "     - OR transfer DNS management to your registrar"
    echo ""
    echo "  3. Check where DNS is managed:"
    echo "     - Look at your domain registrar's DNS settings"
    echo "     - Check if nameservers point to old hosting provider"
    echo ""
    
    read -p "Have you updated the DNS A record? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo "Please update DNS first, then run this script again."
        exit 1
    fi
    
    echo ""
    echo "Waiting 30 seconds, then checking DNS again..."
    sleep 30
    
    # Re-check DNS
    DOMAIN_IP=$(dig +short $DOMAIN A 2>/dev/null | tail -1 || echo "")
    WWW_IP=$(dig +short www.$DOMAIN A 2>/dev/null | tail -1 || echo "")
    
    echo ""
    echo "Re-checking DNS..."
    echo "krugerbdg.com now points to: ${DOMAIN_IP:-'not resolving'}"
    echo "www.krugerbdg.com points to: ${WWW_IP:-'not resolving'}"
    echo ""
    
    if [ "$DOMAIN_IP" != "$LINODE_IP" ]; then
        echo "⚠ DNS hasn't updated yet. This can take 5-60 minutes."
        echo ""
        echo "You can:"
        echo "  1. Wait longer and check with: dig +short krugerbdg.com"
        echo "  2. Run this script again later"
        echo "  3. Once DNS shows $LINODE_IP, run: sudo ./setup-krugerbdg-ssl.sh"
        exit 1
    fi
fi

# Step 2: Verify DNS is correct
if [ "$DOMAIN_IP" = "$LINODE_IP" ]; then
    echo "✓ krugerbdg.com is pointing to correct IP: $LINODE_IP"
else
    echo "❌ krugerbdg.com still not pointing to Linode IP"
    exit 1
fi

if [ "$WWW_IP" = "$LINODE_IP" ]; then
    echo "✓ www.krugerbdg.com is pointing to correct IP: $LINODE_IP"
else
    echo "⚠ www.krugerbdg.com not pointing to Linode IP (optional but recommended)"
fi

# Step 3: Retry SSL setup
echo ""
echo "=== DNS is correct! Retrying SSL Setup ==="
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

mkdir -p /var/www/html/.well-known/acme-challenge
chown -R www-data:www-data /var/www/html

nginx -t
systemctl reload nginx

# Get SSL certificate
echo "Getting SSL certificate..."
if [ "$WWW_IP" = "$LINODE_IP" ]; then
    certbot --nginx -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos --redirect --email admin@$DOMAIN 2>/dev/null || \
    certbot --nginx -d $DOMAIN -d www.$DOMAIN
else
    certbot --nginx -d $DOMAIN --non-interactive --agree-tos --redirect --email admin@$DOMAIN 2>/dev/null || \
    certbot --nginx -d $DOMAIN
fi

echo ""
echo "=== SSL Setup Complete! ==="
echo ""
echo "✓ Your site is now available at:"
echo "  https://$DOMAIN"
if [ "$WWW_IP" = "$LINODE_IP" ]; then
    echo "  https://www.$DOMAIN"
fi
echo ""

