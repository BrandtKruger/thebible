use crate::error::{AppError, Result};
use serde::{Deserialize, Serialize};
use tracing;

#[derive(Debug, Clone)]
pub struct HelloAOBibleClient {
    client: reqwest::Client,
    base_url: String,
}

impl HelloAOBibleClient {
    pub fn new(base_url: String) -> Self {
        Self {
            client: reqwest::Client::new(),
            base_url,
        }
    }

    /// Get list of available translations
    pub async fn get_translations(&self) -> Result<Vec<Translation>> {
        let url = format!("{}/available_translations.json", self.base_url);
        tracing::debug!("Fetching translations from: {}", url);
        
        let response = self.client.get(&url).send().await.map_err(|e| {
            tracing::error!("Failed to connect to HelloAO API: {}", e);
            AppError::BibleBrainApi(format!("Failed to connect to API: {}", e))
        })?;

        let status = response.status();
        tracing::debug!("API response status: {}", status);

        if !status.is_success() {
            let error_text = response.text().await.unwrap_or_else(|_| "Unknown error".to_string());
            tracing::error!("API error response: {}", error_text);
            return Err(AppError::BibleBrainApi(format!(
                "Failed to fetch translations: {} - {}",
                status, error_text
            )));
        }

        // The API returns either a direct array or an object with a "translations" field
        let json: serde_json::Value = response.json().await.map_err(|e| {
            tracing::error!("Failed to parse translations JSON: {}", e);
            AppError::BibleBrainApi(format!("Failed to parse response: {}", e))
        })?;

        let translations = if json.is_array() {
            // Direct array response
            serde_json::from_value::<Vec<Translation>>(json).map_err(|e| {
                tracing::error!("Failed to deserialize translations array: {}", e);
                AppError::BibleBrainApi(format!("Failed to deserialize response: {}", e))
            })?
        } else if let Some(translations_array) = json.get("translations") {
            // Wrapped in "translations" field
            serde_json::from_value::<Vec<Translation>>(translations_array.clone()).map_err(|e| {
                tracing::error!("Failed to deserialize translations from wrapper: {}", e);
                AppError::BibleBrainApi(format!("Failed to deserialize response: {}", e))
            })?
        } else {
            return Err(AppError::BibleBrainApi(
                "Unexpected API response format".to_string()
            ));
        };
        
        tracing::debug!("Successfully loaded {} translations", translations.len());
        Ok(translations)
    }

    /// Get list of books for a translation
    pub async fn get_books(&self, translation: &str) -> Result<Vec<Book>> {
        let url = format!("{}/{}/books.json", self.base_url, translation);
        tracing::debug!("Fetching books from: {}", url);
        
        let response = self.client.get(&url).send().await.map_err(|e| {
            tracing::error!("Failed to connect to HelloAO API: {}", e);
            AppError::BibleBrainApi(format!("Failed to connect to API: {}", e))
        })?;

        let status = response.status();
        tracing::debug!("API response status: {}", status);

        if !status.is_success() {
            let error_text = response.text().await.unwrap_or_else(|_| "Unknown error".to_string());
            tracing::error!("API error response: {}", error_text);
            return Err(AppError::BibleBrainApi(format!(
                "Failed to fetch books: {} - {}",
                status, error_text
            )));
        }

        // The API returns either a direct array or an object with a "books" field
        let json: serde_json::Value = response.json().await.map_err(|e| {
            tracing::error!("Failed to parse books JSON: {}", e);
            AppError::BibleBrainApi(format!("Failed to parse response: {}", e))
        })?;

        let books = if json.is_array() {
            // Direct array response
            serde_json::from_value::<Vec<Book>>(json).map_err(|e| {
                tracing::error!("Failed to deserialize books array: {}", e);
                AppError::BibleBrainApi(format!("Failed to deserialize response: {}", e))
            })?
        } else if let Some(books_array) = json.get("books") {
            // Wrapped in "books" field
            serde_json::from_value::<Vec<Book>>(books_array.clone()).map_err(|e| {
                tracing::error!("Failed to deserialize books from wrapper: {}", e);
                AppError::BibleBrainApi(format!("Failed to deserialize response: {}", e))
            })?
        } else {
            return Err(AppError::BibleBrainApi(
                "Unexpected API response format for books".to_string()
            ));
        };
        
        tracing::debug!("Successfully loaded {} books", books.len());
        Ok(books)
    }

    /// Get a chapter from a translation
    pub async fn get_chapter(
        &self,
        translation: &str,
        book: &str,
        chapter: u32,
    ) -> Result<Chapter> {
        let url = format!("{}/{}/{}/{}.json", self.base_url, translation, book, chapter);
        tracing::debug!("Fetching chapter from: {}", url);
        
        let response = self.client.get(&url).send().await.map_err(|e| {
            tracing::error!("Failed to connect to HelloAO API: {}", e);
            AppError::BibleBrainApi(format!("Failed to connect to API: {}", e))
        })?;

        let status = response.status();
        tracing::debug!("API response status: {}", status);

        if !status.is_success() {
            let error_text = response.text().await.unwrap_or_else(|_| "Unknown error".to_string());
            tracing::error!("API error response: {}", error_text);
            return Err(AppError::BibleBrainApi(format!(
                "Failed to fetch chapter: {} - {}",
                status, error_text
            )));
        }

        // The API returns a wrapped object with translation, book, and chapter fields
        let json: serde_json::Value = response.json().await.map_err(|e| {
            tracing::error!("Failed to parse chapter JSON: {}", e);
            AppError::BibleBrainApi(format!("Failed to parse response: {}", e))
        })?;

        // Extract the chapter data from the wrapped response
        let chapter_data = if let Some(chapter_obj) = json.get("chapter") {
            // Parse the chapter object
            let chapter_number = chapter_obj.get("number")
                .and_then(|n| n.as_u64())
                .unwrap_or(chapter as u64) as u32;
            
            // Extract verses from content array
            let empty_array: Vec<serde_json::Value> = Vec::new();
            let content = chapter_obj.get("content")
                .and_then(|c| c.as_array())
                .unwrap_or(&empty_array);
            
            let mut verses = Vec::new();
            for item in content {
                if let Some(verse_obj) = item.as_object() {
                    if verse_obj.get("type").and_then(|t| t.as_str()) == Some("verse") {
                        if let (Some(verse_num), Some(content_arr)) = (
                            verse_obj.get("number").and_then(|n| n.as_u64()),
                            verse_obj.get("content").and_then(|c| c.as_array())
                        ) {
                            // Join all content strings for the verse
                            let verse_text: String = content_arr
                                .iter()
                                .filter_map(|v| {
                                    if v.is_string() {
                                        Some(v.as_str().unwrap_or(""))
                                    } else {
                                        None
                                    }
                                })
                                .collect::<Vec<_>>()
                                .join(" ");
                            
                            verses.push(Verse {
                                verse: verse_num as u32,
                                text: verse_text,
                                footnotes: None,
                            });
                        }
                    }
                }
            }
            
            Chapter {
                translation: translation.to_string(),
                book: book.to_string(),
                chapter: chapter_number,
                verses,
                footnotes: None,
            }
        } else {
            return Err(AppError::BibleBrainApi(
                "Unexpected API response format for chapter".to_string()
            ));
        };
        
        tracing::debug!("Successfully loaded chapter {} with {} verses", chapter, chapter_data.verses.len());
        Ok(chapter_data)
    }

    /// Get list of available commentaries
    pub async fn get_commentaries(&self) -> Result<Vec<Commentary>> {
        let url = format!("{}/available_commentaries.json", self.base_url);
        tracing::debug!("Fetching commentaries from: {}", url);
        
        let response = self.client.get(&url).send().await.map_err(|e| {
            tracing::error!("Failed to connect to HelloAO API: {}", e);
            AppError::BibleBrainApi(format!("Failed to connect to API: {}", e))
        })?;

        let status = response.status();
        tracing::debug!("API response status: {}", status);

        if !status.is_success() {
            let error_text = response.text().await.unwrap_or_else(|_| "Unknown error".to_string());
            tracing::error!("API error response: {}", error_text);
            return Err(AppError::BibleBrainApi(format!(
                "Failed to fetch commentaries: {} - {}",
                status, error_text
            )));
        }

        // The API returns either a direct array or an object with a "commentaries" field
        let json: serde_json::Value = response.json().await.map_err(|e| {
            tracing::error!("Failed to parse commentaries JSON: {}", e);
            AppError::BibleBrainApi(format!("Failed to parse response: {}", e))
        })?;

        let commentaries = if json.is_array() {
            // Direct array response
            serde_json::from_value::<Vec<Commentary>>(json).map_err(|e| {
                tracing::error!("Failed to deserialize commentaries array: {}", e);
                AppError::BibleBrainApi(format!("Failed to deserialize response: {}", e))
            })?
        } else if let Some(commentaries_array) = json.get("commentaries") {
            // Wrapped in "commentaries" field
            serde_json::from_value::<Vec<Commentary>>(commentaries_array.clone()).map_err(|e| {
                tracing::error!("Failed to deserialize commentaries from wrapper: {}", e);
                AppError::BibleBrainApi(format!("Failed to deserialize response: {}", e))
            })?
        } else {
            return Err(AppError::BibleBrainApi(
                "Unexpected API response format for commentaries".to_string()
            ));
        };
        
        tracing::debug!("Successfully loaded {} commentaries", commentaries.len());
        Ok(commentaries)
    }

    /// Get commentary for a specific chapter
    pub async fn get_commentary(
        &self,
        commentary_id: &str,
        book: &str,
        chapter: u32,
    ) -> Result<CommentaryChapter> {
        let url = format!("{}/c/{}/{}/{}.json", self.base_url, commentary_id, book, chapter);
        tracing::debug!("Fetching commentary from: {}", url);
        
        let response = self.client.get(&url).send().await.map_err(|e| {
            tracing::error!("Failed to connect to HelloAO API: {}", e);
            AppError::BibleBrainApi(format!("Failed to connect to API: {}", e))
        })?;

        let status = response.status();
        tracing::debug!("API response status: {}", status);

        if !status.is_success() {
            let error_text = response.text().await.unwrap_or_else(|_| "Unknown error".to_string());
            tracing::error!("API error response: {}", error_text);
            return Err(AppError::BibleBrainApi(format!(
                "Failed to fetch commentary: {} - {}",
                status, error_text
            )));
        }

        // The API returns a wrapped object with commentary, book, and chapter fields
        let json: serde_json::Value = response.json().await.map_err(|e| {
            tracing::error!("Failed to parse commentary JSON: {}", e);
            AppError::BibleBrainApi(format!("Failed to parse response: {}", e))
        })?;

        // Extract the chapter data from the wrapped response
        let commentary_chapter = if let Some(chapter_obj) = json.get("chapter") {
            let chapter_number = chapter_obj.get("number")
                .and_then(|n| n.as_u64())
                .unwrap_or(chapter as u64) as u32;
            
            // Extract commentary content from content array
            let empty_array: Vec<serde_json::Value> = Vec::new();
            let content = chapter_obj.get("content")
                .and_then(|c| c.as_array())
                .unwrap_or(&empty_array);
            
            let mut verses = Vec::new();
            for item in content {
                if let Some(verse_obj) = item.as_object() {
                    if verse_obj.get("type").and_then(|t| t.as_str()) == Some("verse") {
                        if let (Some(verse_num), Some(content_arr)) = (
                            verse_obj.get("number").and_then(|n| n.as_u64()),
                            verse_obj.get("content").and_then(|c| c.as_array())
                        ) {
                            // Join all content strings for the verse commentary
                            let verse_text: String = content_arr
                                .iter()
                                .filter_map(|v| {
                                    if v.is_string() {
                                        Some(v.as_str().unwrap_or(""))
                                    } else {
                                        None
                                    }
                                })
                                .collect::<Vec<_>>()
                                .join(" ");
                            
                            verses.push(CommentaryVerse {
                                verse: verse_num as u32,
                                content: verse_text,
                            });
                        }
                    }
                }
            }
            
            CommentaryChapter {
                commentary_id: commentary_id.to_string(),
                book: book.to_string(),
                chapter: chapter_number,
                verses,
            }
        } else {
            return Err(AppError::BibleBrainApi(
                "Unexpected API response format for commentary".to_string()
            ));
        };
        
        tracing::debug!("Successfully loaded commentary chapter {} with {} verses", chapter, commentary_chapter.verses.len());
        Ok(commentary_chapter)
    }
}

// API Response Types
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Translation {
    pub id: String,
    pub name: String,
    #[serde(default)]
    pub language: Option<String>,
    #[serde(default, rename = "englishName")]
    pub english_name: Option<String>,
    #[serde(default, rename = "languageName")]
    pub language_name: Option<String>,
    #[serde(default, rename = "languageEnglishName")]
    pub language_english_name: Option<String>,
    #[serde(default, rename = "shortName")]
    pub short_name: Option<String>,
    #[serde(default)]
    pub description: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Book {
    pub id: String,
    pub name: String,
    #[serde(default, rename = "commonName")]
    pub common_name: Option<String>,
    #[serde(default)]
    pub order: Option<u32>,
    #[serde(default, rename = "numberOfChapters")]
    pub number_of_chapters: Option<u32>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Chapter {
    pub translation: String,
    pub book: String,
    pub chapter: u32,
    pub verses: Vec<Verse>,
    #[serde(default)]
    pub footnotes: Option<Vec<Footnote>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Verse {
    pub verse: u32,
    pub text: String,
    #[serde(default)]
    pub footnotes: Option<Vec<String>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Footnote {
    pub id: String,
    pub text: String,
}

// Commentary Types
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Commentary {
    pub id: String,
    pub name: String,
    #[serde(default, rename = "englishName")]
    pub english_name: Option<String>,
    #[serde(default)]
    pub language: Option<String>,
    #[serde(default, rename = "languageEnglishName")]
    pub language_english_name: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CommentaryChapter {
    pub commentary_id: String,
    pub book: String,
    pub chapter: u32,
    pub verses: Vec<CommentaryVerse>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CommentaryVerse {
    pub verse: u32,
    pub content: String,
}

