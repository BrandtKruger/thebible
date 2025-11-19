# Linode Deployment - Quick Reference

## Initial Deployment

### Option 1: Automated Script (Recommended)

```bash
# Upload script to server
scp linode-deploy.sh root@your-linode-ip:/root/

# SSH into server
ssh root@your-linode-ip

# Run deployment script
chmod +x linode-deploy.sh
./linode-deploy.sh
```

### Option 2: Manual Steps

1. **Upload files to server:**
   ```bash
   # From your local machine
   rsync -avz --exclude 'target' --exclude '.git' \
       /path/to/TheBible/ root@your-linode-ip:/opt/thebible/
   ```

2. **SSH and run setup:**
   ```bash
   ssh root@your-linode-ip
   cd /opt/thebible
   # Follow LINODE_DEPLOY.md manual steps
   ```

## Common Commands

### Service Management

```bash
# Start service
sudo systemctl start thebible

# Stop service
sudo systemctl stop thebible

# Restart service
sudo systemctl restart thebible

# Check status
sudo systemctl status thebible

# View logs
sudo journalctl -u thebible -f

# View last 100 log lines
sudo journalctl -u thebible -n 100
```

### Application Updates

```bash
cd /opt/thebible

# Pull latest code (if using git)
sudo -u thebible git pull

# Rebuild
sudo -u thebible bash -c "source ~/.cargo/env && cargo build --release"

# Restart
sudo systemctl restart thebible
```

### Nginx Management

```bash
# Test configuration
sudo nginx -t

# Reload configuration
sudo systemctl reload nginx

# Restart Nginx
sudo systemctl restart nginx

# View error logs
sudo tail -f /var/log/nginx/error.log

# View access logs
sudo tail -f /var/log/nginx/access.log
```

### SSL Certificate

```bash
# Get certificate
sudo certbot --nginx -d krugerbdg.com -d www.krugerbdg.com

# Renew certificate
sudo certbot renew

# Test renewal
sudo certbot renew --dry-run

# Check certificate status
sudo certbot certificates
```

### Firewall

```bash
# Check status
sudo ufw status

# Allow port
sudo ufw allow 3000/tcp

# Deny port
sudo ufw deny 3000/tcp

# Reload firewall
sudo ufw reload
```

### Troubleshooting

```bash
# Check if port is in use
sudo netstat -tlnp | grep 3000

# Check process
ps aux | grep server

# Check disk space
df -h

# Check memory
free -h

# Test local connection
curl http://127.0.0.1:3000/health

# Test external connection
curl https://krugerbdg.com/health
```

## File Locations

```
/opt/thebible/              # Application directory
├── .env                    # Environment variables
├── src/                    # Source code
├── static/                 # Static files
└── target/release/server   # Compiled binary

/etc/systemd/system/thebible.service  # Systemd service file
/etc/nginx/sites-available/thebible   # Nginx configuration
/var/log/nginx/             # Nginx logs
```

## Environment Variables

Edit `/opt/thebible/.env`:

```bash
HOST=127.0.0.1
PORT=3000
BIBLE_API_BASE_URL=https://bible.helloao.org/api
RUST_LOG=info
```

After editing, restart the service:
```bash
sudo systemctl restart thebible
```

## Backup

```bash
# Backup application
tar -czf thebible-backup-$(date +%Y%m%d).tar.gz \
    /opt/thebible \
    /etc/systemd/system/thebible.service \
    /etc/nginx/sites-available/thebible

# Backup to remote location
scp thebible-backup-*.tar.gz user@backup-server:/backups/
```

## Monitoring

```bash
# Monitor service logs
sudo journalctl -u thebible -f

# Monitor system resources
htop

# Monitor network connections
sudo netstat -tulpn

# Monitor disk I/O
sudo iotop
```

## Security Checklist

- [ ] Firewall configured (UFW)
- [ ] SSL certificate installed
- [ ] Non-root user for application
- [ ] Service running as non-root user
- [ ] SSH key authentication enabled
- [ ] Root login disabled (optional)
- [ ] Fail2ban installed
- [ ] Regular system updates scheduled
- [ ] Backups configured

## Quick Fixes

### Service won't start
```bash
sudo journalctl -u thebible -n 50
sudo systemctl restart thebible
```

### Nginx 502 Bad Gateway
```bash
# Check if service is running
sudo systemctl status thebible

# Check if port is correct
sudo netstat -tlnp | grep 3000

# Check Nginx config
sudo nginx -t
```

### Permission denied
```bash
sudo chown -R thebible:thebible /opt/thebible
sudo chmod 600 /opt/thebible/.env
```

### Out of disk space
```bash
# Clean up old builds
cd /opt/thebible
sudo -u thebible cargo clean

# Remove old logs
sudo journalctl --vacuum-time=7d
```

## Performance Tuning

### Increase file descriptor limit
Edit `/etc/systemd/system/thebible.service`:
```ini
LimitNOFILE=65536
```

Then:
```bash
sudo systemctl daemon-reload
sudo systemctl restart thebible
```

### Nginx caching (optional)
Add to Nginx config:
```nginx
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=thebible_cache:10m max_size=100m;
```

## Support

For detailed instructions, see [LINODE_DEPLOY.md](LINODE_DEPLOY.md)

