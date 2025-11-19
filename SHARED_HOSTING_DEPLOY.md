# Shared Hosting Deployment Guide

## Your Hosting Information

- **Username**: `krugeqkb`
- **Domain**: `krugerbdg.com`
- **IP Address**: `154.0.162.252`
- **Home Directory**: `/home/krugeqkb`

## Important: Shared Hosting Limitations

⚠️ **Warning**: Shared hosting typically has limitations that may prevent running custom Rust binaries:

1. **No custom binary execution** - Many shared hosts don't allow running custom compiled binaries
2. **No systemd** - Process management may not be available
3. **Port restrictions** - You may not be able to bind to custom ports
4. **Limited root access** - No sudo privileges

## Step 1: Connect via SSH

```bash
ssh krugeqkb@krugerbdg.com
```

Or:
```bash
ssh krugeqkb@154.0.162.252
```

## Step 2: Check Hosting Capabilities

Once connected, run these commands to check what's available:

```bash
# Check if Rust is installed
rustc --version

# Check OS
uname -a
cat /etc/os-release

# Check home directory
pwd
ls -la

# Check if you can create and run binaries
mkdir -p ~/test
echo '#!/bin/bash' > ~/test/test.sh
echo 'echo "Test successful"' >> ~/test/test.sh
chmod +x ~/test/test.sh
~/test/test.sh

# Check available ports (if accessible)
netstat -tuln 2>/dev/null | grep LISTEN || echo "Cannot check ports"
```

## Step 3: Determine Deployment Strategy

### Option A: If Rust is Available and Binaries Work

If you can compile and run Rust binaries:

```bash
# Navigate to your home directory
cd ~

# Create project directory
mkdir -p thebible
cd thebible

# Upload your project files (from local machine)
# Use SCP or SFTP to upload:
# - Cargo.toml
# - Cargo.lock
# - src/ directory
# - static/ directory
# - .env file

# Build the project
cargo build --release

# Test run (in background or screen session)
./target/release/server
```

**Note**: You may need to use a different port or configure your hosting provider's web server to proxy to your application.

### Option B: If Binaries Don't Work - Use Cloud Platform

If shared hosting doesn't support custom binaries, deploy to a cloud platform:

#### Option B1: Railway (Easiest)

1. **Install Railway CLI**:
   ```bash
   npm i -g @railway/cli
   ```

2. **Login and deploy**:
   ```bash
   railway login
   railway init
   railway up
   ```

3. **Set environment variables** in Railway dashboard:
   - `BIBLE_BRAIN_API_KEY`
   - `HOST=0.0.0.0`
   - `PORT` (Railway will provide)

4. **Point your domain** to Railway's provided URL

#### Option B2: Fly.io

1. **Install Fly CLI**:
   ```bash
   curl -L https://fly.io/install.sh | sh
   ```

2. **Create fly.toml** (see below)

3. **Deploy**:
   ```bash
   fly launch
   fly deploy
   ```

#### Option B3: Render

1. Connect GitHub repository
2. Create new Web Service
3. Build: `cargo build --release`
4. Start: `./target/release/server`
5. Add environment variables

## Step 4: Configure Domain (If Using Cloud Platform)

If deploying to a cloud platform, configure your domain:

1. **Get the deployment URL** from your cloud platform
2. **Update DNS records**:
   - Add CNAME record: `krugerbdg.com` → `your-platform-url.com`
   - Or add A record pointing to platform IP

3. **Configure SSL** (usually automatic on cloud platforms)

## Step 5: Alternative - Static Site + API Proxy

If shared hosting supports PHP or Node.js, you could:

1. **Deploy Rust API** to cloud platform
2. **Host static files** on your shared hosting
3. **Proxy API calls** from static site to cloud API

## Recommended Approach

Given shared hosting limitations, I recommend:

1. **Deploy Rust server to Railway or Fly.io** (free tiers available)
2. **Point krugerbdg.com** to the cloud deployment
3. **Keep shared hosting** for other purposes if needed

## Quick Cloud Deployment Commands

### Railway Deployment

```bash
# From your local machine
cd /Users/brandtkruger/RustroverProjects/TheBible

# Install Railway CLI
npm i -g @railway/cli

# Login
railway login

# Initialize project
railway init

# Set environment variables
railway variables set BIBLE_BRAIN_API_KEY=your_key_here

# Deploy
railway up

# Get your URL
railway domain
```

### Fly.io Deployment

First, create `fly.toml`:

```toml
app = "thebible"
primary_region = "iad"

[build]

[http_service]
  internal_port = 3000
  force_https = true
  auto_stop_machines = true
  auto_start_machines = true
  min_machines_running = 0
  processes = ["app"]

[[services]]
  protocol = "tcp"
  internal_port = 3000

  [[services.ports]]
    port = 80
    handlers = ["http"]
    force_https = true

  [[services.ports]]
    port = 443
    handlers = ["tls", "http"]
```

Then deploy:

```bash
fly launch
fly deploy
```

## Testing Your Deployment

After deployment:

```bash
# Test health endpoint
curl https://krugerbdg.com/health

# Test API
curl https://krugerbdg.com/api/languages
```

## Troubleshooting

### SSH Connection Issues

- **Connection refused**: SSH may not be enabled - check hosting control panel
- **Permission denied**: Verify username and password
- **Timeout**: Check firewall or try different network

### Binary Execution Issues

- **Permission denied**: Check file permissions with `ls -la`
- **Command not found**: Binary may not be in PATH
- **Cannot execute**: Hosting may not allow custom binaries

### Port Issues

- **Port in use**: Try different port (8080, 8000, etc.)
- **Cannot bind**: Shared hosting may restrict port binding

## Next Steps

1. **Connect via SSH** and check capabilities
2. **If binaries work**: Follow Option A
3. **If binaries don't work**: Use cloud platform (Option B)
4. **Update DNS** to point to your deployment
5. **Test** your deployment

## Support

If you encounter issues:
1. Check hosting provider documentation
2. Contact hosting support about custom binary execution
3. Consider upgrading to VPS for full control

