use serde::Deserialize;

#[derive(Debug, Clone, Deserialize)]
pub struct Config {
    pub server: ServerConfig,
    pub bible_api: BibleApiConfig,
}

#[derive(Debug, Clone, Deserialize)]
pub struct ServerConfig {
    pub host: String,
    pub port: u16,
}

#[derive(Debug, Clone, Deserialize)]
pub struct BibleApiConfig {
    pub base_url: String,
}

impl Config {
    pub fn from_env() -> Result<Self, config::ConfigError> {
        let mut builder = config::Config::builder()
            .set_default("server.host", "0.0.0.0")?
            .set_default("server.port", 3000)?
            .set_default("bible_api.base_url", "https://bible.helloao.org/api")?;

        if let Ok(host) = std::env::var("HOST") {
            builder = builder.set_override("server.host", host)?;
        }

        if let Ok(port) = std::env::var("PORT") {
            let port: u16 = port.parse().map_err(|_| {
                config::ConfigError::Message("Invalid PORT value".to_string())
            })?;
            builder = builder.set_override("server.port", port)?;
        }

        if let Ok(base_url) = std::env::var("BIBLE_API_BASE_URL") {
            builder = builder.set_override("bible_api.base_url", base_url)?;
        }

        builder.build()?.try_deserialize()
    }
}

