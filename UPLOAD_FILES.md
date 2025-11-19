# Upload Files to Linode - Quick Guide

## Step 1: Find Your Linode IP Address

You can find this in your Linode dashboard or by running on your server:
```bash
curl ifconfig.me
```

## Step 2: Upload Files from Your Local Machine

**Open a NEW terminal window on your local Mac** (keep your SSH session open to monitor progress).

Run this command (replace `YOUR_LINODE_IP` with your actual IP):

```bash
cd /Users/brandtkruger/RustroverProjects/TheBible

rsync -avz --progress \
    --exclude='target' \
    --exclude='.git' \
    --exclude='*.md' \
    --exclude='.env' \
    --exclude='.DS_Store' \
    src/ static/ Cargo.toml Cargo.lock \
    root@YOUR_LINODE_IP:/opt/thebible/
```

## Step 3: Verify Upload

**Back on your Linode server** (in your SSH session), run:

```bash
cd /opt/thebible
ls -la
```

You should now see:
- `Cargo.toml`
- `Cargo.lock`
- `src/` directory
- `static/` directory

## Step 4: Build the Application

```bash
cd /opt/thebible
export PATH="/root/.cargo/bin:$PATH"
cargo build --release
```

## Alternative: Using SCP (if rsync doesn't work)

```bash
# From your local machine
cd /Users/brandtkruger/RustroverProjects/TheBible

scp -r src/ static/ Cargo.toml Cargo.lock \
    root@YOUR_LINODE_IP:/opt/thebible/
```

## Need Help?

If you're not sure of your Linode IP, you can:
1. Check your Linode dashboard
2. Or run on the server: `hostname -I` or `ip addr show`

