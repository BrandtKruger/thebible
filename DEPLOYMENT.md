# Deployment Guide

This guide covers deploying The Bible web server to your internet service (krugerbdg.com).

## Quick Start - SSH Connection

To connect to your server:
```bash
ssh krugeqkb@krugerbdg.com
```

For detailed SSH setup, see [SSH_SETUP.md](SSH_SETUP.md).

**Important**: If you're on shared hosting, see [SHARED_HOSTING_DEPLOY.md](SHARED_HOSTING_DEPLOY.md) for specific instructions.

## Deployment Options

### Option 1: VPS/Server Deployment (Recommended)

This is the most common approach for Rust applications. You'll need:
- A VPS (DigitalOcean, Linode, AWS EC2, etc.)
- Ubuntu/Debian Linux (20.04+ recommended)
- Domain name pointing to your server (krugerbdg.com)

### Option 2: Docker Deployment

Containerized deployment for easier management and scaling.

### Option 3: Cloud Platform

Deploy to platforms like Railway, Fly.io, or Render.

---

## Option 1: VPS/Server Deployment (Detailed)

### Prerequisites

1. **Server Setup**
   - Ubuntu 20.04+ or Debian 11+
   - SSH access
   - Root or sudo access

2. **Domain Configuration**
   - Point krugerbdg.com A record to your server IP
   - Point www.krugerbdg.com A record to your server IP (optional)

### Step 1: Server Preparation

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y curl build-essential nginx certbot python3-certbot-nginx

# Install Rust (if not already installed)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env
```

### Step 2: Deploy Your Application

```bash
# Create application directory
sudo mkdir -p /opt/thebible
sudo chown $USER:$USER /opt/thebible

# Clone or upload your project
cd /opt/thebible
# If using git:
# git clone <your-repo-url> .

# Or upload files via SCP:
# scp -r TheBible/* user@your-server:/opt/thebible/
```

### Step 3: Build the Application

```bash
cd /opt/thebible

# Build release binary
cargo build --release

# Verify binary exists
ls -lh target/release/server
```

### Step 4: Configure Environment Variables

```bash
# Create .env file
nano .env
```

Add your configuration:
```bash
HOST=127.0.0.1
PORT=3000
BIBLE_BRAIN_API_KEY=your_actual_api_key_here
RUST_LOG=thebible=info,tower_http=info
```

### Step 5: Create Systemd Service

Create `/etc/systemd/system/thebible.service`:

```bash
sudo nano /etc/systemd/system/thebible.service
```

Paste the following (adjust paths as needed):

```ini
[Unit]
Description=The Bible Web Server
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data
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

### Step 6: Configure Nginx Reverse Proxy

Create `/etc/nginx/sites-available/krugerbdg.com`:

```bash
sudo nano /etc/nginx/sites-available/krugerbdg.com
```

Paste the following:

```nginx
server {
    listen 80;
    listen [::]:80;
    server_name krugerbdg.com www.krugerbdg.com;

    # Logging
    access_log /var/log/nginx/krugerbdg.com.access.log;
    error_log /var/log/nginx/krugerbdg.com.error.log;

    # Increase body size limit for API requests
    client_max_body_size 10M;

    # Proxy to Rust server
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
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Health check endpoint
    location /health {
        proxy_pass http://127.0.0.1:3000/health;
        access_log off;
    }
}
```

Enable the site:

```bash
sudo ln -s /etc/nginx/sites-available/krugerbdg.com /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### Step 7: Set Up SSL with Let's Encrypt

```bash
sudo certbot --nginx -d krugerbdg.com -d www.krugerbdg.com
```

Follow the prompts. Certbot will automatically configure SSL and redirect HTTP to HTTPS.

### Step 8: Firewall Configuration

```bash
# Allow SSH, HTTP, and HTTPS
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

### Step 9: Verify Deployment

```bash
# Check service status
sudo systemctl status thebible

# Check logs
sudo journalctl -u thebible -f

# Test locally
curl http://localhost:3000/health

# Test from outside
curl https://krugerbdg.com/health
```

---

## Option 2: Docker Deployment

### Create Dockerfile

Create `Dockerfile` in project root:

```dockerfile
# Build stage
FROM rust:1.75 as builder

WORKDIR /app

# Copy dependency files
COPY Cargo.toml Cargo.lock ./

# Create dummy source to cache dependencies
RUN mkdir src && \
    echo "fn main() {}" > src/main.rs && \
    cargo build --release && \
    rm -rf src

# Copy actual source code
COPY src ./src
COPY static ./static

# Build the application
RUN touch src/bin/server.rs && \
    cargo build --release --bin server

# Runtime stage
FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy binary and static files
COPY --from=builder /app/target/release/server /app/server
COPY --from=builder /app/static ./static

# Create non-root user
RUN useradd -m -u 1000 appuser && \
    chown -R appuser:appuser /app

USER appuser

EXPOSE 3000

ENV RUST_LOG=thebible=info,tower_http=info

CMD ["./server"]
```

### Create docker-compose.yml

```yaml
version: '3.8'

services:
  thebible:
    build: .
    container_name: thebible
    restart: unless-stopped
    ports:
      - "127.0.0.1:3000:3000"
    environment:
      - HOST=0.0.0.0
      - PORT=3000
      - BIBLE_BRAIN_API_KEY=${BIBLE_BRAIN_API_KEY}
      - RUST_LOG=thebible=info,tower_http=info
    volumes:
      - ./static:/app/static:ro
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

### Deploy with Docker

```bash
# Build and run
docker-compose up -d

# View logs
docker-compose logs -f

# Stop
docker-compose down
```

---

## Option 3: Cloud Platform Deployment

### Railway

1. Install Railway CLI: `npm i -g @railway/cli`
2. Login: `railway login`
3. Initialize: `railway init`
4. Set environment variables in Railway dashboard
5. Deploy: `railway up`

### Fly.io

1. Install Fly CLI: `curl -L https://fly.io/install.sh | sh`
2. Login: `fly auth login`
3. Launch: `fly launch`
4. Deploy: `fly deploy`

### Render

1. Connect your GitHub repository
2. Create new Web Service
3. Set build command: `cargo build --release`
4. Set start command: `./target/release/server`
5. Add environment variables
6. Deploy

---

## Maintenance

### Updating the Application

```bash
cd /opt/thebible

# Pull latest changes (if using git)
git pull

# Rebuild
cargo build --release

# Restart service
sudo systemctl restart thebible

# Check status
sudo systemctl status thebible
```

### Viewing Logs

```bash
# Service logs
sudo journalctl -u thebible -f

# Nginx logs
sudo tail -f /var/log/nginx/krugerbdg.com.access.log
sudo tail -f /var/log/nginx/krugerbdg.com.error.log
```

### Monitoring

Consider setting up:
- **Uptime monitoring**: UptimeRobot, Pingdom
- **Log aggregation**: Logtail, Papertrail
- **Performance monitoring**: New Relic, Datadog

---

## Troubleshooting

### Service won't start

```bash
# Check service status
sudo systemctl status thebible

# Check logs
sudo journalctl -u thebible -n 50

# Verify binary exists and is executable
ls -lh /opt/thebible/target/release/server
```

### Port already in use

```bash
# Check what's using port 3000
sudo lsof -i :3000

# Change PORT in .env file
```

### SSL certificate issues

```bash
# Renew certificate
sudo certbot renew

# Test renewal
sudo certbot renew --dry-run
```

### Nginx 502 Bad Gateway

```bash
# Check if Rust server is running
curl http://localhost:3000/health

# Check Nginx error logs
sudo tail -f /var/log/nginx/krugerbdg.com.error.log
```

---

## Security Checklist

- [ ] Firewall configured (UFW)
- [ ] SSL/TLS enabled (Let's Encrypt)
- [ ] Service runs as non-root user
- [ ] Environment variables secured (.env not in git)
- [ ] Regular system updates
- [ ] Log rotation configured
- [ ] Backup strategy in place

---

## Performance Optimization

1. **Enable gzip compression** in Nginx
2. **Set up caching** for static assets
3. **Use CDN** for static files (optional)
4. **Monitor resource usage** (CPU, memory)
5. **Consider load balancing** if traffic grows

---

## Backup Strategy

```bash
# Backup script (create /opt/backup-thebible.sh)
#!/bin/bash
BACKUP_DIR="/opt/backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup application
tar -czf $BACKUP_DIR/thebible_$DATE.tar.gz \
    /opt/thebible/static \
    /opt/thebible/.env \
    /opt/thebible/target/release/server

# Keep only last 7 days
find $BACKUP_DIR -name "thebible_*.tar.gz" -mtime +7 -delete
```

Add to crontab:
```bash
0 2 * * * /opt/backup-thebible.sh
```

