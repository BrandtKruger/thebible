#!/bin/bash

# DNS Zone File Setup Helper
# Run this on your Linode server: sudo ./setup-dns-zone.sh

set -e

echo "=== DNS Zone File Setup ==="
echo ""

# Find zone files in root directory
echo "Looking for DNS zone files..."
ZONE_FILES=$(find /root -name "*.zone" -o -name "*zone*" -o -name "*.txt" 2>/dev/null | grep -i zone || echo "")

if [ -z "$ZONE_FILES" ]; then
    echo "No zone files found in /root"
    echo ""
    echo "Please check:"
    echo "  ls -la /root | grep -i zone"
    echo ""
    exit 1
fi

echo "Found zone files:"
echo "$ZONE_FILES"
echo ""

# Get Linode IP
LINODE_IP=$(hostname -I | awk '{print $1}')
echo "Your Linode IP: $LINODE_IP"
echo ""

echo "=== DNS Configuration Options ==="
echo ""
echo "You have several options to configure DNS:"
echo ""
echo "Option 1: Use Linode DNS Manager (Recommended)"
echo "  1. Go to https://cloud.linode.com/dns/zones"
echo "  2. Click 'Create a Domain Zone'"
echo "  3. Domain: thebibl.com"
echo "  4. Click 'Create Zone'"
echo "  5. Click 'Import a Zone File'"
echo "  6. Upload your zone file"
echo "  7. Update NS records at your domain registrar to Linode's nameservers"
echo ""
echo "Option 2: Configure at Domain Registrar"
echo "  1. Go to your domain registrar (where you registered TheBibl.com)"
echo "  2. Find DNS Management"
echo "  3. Import or manually add records from zone file"
echo ""
echo "Option 3: View Zone File Contents"
echo "  Let's check what's in your zone file..."
echo ""

# Ask user which zone file to check
if [ $(echo "$ZONE_FILES" | wc -l) -eq 1 ]; then
    ZONE_FILE=$(echo "$ZONE_FILES" | head -1)
    echo "Checking: $ZONE_FILE"
    echo ""
    echo "=== Zone File Contents ==="
    cat "$ZONE_FILE"
    echo ""
    echo "=== Required Records ==="
    echo ""
    echo "Make sure these A records exist:"
    echo "  thebibl.com.    IN  A  $LINODE_IP"
    echo "  www.thebibl.com. IN  A  $LINODE_IP"
    echo ""
else
    echo "Multiple zone files found. Please specify which one to check:"
    echo "$ZONE_FILES"
fi

echo ""
echo "=== Next Steps ==="
echo ""
echo "1. Import zone file to Linode DNS Manager OR configure at registrar"
echo "2. Update nameservers at domain registrar (if using Linode DNS)"
echo "3. Wait 5-60 minutes for DNS propagation"
echo "4. Verify DNS: dig +short thebibl.com"
echo "5. Get SSL certificate: certbot --nginx -d thebibl.com -d www.thebibl.com"
echo ""

