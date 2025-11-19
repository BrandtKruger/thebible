# Deploy Now - Cloud Platform Guide

## Current Situation

SSH is not accessible on your shared hosting (`154.0.162.252`). This is common with shared hosting providers. 

**Solution**: Deploy to a cloud platform (Railway or Fly.io) and point your domain there.

## Option 1: Railway Deployment (Recommended - Easiest)

Railway is the easiest option with a free tier.

### Step 1: Install Railway CLI

```bash
npm i -g @railway/cli
```

If you don't have Node.js/npm:
```bash
# Install Homebrew if needed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Node.js
brew install node

# Then install Railway
npm i -g @railway/cli
```

### Step 2: Login to Railway

```bash
railway login
```

This will open your browser to authenticate.

### Step 3: Initialize Project

```bash
cd /Users/brandtkruger/RustroverProjects/TheBible
railway init
```

When prompted:
- Create new project: Yes
- Project name: `thebible` (or your choice)

### Step 4: Set Environment Variables

```bash
railway variables set BIBLE_BRAIN_API_KEY=your_actual_api_key_here
railway variables set HOST=0.0.0.0
railway variables set PORT=3000
railway variables set RUST_LOG=thebible=info,tower_http=info
```

### Step 5: Deploy

```bash
railway up
```

This will:
1. Build your Rust application
2. Deploy it to Railway
3. Give you a URL like: `thebible-production.up.railway.app`

### Step 6: Get Your Deployment URL

```bash
railway domain
```

Or check the Railway dashboard: https://railway.app/dashboard

### Step 7: Point Your Domain

1. **In Railway Dashboard**:
   - Go to your project
   - Click "Settings" → "Domains"
   - Add custom domain: `krugerbdg.com`
   - Railway will give you DNS instructions

2. **Update DNS** (in your domain registrar):
   - Add CNAME record: `krugerbdg.com` → Railway's provided URL
   - Or add A record with Railway's IP (they'll provide this)

3. **Wait for DNS propagation** (5-60 minutes)

### Step 8: Verify Deployment

```bash
# Test the deployment URL
curl https://your-railway-url.up.railway.app/health

# Once DNS is updated
curl https://krugerbdg.com/health
```

---

## Option 2: Fly.io Deployment

### Step 1: Install Fly CLI

```bash
curl -L https://fly.io/install.sh | sh
```

### Step 2: Login

```bash
fly auth login
```

### Step 3: Deploy

```bash
cd /Users/brandtkruger/RustroverProjects/TheBible
fly launch
```

When prompted:
- App name: `thebible` (or your choice)
- Region: Choose closest to you
- Postgres: No
- Redis: No

### Step 4: Set Secrets (Environment Variables)

```bash
fly secrets set BIBLE_BRAIN_API_KEY=your_actual_api_key_here
fly secrets set HOST=0.0.0.0
fly secrets set PORT=3000
fly secrets set RUST_LOG=thebible=info,tower_http=info
```

### Step 5: Deploy

```bash
fly deploy
```

### Step 6: Add Domain

```bash
fly domains add krugerbdg.com
```

Follow the DNS instructions Fly.io provides.

---

## Quick Comparison

| Feature | Railway | Fly.io |
|---------|---------|--------|
| Ease of Use | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| Free Tier | ✅ Yes | ✅ Yes |
| Setup Time | ~5 minutes | ~10 minutes |
| CLI Required | Yes | Yes |

## Recommended: Railway

Railway is recommended because:
- ✅ Easiest setup
- ✅ Automatic builds from git
- ✅ Free tier available
- ✅ Simple domain setup
- ✅ Good documentation

## After Deployment

Once deployed, you can:

1. **Update code**: Push to git, Railway auto-deploys
2. **View logs**: `railway logs` or in dashboard
3. **Monitor**: Check Railway dashboard for metrics
4. **Scale**: Upgrade if needed (free tier is usually enough)

## Troubleshooting

### Build Fails

Check logs:
```bash
railway logs
```

Common issues:
- Missing environment variables
- Build timeout (increase in settings)
- Rust version mismatch

### Domain Not Working

1. Check DNS propagation: https://dnschecker.org
2. Verify DNS records match Railway's instructions
3. Wait up to 60 minutes for propagation

### Application Not Starting

Check environment variables:
```bash
railway variables
```

Ensure `BIBLE_BRAIN_API_KEY` is set correctly.

## Next Steps

1. **Choose platform** (Railway recommended)
2. **Deploy** using steps above
3. **Point domain** to deployment
4. **Test** your site at krugerbdg.com

Your SSH keys are set up correctly, but since SSH isn't available on your hosting, cloud deployment is the best path forward.

