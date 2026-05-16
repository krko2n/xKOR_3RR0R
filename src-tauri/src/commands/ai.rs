use std::fs;

#[derive(serde::Serialize)]
pub struct AiResponse {
    pub response: String,
    pub error: Option<String>,
}

fn load_config() -> Result<(String, String), String> {
    let config_paths = vec![
        "/opt/xkor_3rr0r/config/ai-endpoint.json",
        "config/ai-endpoint.json",
    ];
    for path in &config_paths {
        if let Ok(content) = fs::read_to_string(path) {
            if let Ok(config) = serde_json::from_str::<serde_json::Value>(&content) {
                let endpoint = config
                    .get("endpoint")
                    .and_then(|v| v.as_str())
                    .unwrap_or("http://localhost:11434/api/generate");
                let model = config
                    .get("model")
                    .and_then(|v| v.as_str())
                    .unwrap_or("llama3");
                return Ok((endpoint.to_string(), model.to_string()));
            }
        }
    }
    Err("AI config not found".to_string())
}

#[tauri::command]
pub async fn ai_query(prompt: String) -> AiResponse {
    let (endpoint, model) = match load_config() {
        Ok(v) => v,
        Err(e) => {
            return AiResponse {
                response: String::new(),
                error: Some(e),
            }
        }
    };

    let client = reqwest::Client::new();
    let body = serde_json::json!({
        "model": model,
        "prompt": prompt,
        "stream": false,
        "options": {
            "temperature": 0.7
        }
    });

    match client
        .post(&endpoint)
        .json(&body)
        .timeout(std::time::Duration::from_secs(30))
        .send()
        .await
    {
        Ok(resp) => match resp.json::<serde_json::Value>().await {
            Ok(data) => {
                let text = data
                    .get("response")
                    .or_else(|| data.get("message").and_then(|m| m.get("content")))
                    .and_then(|v| v.as_str())
                    .unwrap_or("No response")
                    .to_string();
                AiResponse {
                    response: text,
                    error: None,
                }
            }
            Err(e) => AiResponse {
                response: String::new(),
                error: Some(format!("JSON parse error: {}", e)),
            },
        },
        Err(e) => AiResponse {
            response: String::new(),
            error: Some(format!("AI endpoint unreachable: {}", e)),
        },
    }
}
