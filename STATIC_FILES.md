# Static Files Location Guide

## Current Setup

Your `index.html` is already in the **correct location**: `static/index.html`

## How the Server Serves Static Files

Looking at `src/bin/server.rs` line 64:

```rust
.nest_service("/", tower_http::services::ServeDir::new("static"))
```

This means:
- The server looks for a `static/` directory **relative to where the server binary runs**
- Files in `static/` are served at the root URL (`/`)
- `static/index.html` is automatically served when someone visits `/` or `/index.html`

## File Structure

```
TheBible/
├── static/              ← Static files directory
│   └── index.html      ← Your main HTML file (already here!)
├── src/
│   └── bin/
│       └── server.rs   ← Server code that serves static/
└── target/
    └── release/
        └── server      ← Compiled binary
```

## Local Development

When you run locally:

```bash
cargo run --bin server
```

The server looks for `static/` in the project root (where you run the command), so:
- ✅ `static/index.html` → served at `http://localhost:3000/`
- ✅ `static/index.html` → also at `http://localhost:3000/index.html`
- ✅ Any other files in `static/` → served at their relative paths

## Deployment Considerations

### Railway Deployment

Railway automatically includes all files in your project, so:
- ✅ `static/index.html` will be included
- ✅ The server will find it relative to the binary location
- ✅ No changes needed!

### VPS/Server Deployment

When deploying to a server, ensure:

1. **The `static/` directory is in the same location as your binary**:
   ```
   /opt/thebible/
   ├── server              ← Binary
   ├── static/             ← Must be here!
   │   └── index.html
   └── .env
   ```

2. **Or use absolute path** (if needed, modify server.rs):
   ```rust
   .nest_service("/", tower_http::services::ServeDir::new("/opt/thebible/static"))
   ```

### Docker Deployment

In Docker, the `static/` directory is copied into the container, so it works automatically.

## Adding More Static Files

You can add any static files to the `static/` directory:

```
static/
├── index.html          ← Main page
├── css/
│   └── style.css      ← Accessible at /css/style.css
├── js/
│   └── app.js         ← Accessible at /js/app.js
├── images/
│   └── logo.png       ← Accessible at /images/logo.png
└── favicon.ico         ← Accessible at /favicon.ico
```

## Testing Static Files

### Local Testing

```bash
# Start server
cargo run --bin server

# Test in browser or curl
curl http://localhost:3000/
curl http://localhost:3000/index.html
```

### After Deployment

```bash
# Test your deployed site
curl https://krugerbdg.com/
curl https://krugerbdg.com/index.html
```

## Troubleshooting

### File Not Found (404)

**Problem**: Server can't find `static/index.html`

**Solutions**:
1. Verify `static/index.html` exists in project root
2. Check the server is running from the project root directory
3. Verify file permissions: `chmod 644 static/index.html`
4. Check server logs for path errors

### Wrong Working Directory

**Problem**: Server runs from wrong directory

**Solution**: Ensure you run the server from the project root:
```bash
cd /Users/brandtkruger/RustroverProjects/TheBible
cargo run --bin server
```

Or set the working directory in systemd service:
```ini
[Service]
WorkingDirectory=/opt/thebible
```

### Files Not Included in Deployment

**Problem**: Static files missing after deployment

**Solutions**:
- Railway: Files are automatically included
- Docker: Ensure `COPY static ./static` in Dockerfile
- Manual: Copy `static/` directory to server

## Current Status

✅ **Your `index.html` is correctly located at `static/index.html`**

✅ **The server is configured to serve it automatically**

✅ **No changes needed for deployment**

## Quick Reference

- **Location**: `static/index.html` (project root)
- **URL**: `https://krugerbdg.com/` or `https://krugerbdg.com/index.html`
- **Server config**: Line 64 in `src/bin/server.rs`
- **Add more files**: Put them in `static/` directory

