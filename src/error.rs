use axum::{
    http::StatusCode,
    response::{IntoResponse, Response},
    Json,
};
use serde_json::json;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum AppError {
    #[error("Bible Brain API error: {0}")]
    BibleBrainApi(String),

    #[error("HTTP client error: {0}")]
    HttpClient(#[from] reqwest::Error),

    #[error("Serialization error: {0}")]
    Serialization(#[from] serde_json::Error),

    #[error("Configuration error: {0}")]
    Config(#[from] config::ConfigError),

    #[error("Internal server error: {0}")]
    Internal(#[from] anyhow::Error),
}

impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        let (status, error_message) = match self {
            AppError::BibleBrainApi(msg) => (StatusCode::BAD_GATEWAY, msg),
            AppError::HttpClient(e) => (
                StatusCode::BAD_GATEWAY,
                format!("HTTP client error: {}", e),
            ),
            AppError::Serialization(e) => (
                StatusCode::INTERNAL_SERVER_ERROR,
                format!("Serialization error: {}", e),
            ),
            AppError::Config(e) => (
                StatusCode::INTERNAL_SERVER_ERROR,
                format!("Configuration error: {}", e),
            ),
            AppError::Internal(e) => (
                StatusCode::INTERNAL_SERVER_ERROR,
                format!("Internal error: {}", e),
            ),
        };

        let body = Json(json!({
            "error": error_message
        }));

        (status, body).into_response()
    }
}

pub type Result<T> = std::result::Result<T, AppError>;

