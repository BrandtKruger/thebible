# SSH Connection with Authorized Key

## Your Situation

✅ Your SSH key `id_rsa` is **already authorized** on the server  
❌ But SSH connection still times out

This usually means:
1. SSH service might be disabled
2. Wrong port (not 22)
3. Firewall blocking the connection
4. SSH needs to be enabled in hosting control panel

## Step 1: Try Connecting with Explicit Key

Since your key is authorized, try connecting explicitly:

```bash
# Using the project key
ssh -i ~/.ssh/id_rsa_project krugeqkb@154.0.162.252

# Or using your default key
ssh -i ~/.ssh/id_rsa krugeqkb@154.0.162.252
```

## Step 2: Try Alternative Ports

Many shared hosting providers use non-standard SSH ports. Try:

```bash
# Port 2222 (very common)
ssh -p 2222 -i ~/.ssh/id_rsa_project krugeqkb@154.0.162.252

# Port 2200
ssh -p 2200 -i ~/.ssh/id_rsa_project krugeqkb@154.0.162.252

# Port 7822
ssh -p 7822 -i ~/.ssh/id_rsa_project krugeqkb@154.0.162.252

# Port 22000
ssh -p 22000 -i ~/.ssh/id_rsa_project krugeqkb@154.0.162.252
```

## Step 3: Check Hosting Control Panel

Since your key is "authorized", you have access to the control panel. Check:

### cPanel
1. Log into cPanel: `https://krugerbdg.com:2083` or `https://154.0.162.252:2083`
2. Look for: **Security** → **SSH Access** or **Terminal**
3. Check:
   - Is SSH enabled?
   - What port is shown?
   - Are there IP restrictions?

### Plesk
1. Log into Plesk: `https://krugerbdg.com:8443`
2. Look for: **Tools & Settings** → **SSH Access**
3. Check SSH status and port

### Other Control Panels
Look for:
- "SSH Access"
- "Terminal"
- "Security" → "SSH"
- "Server Access"

## Step 4: Enable SSH (If Disabled)

If SSH is disabled in the control panel:

1. **Enable SSH Access**
2. **Note the SSH Port** (might not be 22)
3. **Check IP Restrictions** - you may need to whitelist your IP
4. **Save changes**

## Step 5: Update SSH Config

Once you know the correct port, update your SSH config:

```bash
nano ~/.ssh/config
```

Add or update:

```
Host krugerbdg krugerbdg.com
    HostName 154.0.162.252
    User krugeqkb
    Port 2222  # ← Change to correct port from control panel
    IdentityFile ~/.ssh/id_rsa_project
    AddKeysToAgent yes
    UseKeychain yes
```

Then connect:
```bash
ssh krugerbdg
```

## Step 6: Check Your Public Key Matches

Verify your public key matches what's authorized on the server:

```bash
# Display your public key
cat ~/.ssh/id_rsa_project.pub

# Compare with what's on server (if you can access via other means)
```

## Common Issues & Solutions

### Issue: "Connection timed out"
**Cause**: SSH service not running or port blocked  
**Solution**: Enable SSH in control panel, check firewall

### Issue: "Connection refused"
**Cause**: Wrong port or SSH disabled  
**Solution**: Try alternative ports, enable SSH

### Issue: "Permission denied (publickey)"
**Cause**: Key not authorized or wrong key  
**Solution**: Verify key is in server's `~/.ssh/authorized_keys`

### Issue: "Host key verification failed"
**Cause**: Server key changed  
**Solution**: 
```bash
ssh-keygen -R 154.0.162.252
ssh-keygen -R krugerbdg.com
```

## Finding SSH Port in Control Panel

### cPanel
- **Security** → **SSH Access** → Look for "SSH Port" or "Port"
- Usually shows: "SSH Port: 2222" or similar

### Plesk
- **Tools & Settings** → **SSH Access** → Port number shown

### DirectAdmin
- **Account Manager** → **SSH Access** → Port shown

## Testing Connection

```bash
# Test with verbose output (shows what's happening)
ssh -v krugeqkb@154.0.162.252

# Test specific port
ssh -v -p 2222 krugeqkb@154.0.162.252

# Test with explicit key
ssh -v -i ~/.ssh/id_rsa_project -p 2222 krugeqkb@154.0.162.252
```

## Alternative: Contact Hosting Support

If SSH still doesn't work after checking the control panel:

1. **Contact your hosting provider**
2. **Ask**:
   - "What port should I use for SSH?"
   - "Is SSH enabled on my account?"
   - "Are there any IP restrictions?"
   - "Can you enable SSH access?"

## Quick Test Script

Run this to test multiple ports:

```bash
for port in 22 2222 2200 7822 22000; do
  echo "Testing port $port..."
  ssh -o ConnectTimeout=5 -p $port krugeqkb@154.0.162.252 "echo 'Port $port works!'" 2>&1 | head -1
done
```

## Next Steps

1. **Check your hosting control panel** for SSH settings
2. **Note the SSH port** (if different from 22)
3. **Try connecting with that port**
4. **Update SSH config** with correct port
5. **If still not working**: Contact hosting support

## Important Note

Since your key is already authorized, the issue is likely:
- SSH service disabled
- Wrong port
- Firewall blocking

The control panel should show you the correct port and SSH status.

