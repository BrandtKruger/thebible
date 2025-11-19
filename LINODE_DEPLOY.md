# Linode Ubuntu Deployment Guide

Complete step-by-step guide for deploying The Bible web server to Ubuntu Linode.

## Prerequisites

- Ubuntu Linode VPS (Ubuntu 22.04 LTS recommended)
- Root or sudo access
- Domain name (krugerbdg.com) pointing to your Linode IP
- SSH access configured

## Quick Deployment (Automated Script)

1. **Upload the deployment script to your Linode:**
   ```bash
   scp linode-deploy.sh root@your-linode-ip:/root/
   ```

2. **SSH into your Linode:**
   ```bash
   ssh root@your-linode-ip
   ```

3. **Make script executable and run:**
   ```bash
   chmod +x linode-deploy.sh
   ./linode-deploy.sh
   ```

The script will:
- Install Rust and dependencies
- Set up the application directory
- Build the release binary
- Configure systemd service
- Set up Nginx reverse proxy
- Configure SSL with Let's Encrypt
- Start the service

## Manual Step-by-Step Deployment

### Step 1: Connect to Your Linode

```bash
ssh root@your-linode-ip
# Or if you've set up a non-root user:
ssh your-username@your-linode-ip
```

### Step 2: Update System

```bash
sudo apt update && sudo apt upgrade -y
```

### Step 3: Install Required Packages

```bash
# Install build tools and dependencies
sudo apt install -y \
    curl \
    build-essential \
    pkg-config \
    libssl-dev \
    nginx \
    certbot \
    python3-certbot-nginx \
    git \
    ufw

# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env
rustup default stable
```

### Step 4: Create Application User (Recommended)

```bash
# Create a dedicated user for the application
sudo useradd -r -s /bin/false -d /opt/thebible thebible
sudo mkdir -p /opt/thebible
sudo chown thebible:thebible /opt/thebible
```

### Step 5: Deploy Application Files

**Option A: Using Git (Recommended)**

```bash
cd /opt/thebible
sudo -u thebible git clone <your-repo-url> .
# Or if you want to use your current repo:
sudo -u thebible git init
sudo -u thebible git remote add origin <your-repo-url>
sudo -u thebible git pull origin main
```

**Option B: Using SCP (from your local machine)**

```bash
# From your local machine
cd /path/to/TheBible
scp -r src static Cargo.toml Cargo.lock root@your-linode-ip:/tmp/thebible/
# Then on the server:
sudo mv /tmp/thebible/* /opt/thebible/
sudo chown -R thebible:thebible /opt/thebible
```

**Option C: Manual Upload**

Upload files via SFTP or use `rsync`:
```bash
rsync -avz --exclude 'target' --exclude '.git' \
    /path/to/TheBible/ root@your-linode-ip:/opt/thebible/
```

### Step 6: Configure Environment Variables

```bash
cd /opt/thebible
sudo nano .env
```

Add the following (adjust port if needed):
```bash
HOST=127.0.0.1
PORT=3000
BIBLE_API_BASE_URL=https://bible.helloao.org/api
RUST_LOG=info
```

Set proper permissions:
```bash
sudo chown thebible:thebible .env
sudo chmod 600 .env
```

### Step 7: Build the Application

```bash
cd /opt/thebible
sudo -u thebible source $HOME/.cargo/env && cargo build --release
```

**Note:** If building as root, you may need to:
```bash
export CARGO_HOME=/opt/thebible/.cargo
export RUSTUP_HOME=/opt/thebible/.rustup
cargo build --release
```

### Step 8: Verify Binary

```bash
ls -lh /opt/thebible/target/release/server
# Should show the binary file
/opt/thebible/target/release/server --help
```

### Step 9: Set Up Systemd Service

```bash
sudo nano /etc/systemd/system/thebible.service
```

Paste the following (adjust paths if needed):

```ini
[Unit]
Description=The Bible Web Server
After=network.target

[Service]
Type=simple
User=thebible
Group=thebible
WorkingDirectory=/opt/thebible
EnvironmentFile=/opt/thebible/.env
ExecStart=/opt/thebible/target/release/server
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=thebible

# Security hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/thebible

# Resource limits
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
```

Enable and start the service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable thebible
sudo systemctl start thebible
sudo systemctl status thebible
```

### Step 10: Configure Nginx Reverse Proxy

```bash
sudo nano /etc/nginx/sites-available/thebible
```

Add the following configuration:

```nginx
server {
    listen 80;
    server_name krugerbdg.com www.krugerbdg.com;

    # Redirect HTTP to HTTPS (after SSL setup)
    # Uncomment after Step 11:
    # return 301 https://$server_name$request_uri;

    # For initial setup, use this:
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

Enable the site:

```bash
sudo ln -s /etc/nginx/sites-available/thebible /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### Step 11: Configure Firewall

```bash
# Allow SSH (important!)
sudo ufw allow 22/tcp

# Allow HTTP and HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Enable firewall
sudo ufw enable
sudo ufw status
```

### Step 12: Set Up SSL Certificate (Let's Encrypt)

```bash
# Get SSL certificate
sudo certbot --nginx -d krugerbdg.com -d www.krugerbdg.com

# Follow the prompts:
# - Enter your email
# - Agree to terms
# - Choose whether to redirect HTTP to HTTPS (recommended: Yes)
```

After SSL setup, update the Nginx config to redirect HTTP to HTTPS (if not done automatically).

### Step 13: Verify Deployment

1. **Check service status:**
   ```bash
   sudo systemctl status thebible
   ```

2. **Check logs:**
   ```bash
   sudo journalctl -u thebible -f
   ```

3. **Test locally:**
   ```bash
   curl http://127.0.0.1:3000/health
   ```

4. **Test via domain:**
   ```bash
   curl https://krugerbdg.com/health
   ```

5. **Visit in browser:**
   Open `https://krugerbdg.com` in your browser

## Updating the Application

When you need to update the application:

```bash
cd /opt/thebible

# Pull latest changes (if using git)
sudo -u thebible git pull

# Rebuild
sudo -u thebible source $HOME/.cargo/env && cargo build --release

# Restart service
sudo systemctl restart thebible

# Check status
sudo systemctl status thebible
```

## Troubleshooting

### Service Won't Start

```bash
# Check service status
sudo systemctl status thebible

# Check logs
sudo journalctl -u thebible -n 50

# Check if port is in use
sudo netstat -tlnp | grep 3000
```

### Nginx Issues

```bash
# Test Nginx configuration
sudo nginx -t

# Check Nginx logs
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log
```

### Permission Issues

```bash
# Ensure correct ownership
sudo chown -R thebible:thebible /opt/thebible
sudo chmod 600 /opt/thebible/.env
```

### SSL Certificate Renewal

Let's Encrypt certificates expire every 90 days. Set up auto-renewal:

```bash
# Test renewal
sudo certbot renew --dry-run

# Certbot should auto-renew, but verify:
sudo systemctl status certbot.timer
```

## Security Best Practices

1. **Keep system updated:**
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

2. **Use firewall:**
   ```bash
   sudo ufw status
   ```

3. **Disable root SSH (after setup):**
   ```bash
   sudo nano /etc/ssh/sshd_config
   # Set: PermitRootLogin no
   sudo systemctl restart sshd
   ```

4. **Set up fail2ban:**
   ```bash
   sudo apt install fail2ban
   sudo systemctl enable fail2ban
   ```

5. **Regular backups:**
   - Backup `/opt/thebible` directory
   - Backup Nginx configuration
   - Backup SSL certificates

## File Structure

```
/opt/thebible/
├── .env                    # Environment variables
├── Cargo.toml             # Rust dependencies
├── Cargo.lock             # Locked dependencies
├── src/                   # Source code
├── static/                # Static files (HTML, images)
│   ├── index.html
│   └── Bible.jpg
└── target/
    └── release/
        └── server         # Compiled binary
```

## Useful Commands

```bash
# View service logs
sudo journalctl -u thebible -f

# Restart service
sudo systemctl restart thebible

# Stop service
sudo systemctl stop thebible

# Start service
sudo systemctl start thebible

# Reload Nginx
sudo systemctl reload nginx

# Check disk space
df -h

# Check memory usage
free -h

# Monitor system resources
htop
```

## Next Steps

- Set up monitoring (e.g., Prometheus, Grafana)
- Configure log rotation
- Set up automated backups
- Configure CDN (Cloudflare) for static assets
- Set up monitoring alerts

## Support

If you encounter issues:
1. Check service logs: `sudo journalctl -u thebible -n 100`
2. Check Nginx logs: `sudo tail -f /var/log/nginx/error.log`
3. Verify DNS: `dig krugerbdg.com`
4. Test connectivity: `curl -I https://krugerbdg.com`

