# SSH Connection Guide

## Your Server Information

- **Username**: `krugeqkb`
- **Domain**: `krugerbdg.com`
- **IP Address**: `154.0.162.252`
- **Home Directory**: `/home/krugeqkb`

## Connecting via SSH

### From macOS/Linux Terminal

```bash
ssh krugeqkb@krugerbdg.com
```

Or using the IP address:

```bash
ssh krugeqkb@154.0.162.252
```

### From Windows

**Option 1: Using PowerShell (Windows 10+)**
```powershell
ssh krugeqkb@krugerbdg.com
```

**Option 2: Using PuTTY**
1. Download PuTTY from https://www.putty.org/
2. Enter hostname: `krugerbdg.com` or `154.0.162.252`
3. Port: `22`
4. Connection type: `SSH`
5. Click "Open"
6. Enter username: `krugeqkb`
7. Enter your password when prompted

### First Connection

On first connection, you'll see a security warning:
```
The authenticity of host 'krugerbdg.com (154.0.162.252)' can't be established.
Are you sure you want to continue connecting (yes/no)?
```

Type `yes` and press Enter.

### Using SSH Keys (Recommended)

For passwordless login, set up SSH keys:

**1. Generate SSH key (if you don't have one):**
```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

**2. Copy your public key to the server:**
```bash
ssh-copy-id krugeqkb@krugerbdg.com
```

**3. Test connection:**
```bash
ssh krugeqkb@krugerbdg.com
```

## Important Notes

### Shared Hosting Considerations

Since you're on shared hosting (`/home/krugeqkb`), there may be limitations:

1. **Custom Binary Execution**: Shared hosting may not allow running custom binaries
2. **Port Restrictions**: You may not be able to bind to port 3000
3. **Process Management**: systemd may not be available

### Alternative Deployment Options

If shared hosting doesn't support custom Rust binaries, consider:

1. **Build on server** (if Rust is available):
   ```bash
   # Check if Rust is installed
   rustc --version
   
   # If not, install Rust
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
   ```

2. **Use a VPS** instead of shared hosting for full control

3. **Deploy to cloud platform** (Railway, Fly.io, Render) and point domain

## Checking Your Hosting Environment

Once connected, check what's available:

```bash
# Check OS and version
uname -a
cat /etc/os-release

# Check if Rust is installed
which rustc
rustc --version

# Check available ports
netstat -tuln | grep LISTEN

# Check home directory
pwd
ls -la

# Check disk space
df -h

# Check if you can run custom binaries
mkdir -p ~/test
echo '#!/bin/bash' > ~/test/test.sh
echo 'echo "Hello World"' >> ~/test/test.sh
chmod +x ~/test/test.sh
~/test/test.sh
```

## Troubleshooting SSH Connection

### Connection Timeout (Most Common Issue)

If you get `Operation timed out`, SSH is likely not enabled. See **[SSH_TROUBLESHOOTING.md](SSH_TROUBLESHOOTING.md)** for detailed solutions.

**Quick fixes:**
1. Enable SSH in your hosting control panel (cPanel/Plesk)
2. Try alternative ports: `ssh -p 2222 krugeqkb@154.0.162.252`
3. Contact hosting support to enable SSH
4. Use cloud platform deployment instead (recommended)

### Connection Refused
- Check if SSH is enabled on your hosting account
- Verify port 22 is open
- Try alternative ports (2222, 2200, 7822)
- Contact your hosting provider

### Permission Denied
- Double-check username: `krugeqkb`
- Verify password is correct
- Check if SSH access is enabled in hosting control panel
- Verify your IP is whitelisted (if required)

### Timeout
- SSH may not be enabled on shared hosting
- Check your firewall settings
- Verify the IP address is correct
- Try connecting from a different network
- **Consider cloud platform deployment** as alternative

## Next Steps

After successfully connecting:

1. **Check hosting capabilities** (see commands above)
2. **If Rust binaries are supported**: Follow VPS deployment guide
3. **If not supported**: Consider cloud platform deployment or upgrade to VPS

