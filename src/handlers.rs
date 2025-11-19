use axum::{
    extract::Path,
    response::Json,
};
use serde::Serialize;

use crate::api::helloao::HelloAOBibleClient;
use crate::error::{AppError, Result};

#[derive(Serialize)]
pub struct HealthResponse {
    pub status: String,
    pub message: String,
}

pub async fn health() -> Json<HealthResponse> {
    Json(HealthResponse {
        status: "ok".to_string(),
        message: "The Bible API server is running".to_string(),
    })
}

/// Get list of available translations
pub async fn get_translations(
    bible_client: axum::extract::State<HelloAOBibleClient>,
) -> Result<Json<Vec<crate::api::helloao::Translation>>> {
    let translations = bible_client.get_translations().await?;
    Ok(Json(translations))
}

/// Get list of books for a translation
pub async fn get_books(
    bible_client: axum::extract::State<HelloAOBibleClient>,
    Path(translation): Path<String>,
) -> Result<Json<Vec<crate::api::helloao::Book>>> {
    let books = bible_client.get_books(&translation).await?;
    Ok(Json(books))
}

/// Get a chapter from a translation
pub async fn get_chapter(
    bible_client: axum::extract::State<HelloAOBibleClient>,
    Path((translation, book, chapter)): Path<(String, String, String)>,
) -> Result<Json<crate::api::helloao::Chapter>> {
    let chapter_num: u32 = chapter.parse().map_err(|_| {
        AppError::BibleBrainApi("Invalid chapter number".to_string())
    })?;
    
    let chapter_data = bible_client.get_chapter(&translation, &book, chapter_num).await?;
    Ok(Json(chapter_data))
}

// Compatibility endpoints for frontend
/// Get translations (alias for compatibility)
pub async fn get_languages(
    bible_client: axum::extract::State<HelloAOBibleClient>,
) -> Result<Json<Vec<crate::api::helloao::Translation>>> {
    get_translations(bible_client).await
}

/// Get translations as "bibles" for compatibility
pub async fn get_bibles(
    bible_client: axum::extract::State<HelloAOBibleClient>,
) -> Result<Json<Vec<crate::api::helloao::Translation>>> {
    get_translations(bible_client).await
}

/// Get list of available commentaries
pub async fn get_commentaries(
    bible_client: axum::extract::State<HelloAOBibleClient>,
) -> Result<Json<Vec<crate::api::helloao::Commentary>>> {
    let commentaries = bible_client.get_commentaries().await?;
    Ok(Json(commentaries))
}

/// Get commentary for a specific chapter
pub async fn get_commentary(
    bible_client: axum::extract::State<HelloAOBibleClient>,
    Path((commentary_id, book, chapter)): Path<(String, String, String)>,
) -> Result<Json<crate::api::helloao::CommentaryChapter>> {
    let chapter_num: u32 = chapter.parse().map_err(|_| {
        AppError::BibleBrainApi("Invalid chapter number".to_string())
    })?;
    
    let commentary_data = bible_client.get_commentary(&commentary_id, &book, chapter_num).await?;
    Ok(Json(commentary_data))
}
