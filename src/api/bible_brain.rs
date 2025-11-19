use crate::error::{AppError, Result};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[derive(Debug, Clone)]
pub struct BibleBrainClient {
    client: reqwest::Client,
    base_url: String,
    api_key: String,
}

impl BibleBrainClient {
    pub fn new(base_url: String, api_key: String) -> Self {
        Self {
            client: reqwest::Client::new(),
            base_url,
            api_key,
        }
    }

    /// Get list of available languages
    pub async fn get_languages(&self) -> Result<Vec<Language>> {
        let url = format!("{}/languages", self.base_url);
        let response = self
            .client
            .get(&url)
            .header("dbp-api-key", &self.api_key)
            .send()
            .await?;

        if !response.status().is_success() {
            return Err(AppError::BibleBrainApi(format!(
                "Failed to fetch languages: {}",
                response.status()
            )));
        }

        let languages: Vec<Language> = response.json().await?;
        Ok(languages)
    }

    /// Get list of available Bibles for a language
    pub async fn get_bibles(&self, language_code: &str) -> Result<Vec<Bible>> {
        let url = format!("{}/bibles", self.base_url);
        let mut params = HashMap::new();
        params.insert("language_code", language_code);

        let response = self
            .client
            .get(&url)
            .header("dbp-api-key", &self.api_key)
            .query(&params)
            .send()
            .await?;

        if !response.status().is_success() {
            return Err(AppError::BibleBrainApi(format!(
                "Failed to fetch bibles: {}",
                response.status()
            )));
        }

        let bibles: Vec<Bible> = response.json().await?;
        Ok(bibles)
    }

    /// Get books for a specific Bible
    pub async fn get_books(&self, bible_id: &str) -> Result<Vec<Book>> {
        let url = format!("{}/bibles/{}/books", self.base_url, bible_id);
        let response = self
            .client
            .get(&url)
            .header("dbp-api-key", &self.api_key)
            .send()
            .await?;

        if !response.status().is_success() {
            return Err(AppError::BibleBrainApi(format!(
                "Failed to fetch books: {}",
                response.status()
            )));
        }

        let books: Vec<Book> = response.json().await?;
        Ok(books)
    }

    /// Get chapters for a specific book
    pub async fn get_chapters(&self, bible_id: &str, book_id: &str) -> Result<Vec<Chapter>> {
        let url = format!("{}/bibles/{}/books/{}/chapters", self.base_url, bible_id, book_id);
        let response = self
            .client
            .get(&url)
            .header("dbp-api-key", &self.api_key)
            .send()
            .await?;

        if !response.status().is_success() {
            return Err(AppError::BibleBrainApi(format!(
                "Failed to fetch chapters: {}",
                response.status()
            )));
        }

        let chapters: Vec<Chapter> = response.json().await?;
        Ok(chapters)
    }

    /// Get verses for a specific chapter
    pub async fn get_verses(
        &self,
        bible_id: &str,
        book_id: &str,
        chapter_id: &str,
    ) -> Result<Vec<Verse>> {
        let url = format!(
            "{}/bibles/{}/books/{}/chapters/{}/verses",
            self.base_url, bible_id, book_id, chapter_id
        );
        let response = self
            .client
            .get(&url)
            .header("dbp-api-key", &self.api_key)
            .send()
            .await?;

        if !response.status().is_success() {
            return Err(AppError::BibleBrainApi(format!(
                "Failed to fetch verses: {}",
                response.status()
            )));
        }

        let verses: Vec<Verse> = response.json().await?;
        Ok(verses)
    }

    /// Get verse content
    pub async fn get_verse_content(
        &self,
        bible_id: &str,
        book_id: &str,
        chapter_id: &str,
        verse_id: &str,
    ) -> Result<VerseContent> {
        let url = format!(
            "{}/bibles/{}/books/{}/chapters/{}/verses/{}",
            self.base_url, bible_id, book_id, chapter_id, verse_id
        );
        let response = self
            .client
            .get(&url)
            .header("dbp-api-key", &self.api_key)
            .send()
            .await?;

        if !response.status().is_success() {
            return Err(AppError::BibleBrainApi(format!(
                "Failed to fetch verse content: {}",
                response.status()
            )));
        }

        let content: VerseContent = response.json().await?;
        Ok(content)
    }

    /// Get videos for a specific Bible
    pub async fn get_bible_videos(&self, bible_id: &str) -> Result<Vec<Video>> {
        let url = format!("{}/bibles/{}/videos", self.base_url, bible_id);
        let response = self
            .client
            .get(&url)
            .header("dbp-api-key", &self.api_key)
            .send()
            .await?;

        if !response.status().is_success() {
            return Err(AppError::BibleBrainApi(format!(
                "Failed to fetch videos: {}",
                response.status()
            )));
        }

        let videos: Vec<Video> = response.json().await?;
        Ok(videos)
    }

    /// Get videos for a specific book
    pub async fn get_book_videos(
        &self,
        bible_id: &str,
        book_id: &str,
    ) -> Result<Vec<Video>> {
        let url = format!("{}/bibles/{}/books/{}/videos", self.base_url, bible_id, book_id);
        let response = self
            .client
            .get(&url)
            .header("dbp-api-key", &self.api_key)
            .send()
            .await?;

        if !response.status().is_success() {
            return Err(AppError::BibleBrainApi(format!(
                "Failed to fetch book videos: {}",
                response.status()
            )));
        }

        let videos: Vec<Video> = response.json().await?;
        Ok(videos)
    }

    /// Get videos for a specific chapter
    pub async fn get_chapter_videos(
        &self,
        bible_id: &str,
        book_id: &str,
        chapter_id: &str,
    ) -> Result<Vec<Video>> {
        let url = format!(
            "{}/bibles/{}/books/{}/chapters/{}/videos",
            self.base_url, bible_id, book_id, chapter_id
        );
        let response = self
            .client
            .get(&url)
            .header("dbp-api-key", &self.api_key)
            .send()
            .await?;

        if !response.status().is_success() {
            return Err(AppError::BibleBrainApi(format!(
                "Failed to fetch chapter videos: {}",
                response.status()
            )));
        }

        let videos: Vec<Video> = response.json().await?;
        Ok(videos)
    }

    /// Get all available videos
    pub async fn get_videos(&self) -> Result<Vec<Video>> {
        let url = format!("{}/videos", self.base_url);
        let response = self
            .client
            .get(&url)
            .header("dbp-api-key", &self.api_key)
            .send()
            .await?;

        if !response.status().is_success() {
            return Err(AppError::BibleBrainApi(format!(
                "Failed to fetch videos: {}",
                response.status()
            )));
        }

        let videos: Vec<Video> = response.json().await?;
        Ok(videos)
    }
}

// API Response Types
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Language {
    pub id: String,
    pub name: String,
    pub iso: Option<String>,
    pub iso_name: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Bible {
    pub id: String,
    pub dbl_id: Option<String>,
    pub abbreviation: String,
    pub name: String,
    pub name_local: Option<String>,
    pub description: Option<String>,
    pub description_local: Option<String>,
    pub language: Option<Language>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Book {
    pub id: String,
    pub bible_id: String,
    pub abbreviation: String,
    pub name: String,
    pub name_long: String,
    pub chapters: Option<Vec<Chapter>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Chapter {
    pub id: String,
    pub bible_id: String,
    pub book_id: String,
    pub number: String,
    pub content: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Verse {
    pub id: String,
    pub bible_id: String,
    pub book_id: String,
    pub chapter_id: String,
    pub number: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VerseContent {
    pub id: String,
    pub bible_id: String,
    pub book_id: String,
    pub chapter_id: String,
    pub verse_id: String,
    pub content: String,
    pub reference: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Video {
    pub id: String,
    pub bible_id: Option<String>,
    pub book_id: Option<String>,
    pub chapter_id: Option<String>,
    pub verse_id: Option<String>,
    pub url: Option<String>,
    pub thumbnail_url: Option<String>,
    pub duration: Option<u32>,
    pub title: Option<String>,
    pub description: Option<String>,
    pub language_code: Option<String>,
    pub resolution: Option<String>,
    pub size: Option<u64>,
    #[serde(rename = "type")]
    pub video_type: Option<String>,
}

