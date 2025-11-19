# Quick Deployment Guide

## Prerequisites

- VPS/server with Ubuntu/Debian
- Domain name (krugerbdg.com) pointing to your server
- SSH access to server

## Quick Steps

### 1. On Your Local Machine

```bash
# Build the release binary
cargo build --release

# Upload to server (replace with your server details)
scp -r target/release/server static/ .env user@your-server:/opt/thebible/
```

### 2. On Your Server

```bash
# Install dependencies
sudo apt update
sudo apt install -y nginx certbot python3-certbot-nginx

# Create application directory
sudo mkdir -p /opt/thebible
sudo chown $USER:$USER /opt/thebible

# Move files (if uploaded)
# Files should already be in /opt/thebible from SCP

# Install systemd service
sudo cp systemd/thebible.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable thebible
sudo systemctl start thebible

# Configure Nginx
sudo cp nginx.conf.example /etc/nginx/sites-available/krugerbdg.com
sudo ln -s /etc/nginx/sites-available/krugerbdg.com /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx

# Set up SSL
sudo certbot --nginx -d krugerbdg.com -d www.krugerbdg.com

# Configure firewall
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

### 3. Verify

```bash
# Check service
sudo systemctl status thebible

# Check logs
sudo journalctl -u thebible -f

# Test
curl https://krugerbdg.com/health
```

## Updating

```bash
# On local machine
cargo build --release
scp target/release/server user@your-server:/opt/thebible/target/release/

# On server
sudo systemctl restart thebible
```

## Troubleshooting

- **Service won't start**: Check logs with `sudo journalctl -u thebible -n 50`
- **502 Bad Gateway**: Verify Rust server is running on port 3000
- **SSL issues**: Run `sudo certbot renew`

For detailed instructions, see [DEPLOYMENT.md](DEPLOYMENT.md).

