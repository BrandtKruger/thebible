# SSH Key Setup Guide

## Overview

SSH keys provide passwordless, secure authentication to your server. This guide covers setting up SSH keys on macOS.

## Step 1: Check for Existing SSH Keys

First, check if you already have SSH keys:

```bash
ls -la ~/.ssh
```

Look for files like:
- `id_rsa` and `id_rsa.pub` (RSA keys)
- `id_ed25519` and `id_ed25519.pub` (Ed25519 keys - recommended)
- `id_ecdsa` and `id_ecdsa.pub` (ECDSA keys)

If you see `.pub` files, you already have SSH keys!

## Step 2: Generate a New SSH Key (If Needed)

If you don't have SSH keys, generate a new one:

### Option A: Ed25519 (Recommended - Most Secure)

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

### Option B: RSA (Older, but widely supported)

```bash
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
```

**When prompted:**
- **File location**: Press Enter to accept default (`~/.ssh/id_ed25519` or `~/.ssh/id_rsa`)
- **Passphrase**: Enter a passphrase (recommended) or press Enter for no passphrase

## Step 3: Add SSH Key to ssh-agent

The ssh-agent manages your SSH keys. Add your key:

```bash
# Start the ssh-agent
eval "$(ssh-agent -s)"

# Add your SSH key to the ssh-agent
ssh-add ~/.ssh/id_ed25519
```

Or for RSA:
```bash
ssh-add ~/.ssh/id_rsa
```

### Make ssh-agent Start Automatically (macOS)

Add this to your `~/.ssh/config` file:

```bash
# Create or edit the config file
nano ~/.ssh/config
```

Add these lines:

```
Host *
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519
```

Then add your key to the macOS keychain:

```bash
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

## Step 4: Copy Your Public Key

Display your public key to copy it:

```bash
# For Ed25519
cat ~/.ssh/id_ed25519.pub

# For RSA
cat ~/.ssh/id_rsa.pub
```

**Copy the entire output** - it will look something like:
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGx... your_email@example.com
```

## Step 5: Add Public Key to Your Hosting Account

### Option A: Through Hosting Control Panel

1. **Log into your hosting control panel** (cPanel, Plesk, etc.)
2. **Find SSH/Security settings**:
   - cPanel: Security → SSH Access → Manage SSH Keys
   - Plesk: Tools & Settings → SSH Keys
3. **Import or Add SSH Key**:
   - Click "Import" or "Add SSH Key"
   - Paste your public key
   - Save

### Option B: Manual Setup (If SSH is Working)

If you can already SSH in with a password:

```bash
# Connect to your server
ssh krugeqkb@krugerbdg.com

# Once connected, create .ssh directory if it doesn't exist
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Add your public key to authorized_keys
nano ~/.ssh/authorized_keys
# Paste your public key, save and exit

# Set correct permissions
chmod 600 ~/.ssh/authorized_keys
```

### Option C: Using ssh-copy-id (Easiest)

If SSH is working with password:

```bash
ssh-copy-id krugeqkb@krugerbdg.com
```

Or with a specific port:
```bash
ssh-copy-id -p 2222 krugeqkb@krugerbdg.com
```

This automatically copies your public key to the server.

## Step 6: Test SSH Key Authentication

Try connecting:

```bash
ssh krugeqkb@krugerbdg.com
```

Or with a specific port:
```bash
ssh -p 2222 krugeqkb@krugerbdg.com
```

If set up correctly, you should connect **without entering a password**.

## Step 7: Configure SSH for Your Host (Optional)

Create/edit `~/.ssh/config` for easier connections:

```bash
nano ~/.ssh/config
```

Add:

```
Host krugerbdg
    HostName krugerbdg.com
    User krugeqkb
    Port 22
    IdentityFile ~/.ssh/id_ed25519
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

Or if using a different port:

```
Host krugerbdg
    HostName 154.0.162.252
    User krugeqkb
    Port 2222
    IdentityFile ~/.ssh/id_ed25519
```

Then you can connect simply with:
```bash
ssh krugerbdg
```

## Troubleshooting

### Key Not Working

1. **Check key permissions**:
   ```bash
   chmod 600 ~/.ssh/id_ed25519
   chmod 644 ~/.ssh/id_ed25519.pub
   chmod 700 ~/.ssh
   ```

2. **Verify key is added to ssh-agent**:
   ```bash
   ssh-add -l
   ```

3. **Test with verbose output**:
   ```bash
   ssh -v krugeqkb@krugerbdg.com
   ```

### "Permission denied (publickey)"

- Verify your public key is in `~/.ssh/authorized_keys` on the server
- Check file permissions on server: `chmod 600 ~/.ssh/authorized_keys`
- Ensure your hosting provider supports SSH key authentication

### Key Not Found

```bash
# List all keys
ls -la ~/.ssh/

# If key exists but not found, specify it explicitly
ssh -i ~/.ssh/id_ed25519 krugeqkb@krugerbdg.com
```

## Quick Reference Commands

```bash
# Generate new Ed25519 key
ssh-keygen -t ed25519 -C "your_email@example.com"

# Add key to ssh-agent
ssh-add ~/.ssh/id_ed25519

# Display public key
cat ~/.ssh/id_ed25519.pub

# Copy key to server (if SSH password works)
ssh-copy-id krugeqkb@krugerbdg.com

# Test connection
ssh krugeqkb@krugerbdg.com

# List loaded keys
ssh-add -l
```

## Security Best Practices

1. **Use a passphrase** on your private key
2. **Never share your private key** (`id_ed25519` or `id_rsa`)
3. **Only share your public key** (`.pub` file)
4. **Use Ed25519** instead of RSA when possible
5. **Keep your private key secure** - don't commit it to git

## Next Steps

Once SSH key authentication is working:

1. You can connect without passwords
2. Set up automated deployments
3. Use git over SSH
4. Configure your server

## For Your Specific Setup

Since you're having SSH connection issues, you may need to:

1. **First enable SSH** in your hosting control panel
2. **Then add your SSH key** through the control panel
3. **Or use ssh-copy-id** once SSH is enabled and working

If SSH still doesn't work after adding keys, consider the cloud platform deployment option (Railway/Fly.io) as an alternative.

