# Bible Brain API Video Support

## Yes, Bible Brain API Has Videos! 🎥

According to the Bible Brain API documentation, video content is available in various languages. However, there are some important considerations:

## Current Status

**Your current implementation** only handles:
- ✅ Text content (verses, chapters, books)
- ✅ Languages and Bibles
- ❌ Video content (not yet implemented)

## Video Content Availability

The Bible Brain API provides:
- **Video resources** in multiple languages
- **Video URLs** for Bible content
- **Signed URLs** may be required (some developers report 422 errors with unsigned URLs)

## Adding Video Support

To add video support to your application, you would need to:

### 1. Check Available Content Types

The API may have endpoints like:
- `/videos` - List available videos
- `/bibles/{bible_id}/videos` - Videos for a specific Bible
- `/books/{book_id}/videos` - Videos for a specific book

### 2. Update API Client

Add video-related methods to `src/api/bible_brain.rs`:

```rust
/// Get videos for a Bible
pub async fn get_videos(&self, bible_id: &str) -> Result<Vec<Video>> {
    // Implementation
}

/// Get video URL (may require signed URLs)
pub async fn get_video_url(&self, video_id: &str) -> Result<VideoUrl> {
    // Implementation
}
```

### 3. Add Video Types

```rust
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Video {
    pub id: String,
    pub bible_id: String,
    pub book_id: Option<String>,
    pub chapter_id: Option<String>,
    pub url: Option<String>,
    pub thumbnail_url: Option<String>,
    pub duration: Option<u32>,
    // ... other fields
}
```

### 4. Update Frontend

Add video player support to `static/index.html`:
- Video player component
- Thumbnail display
- Play/pause controls
- Integration with verse/chapter reading

## Next Steps

1. **Check API Documentation**: Visit https://www.faithcomesbyhearing.com/bible-brain/api-reference
2. **Review OpenAPI Spec**: Check the OpenAPI configuration at https://4.dbt.io/open-api-4.json
3. **Test Video Endpoints**: Use Postman or curl to test video endpoints
4. **Implement Video Support**: Add video methods to your API client

## Resources

- **Official API Reference**: https://www.faithcomesbyhearing.com/bible-brain/api-reference
- **OpenAPI Spec**: https://4.dbt.io/open-api-4.json
- **Postman Collection**: Available from Bible Brain API documentation

## Important Notes

⚠️ **Signed URLs**: Some video URLs may require signing/authentication
⚠️ **Rate Limits**: Video content may have different rate limits
⚠️ **File Sizes**: Videos are larger than text, consider caching strategies

## Would You Like Video Support Added?

If you'd like me to add video support to your application, I can:
1. Research the exact video endpoints from the API
2. Add video methods to your Rust API client
3. Create video player components in your frontend
4. Integrate videos with your existing Bible reader

Let me know if you'd like me to implement video support!

