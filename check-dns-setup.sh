#!/bin/bash

# DNS Setup Checker for TheBibl.com
# Run this on your Linode server: sudo ./check-dns-setup.sh

set -e

DOMAIN="TheBibl.com"
DOMAIN_LOWER="thebibl.com"

echo "=== DNS Setup Check for $DOMAIN ==="
echo ""

# Get Linode IP
LINODE_IP=$(hostname -I | awk '{print $1}')
echo "Your Linode IP Address: $LINODE_IP"
echo ""

# Check DNS records
echo "Checking DNS records..."
echo ""

echo "Checking $DOMAIN_LOWER:"
DOMAIN_IP=$(dig +short $DOMAIN_LOWER A 2>/dev/null | tail -1 || echo "")
if [ -z "$DOMAIN_IP" ]; then
    echo "  ❌ No A record found (NXDOMAIN)"
    echo "  → DNS record does not exist or hasn't propagated yet"
else
    echo "  ✓ A record found: $DOMAIN_IP"
    if [ "$DOMAIN_IP" = "$LINODE_IP" ]; then
        echo "  ✓ Points to your Linode IP (correct!)"
    else
        echo "  ⚠ Points to $DOMAIN_IP (should be $LINODE_IP)"
    fi
fi

echo ""
echo "Checking www.$DOMAIN_LOWER:"
WWW_IP=$(dig +short www.$DOMAIN_LOWER A 2>/dev/null | tail -1 || echo "")
if [ -z "$WWW_IP" ]; then
    echo "  ❌ No A record found (NXDOMAIN)"
    echo "  → DNS record does not exist or hasn't propagated yet"
else
    echo "  ✓ A record found: $WWW_IP"
    if [ "$WWW_IP" = "$LINODE_IP" ]; then
        echo "  ✓ Points to your Linode IP (correct!)"
    else
        echo "  ⚠ Points to $WWW_IP (should be $LINODE_IP)"
    fi
fi

echo ""
echo "=== DNS Configuration Required ==="
echo ""
echo "You need to set up DNS records at your domain registrar."
echo ""
echo "Required DNS Records:"
echo "  Type: A"
echo "  Name: @ (or $DOMAIN_LOWER)"
echo "  Value: $LINODE_IP"
echo "  TTL: 3600 (or default)"
echo ""
echo "  Type: A"
echo "  Name: www"
echo "  Value: $LINODE_IP"
echo "  TTL: 3600 (or default)"
echo ""
echo "=== Steps to Fix ==="
echo ""
echo "1. Go to your domain registrar (where you registered $DOMAIN)"
echo "2. Find DNS Management / DNS Settings"
echo "3. Add or update these A records:"
echo "   - @ or $DOMAIN_LOWER → $LINODE_IP"
echo "   - www → $LINODE_IP"
echo "4. Save changes"
echo "5. Wait 5-60 minutes for DNS propagation"
echo "6. Run this script again to verify"
echo ""
echo "=== Verify DNS ==="
echo ""
echo "After updating DNS, verify with:"
echo "  dig +short $DOMAIN_LOWER"
echo "  dig +short www.$DOMAIN_LOWER"
echo ""
echo "Both should return: $LINODE_IP"
echo ""
echo "Once DNS is correct, you can get SSL certificate:"
echo "  certbot --nginx -d $DOMAIN_LOWER -d www.$DOMAIN_LOWER"
echo ""

