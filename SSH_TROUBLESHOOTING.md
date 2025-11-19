# SSH Connection Troubleshooting

## Issue: Connection Timeout

If you're getting:
```
ssh: connect to host 154.0.162.252 port 22: Operation timed out
```

This typically means SSH is not enabled or accessible on your shared hosting account.

## Solutions

### Solution 1: Enable SSH in Hosting Control Panel

Most shared hosting providers require you to enable SSH through their control panel:

1. **Log into your hosting control panel** (cPanel, Plesk, or custom panel)
2. **Look for SSH/Security settings**:
   - In cPanel: Look for "Terminal" or "SSH Access" under Security section
   - Enable SSH access
   - You may need to whitelist your IP address
3. **Check for SSH keys**: Some hosts require SSH key setup
4. **Note the SSH port**: It might not be 22 (could be 2222, 2200, etc.)

### Solution 2: Check Alternative Ports

Try common alternative SSH ports:

```bash
# Try port 2222 (common for shared hosting)
ssh -p 2222 krugeqkb@154.0.162.252

# Try port 2200
ssh -p 2200 krugeqkb@154.0.162.252

# Try port 7822
ssh -p 7822 krugeqkb@154.0.162.252
```

### Solution 3: Contact Your Hosting Provider

Contact your hosting provider's support and ask:
- "Is SSH enabled on my account?"
- "What port should I use for SSH?"
- "Do I need to enable SSH access in the control panel?"
- "Are there any IP restrictions for SSH?"

### Solution 4: Use SFTP Instead

If SSH isn't available, you can use SFTP (File Transfer Protocol) to upload files:

**Using FileZilla (GUI):**
1. Download FileZilla: https://filezilla-project.org/
2. Host: `sftp://154.0.162.252` or `sftp://krugerbdg.com`
3. Username: `krugeqkb`
4. Port: `22` (or try `2222`)
5. Password: Your hosting password

**Using command line (macOS/Linux):**
```bash
sftp krugeqkb@154.0.162.252
```

### Solution 5: Use Hosting Control Panel File Manager

Most shared hosting providers have a web-based file manager:
- cPanel: File Manager
- Plesk: File Manager
- Custom panel: Look for "Files" or "File Manager"

You can upload files directly through the web interface.

## Alternative: Deploy Without SSH

Since SSH may not be available, here are deployment alternatives:

### Option A: Cloud Platform Deployment (Recommended)

Deploy to Railway or Fly.io, then point your domain:

**Railway:**
```bash
cd /Users/brandtkruger/RustroverProjects/TheBible
npm i -g @railway/cli
railway login
railway init
railway variables set BIBLE_BRAIN_API_KEY=your_key_here
railway up
```

Then update DNS to point to Railway's URL.

**Fly.io:**
```bash
cd /Users/brandtkruger/RustroverProjects/TheBible
curl -L https://fly.io/install.sh | sh
fly launch
fly deploy
```

### Option B: Use Hosting Provider's Deployment Features

Some shared hosting providers offer:
- **Git deployment**: Connect GitHub repo and auto-deploy
- **One-click installers**: For specific frameworks
- **Custom build scripts**: Through control panel

Check your hosting control panel for these options.

### Option C: Static Site + External API

1. **Deploy Rust API** to cloud platform (Railway/Fly.io)
2. **Host static HTML files** on your shared hosting (via File Manager)
3. **Update API URLs** in static files to point to cloud API

## Checking Your Hosting Control Panel

Common hosting control panels:

1. **cPanel** (most common):
   - URL: `https://krugerbdg.com:2083` or `https://cpanel.krugerbdg.com`
   - Look for: "Terminal", "SSH Access", "Security" sections

2. **Plesk**:
   - URL: `https://krugerbdg.com:8443`
   - Look for: "SSH Access" in settings

3. **Custom Panel**:
   - Check your hosting welcome email
   - Look for "Control Panel" or "Dashboard" link

## Testing Connection

Try these diagnostic commands:

```bash
# Test if port 22 is open
nc -zv 154.0.162.252 22

# Test alternative ports
nc -zv 154.0.162.252 2222
nc -zv 154.0.162.252 2200

# Try with verbose output
ssh -v krugeqkb@154.0.162.252
```

## Next Steps

1. **Check your hosting control panel** for SSH settings
2. **Contact hosting support** if SSH isn't available
3. **Consider cloud platform deployment** (Railway/Fly.io) as alternative
4. **Use SFTP/File Manager** to upload files if needed

## Recommended Path Forward

Given SSH connection issues, I recommend:

1. **Deploy to Railway** (easiest, free tier available)
2. **Point krugerbdg.com DNS** to Railway deployment
3. **Keep shared hosting** for other purposes

This avoids SSH issues and gives you full control over your Rust application.

