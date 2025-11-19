use axum::{
    routing::get,
    Router,
};
use std::net::SocketAddr;
use tower::ServiceBuilder;
use tower_http::{
    cors::CorsLayer,
    trace::TraceLayer,
};
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

use thebible::{
    api::helloao::HelloAOBibleClient,
    config::Config,
    handlers,
};

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // Load environment variables
    dotenv::dotenv().ok();

    // Initialize tracing
    tracing_subscriber::registry()
        .with(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "thebible=debug,tower_http=debug".into()),
        )
        .with(tracing_subscriber::fmt::layer())
        .init();

    // Load configuration
    let config = Config::from_env()?;
    tracing::info!("Loaded configuration: {:?}", config);

    // Create HelloAO Bible API client (no API key needed!)
    let bible_client = HelloAOBibleClient::new(config.bible_api.base_url.clone());

    // Build application routes
    let app = Router::new()
        // Health check
        .route("/health", get(handlers::health))
        // HelloAO API routes
        .route("/api/translations", get(handlers::get_translations))
        .route("/api/translations/:translation/books", get(handlers::get_books))
        .route(
            "/api/translations/:translation/books/:book/chapters/:chapter",
            get(handlers::get_chapter),
        )
        // Commentary routes
        .route("/api/commentaries", get(handlers::get_commentaries))
        .route(
            "/api/commentaries/:commentary_id/books/:book/chapters/:chapter",
            get(handlers::get_commentary),
        )
        // Compatibility routes for frontend
        .route("/api/languages", get(handlers::get_languages))
        .route("/api/bibles", get(handlers::get_bibles))
        .route("/api/bibles/:translation/books", get(handlers::get_books))
        .route(
            "/api/bibles/:translation/books/:book/chapters/:chapter",
            get(handlers::get_chapter),
        )
        // Serve static files
        .nest_service("/", tower_http::services::ServeDir::new("static"))
        // Add middleware
        .layer(
            ServiceBuilder::new()
                .layer(TraceLayer::new_for_http())
                .layer(CorsLayer::permissive())
                .into_inner(),
        )
        .with_state(bible_client);

    // Start server
    let addr = SocketAddr::from(([0, 0, 0, 0], config.server.port));
    tracing::info!("Server listening on http://{}", addr);

    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}

