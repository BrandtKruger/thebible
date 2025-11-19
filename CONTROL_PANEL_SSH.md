# Finding SSH Settings in Your Control Panel

Since your SSH key is already authorized, you need to find the **SSH port** and **enable SSH** in your hosting control panel.

## Step 1: Access Your Control Panel

Try these URLs (one should work):

### cPanel
```
https://krugerbdg.com:2083
https://154.0.162.252:2083
https://cpanel.krugerbdg.com
```

### Plesk
```
https://krugerbdg.com:8443
https://154.0.162.252:8443
```

### DirectAdmin
```
https://krugerbdg.com:2222
https://154.0.162.252:2222
```

## Step 2: Find SSH Settings

### In cPanel:

1. **Look for "Security" section**
2. **Click "SSH Access"** or **"Terminal"**
3. **You should see**:
   - SSH Status (Enabled/Disabled)
   - SSH Port (usually 2222, 2200, or 7822)
   - Authorized Keys (your key should be listed)

**Enable SSH if disabled** and **note the port number**.

### In Plesk:

1. **Go to "Tools & Settings"**
2. **Click "SSH Access"**
3. **Check**:
   - SSH Access Status
   - Port number
   - Your authorized keys

### In DirectAdmin:

1. **Go to "SSH Management"**
2. **Check SSH Access** and port

## Step 3: Enable SSH (If Disabled)

If SSH shows as "Disabled":

1. **Click "Enable SSH"** or toggle switch
2. **Note the port** (might be different from 22)
3. **Check for IP restrictions** - you may need to whitelist your IP
4. **Save changes**

## Step 4: Check IP Restrictions

Some hosts require you to whitelist your IP:

1. **Find "IP Access"** or **"Allowed IPs"**
2. **Add your current IP**: `165.49.38.38` (your last login IP)
3. **Or allow all IPs** (less secure but easier)

## Step 5: Note the SSH Port

Common ports for shared hosting:
- **22** (standard, but often blocked)
- **2222** (very common)
- **2200** (common)
- **7822** (some providers)
- **22000** (some providers)

**Write down the port number shown in your control panel.**

## Step 6: Connect Using the Correct Port

Once you know the port, connect:

```bash
# Replace PORT with the port from your control panel
ssh -p PORT krugeqkb@154.0.162.252

# Or update your SSH config
nano ~/.ssh/config
```

Add:
```
Host krugerbdg
    HostName 154.0.162.252
    User krugeqkb
    Port 2222  # ← Use the port from control panel
    IdentityFile ~/.ssh/id_rsa_project
```

Then:
```bash
ssh krugerbdg
```

## What to Look For

In your control panel, you should see something like:

```
SSH Access: ✅ Enabled
SSH Port: 2222
Authorized Keys: 
  - ssh-rsa AAAAB3... (your key)
```

## If You Can't Find SSH Settings

1. **Check your hosting welcome email** - it usually has control panel URL and SSH info
2. **Look for "Terminal"** or **"Shell Access"** instead of "SSH"
3. **Contact hosting support** and ask:
   - "What port should I use for SSH?"
   - "How do I enable SSH access?"
   - "Is SSH enabled on my account?"

## Quick Checklist

- [ ] Logged into control panel
- [ ] Found SSH/Terminal settings
- [ ] SSH is enabled
- [ ] Noted the SSH port number
- [ ] Checked IP restrictions
- [ ] Tried connecting with correct port

## After Finding the Port

Update your connection:

```bash
# Test with the port from control panel
ssh -p 2222 krugeqkb@154.0.162.252  # Replace 2222 with your port

# If it works, update SSH config
```

Your key is already authorized, so once SSH is enabled and you use the correct port, it should work!

