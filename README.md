# The Bible - Rust Web Server

A modern Rust web server built with Axum that serves a website and integrates with the HelloAO Bible API.

## Features

- 🚀 **Fast & Modern**: Built with Axum, Tokio, and async/await
- 📚 **HelloAO Bible API Integration**: Full integration with the free HelloAO Bible API
- 🎨 **Static File Serving**: Serves static HTML/CSS/JS files
- 🔒 **Best Practices**: Proper error handling, configuration management, logging
- 🌐 **CORS Support**: Ready for frontend integration
- 📝 **Structured Logging**: Built-in tracing and logging
- 🆓 **No API Key Required**: The HelloAO Bible API is completely free!

## Prerequisites

- Rust 1.70+ (install from [rustup.rs](https://rustup.rs/))
- **No API key needed!** The HelloAO Bible API is free and open ([bible.helloao.org](https://bible.helloao.org))

## Setup

1. **Clone and navigate to the project:**
   ```bash
   cd TheBible
   ```

2. **Copy the example environment file (optional):**
   ```bash
   cp .env.example .env
   ```
   
   **Note**: No API key is required! The HelloAO Bible API is free and open.

4. **Build the project:**
   ```bash
   cargo build --release
   ```

5. **Run the server:**
   ```bash
   cargo run --bin server
   ```

   Or run the release binary:
   ```bash
   ./target/release/server
   ```

The server will start on `http://localhost:3000` (or the port specified in your `.env` file).

## Configuration

Configuration is managed through environment variables:

- `HOST`: Server host (default: `0.0.0.0`)
- `PORT`: Server port (default: `3000`)
- `BIBLE_API_BASE_URL`: Bible API base URL (default: `https://bible.helloao.org/api`)
- `RUST_LOG`: Logging level (optional, default: `thebible=debug,tower_http=debug`)

**Note**: No API key is required! The HelloAO Bible API is completely free.

## API Endpoints

### Health Check
- `GET /health` - Server health status

### HelloAO Bible API Endpoints
- `GET /api/translations` - Get list of available translations
- `GET /api/translations/{translation}/books` - Get books for a translation
- `GET /api/translations/{translation}/books/{book}/chapters/{chapter}` - Get chapter with all verses

### Compatibility Endpoints (for frontend)
- `GET /api/languages` - Alias for translations
- `GET /api/bibles` - Alias for translations
- `GET /api/bibles/{translation}/books` - Get books for a translation
- `GET /api/bibles/{translation}/books/{book}/chapters/{chapter}` - Get chapter with all verses

## Project Structure

```
TheBible/
├── src/
│   ├── bin/
│   │   └── server.rs          # Main server binary
│   ├── lib.rs                 # Library root
│   ├── api/
│   │   └── helloao.rs         # HelloAO Bible API client
│   ├── config.rs              # Configuration management
│   ├── error.rs               # Error types and handling
│   └── handlers.rs            # HTTP request handlers
├── static/                    # Static files (HTML, CSS, JS)
│   └── index.html
├── Cargo.toml                 # Dependencies and project config
├── .env.example               # Example environment variables
└── README.md                  # This file
```

## Development

### Running in Development Mode

```bash
cargo run --bin server
```

### Building for Production

```bash
cargo build --release
```

### Running Tests

```bash
cargo test
```

## Deployment

For detailed deployment instructions, see **[DEPLOYMENT.md](DEPLOYMENT.md)**.

### Quick Start

1. **Build for production:**
   ```bash
   cargo build --release
   ```

2. **Deploy to server:**
   ```bash
   ./deploy.sh production
   ```

### Deployment Options

- **VPS/Server**: Full guide with Nginx, SSL, and systemd setup
- **Docker**: Containerized deployment with docker-compose
- **Cloud Platforms**: Railway, Fly.io, Render instructions

See [DEPLOYMENT.md](DEPLOYMENT.md) for complete instructions.

## Best Practices Implemented

1. **Error Handling**: Custom error types with proper HTTP status codes
2. **Configuration**: Environment-based configuration with defaults
3. **Logging**: Structured logging with tracing
4. **Type Safety**: Strong typing throughout with Rust's type system
5. **Async/Await**: Non-blocking I/O with Tokio
6. **Separation of Concerns**: Modular code structure
7. **API Client**: Reusable HTTP client for Bible Brain API
8. **Middleware**: CORS and request tracing middleware

## License

This project is for personal use. The HelloAO Bible API is provided under the MIT license and is free to use, including for commercial purposes. See [HelloAO Bible API](https://bible.helloao.org) for details.

## Resources

- [HelloAO Bible API Documentation](https://bible.helloao.org/docs/guide/)
- [HelloAO Bible API GitHub](https://github.com/HelloAOLab/bible-api)
- [Axum Documentation](https://docs.rs/axum/)
- [Rust Book](https://doc.rust-lang.org/book/)

