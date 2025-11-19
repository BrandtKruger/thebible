#!/bin/bash

# Check DNS Zone File and Extract Required Information
# Run this on your Linode server: sudo ./check-zone-file.sh [zone-file-path]

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 [path-to-zone-file]"
    echo ""
    echo "Looking for zone files in /root..."
    ZONE_FILES=$(find /root -type f \( -name "*.zone" -o -name "*zone*" -o -name "*.txt" \) 2>/dev/null | head -5)
    
    if [ -z "$ZONE_FILES" ]; then
        echo "No zone files found. Please specify the path:"
        echo "  $0 /root/your-zone-file.txt"
        exit 1
    fi
    
    echo "Found zone files:"
    echo "$ZONE_FILES"
    echo ""
    echo "Please run: $0 /path/to/zone-file"
    exit 1
fi

ZONE_FILE="$1"

if [ ! -f "$ZONE_FILE" ]; then
    echo "Error: File not found: $ZONE_FILE"
    exit 1
fi

echo "=== Analyzing Zone File: $ZONE_FILE ==="
echo ""

# Get Linode IP
LINODE_IP=$(hostname -I | awk '{print $1}')
echo "Your Linode IP: $LINODE_IP"
echo ""

# Display zone file
echo "=== Zone File Contents ==="
cat "$ZONE_FILE"
echo ""

# Extract A records
echo "=== A Records Found ==="
grep -E "^\s*[^;].*\s+IN\s+A\s+" "$ZONE_FILE" 2>/dev/null || echo "No A records found in standard format"
echo ""

# Check if Linode IP is in zone file
if grep -q "$LINODE_IP" "$ZONE_FILE"; then
    echo "✓ Zone file contains your Linode IP: $LINODE_IP"
else
    echo "⚠ Zone file does NOT contain your Linode IP: $LINODE_IP"
    echo "  You may need to update A records in the zone file"
fi

echo ""
echo "=== Required DNS Records ==="
echo ""
echo "Make sure your zone file has these A records:"
echo "  thebibl.com.    IN  A  $LINODE_IP"
echo "  www.thebibl.com. IN  A  $LINODE_IP"
echo ""
echo "=== How to Use This Zone File ==="
echo ""
echo "Option 1: Linode DNS Manager (Easiest)"
echo "  1. Go to: https://cloud.linode.com/dns/zones"
echo "  2. Click 'Create a Domain Zone'"
echo "  3. Domain: thebibl.com"
echo "  4. Click 'Create Zone'"
echo "  5. Click 'Import a Zone File'"
echo "  6. Upload: $ZONE_FILE"
echo "  7. Update nameservers at your domain registrar"
echo ""
echo "Option 2: Manual Configuration"
echo "  Extract A records from zone file and add them at your registrar"
echo ""

