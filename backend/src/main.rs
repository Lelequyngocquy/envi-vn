use axum::{
    extract::State,
    http::StatusCode,
    response::{
        sse::{Event, KeepAlive, Sse},
        IntoResponse, Response,
    },
    routing::{get, post},
    Json, Router,
};
use futures_util::StreamExt;
use serde::{Deserialize, Serialize};
use std::{convert::Infallible, net::SocketAddr, sync::Arc, time::Duration};
use tokio_stream::wrappers::ReceiverStream;
use tower_http::cors::{Any, CorsLayer};
use tracing::{error, info};

#[derive(Clone)]
struct AppState {
    redis_client: Option<redis::Client>,
    ollama_base_url: String,
    ai_model_name: String,
    http_client: reqwest::Client,
}

#[derive(Serialize)]
struct HealthResponse {
    status: &'static str,
    service: &'static str,
    redis: &'static str,
    ollama: &'static str,
    model: String,
}

#[derive(Debug, Deserialize)]
struct ChatRequest {
    message: Option<String>,
    messages: Option<Vec<ChatMessage>>,
    system: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct ChatMessage {
    role: String,
    content: String,
}

#[derive(Serialize)]
struct OllamaChatPayload<'a> {
    model: &'a str,
    messages: Vec<ChatMessage>,
    stream: bool,
}

#[derive(Deserialize)]
struct OllamaChunkMessage {
    content: Option<String>,
}

#[derive(Deserialize)]
struct OllamaChunk {
    message: Option<OllamaChunkMessage>,
    done: Option<bool>,
}

#[derive(Serialize)]
struct StreamDeltaEvent {
    content: String,
    done: bool,
}

async fn health_check(State(state): State<Arc<AppState>>) -> Json<HealthResponse> {
    let redis_status = match &state.redis_client {
        Some(client) => match client.get_multiplexed_async_connection().await {
            Ok(mut con) => match redis::cmd("PING").query_async::<String>(&mut con).await {
                Ok(_) => "connected",
                Err(_) => "disconnected",
            },
            Err(_) => "disconnected",
        },
        None => "disconnected",
    };
    let ollama_status = match state.http_client.get(format!("{}/api/tags", state.ollama_base_url)).timeout(Duration::from_millis(1500)).send().await {
        Ok(res) if res.status().is_success() => "connected",
        _ => "disconnected",
    };
    Json(HealthResponse {
        status: "ok",
        service: "envivn-backend",
        redis: redis_status,
        ollama: ollama_status,
        model: state.ai_model_name.clone(),
    })
}

async fn chat_advisor(
    State(state): State<Arc<AppState>>,
    Json(payload): Json<ChatRequest>,
) -> Response {
    let mut messages = Vec::new();
    if let Some(sys) = payload.system {
        messages.push(ChatMessage { role: "system".into(), content: sys });
    }
    if let Some(history) = payload.messages {
        messages.extend(history);
    } else if let Some(msg) = payload.message {
        messages.push(ChatMessage { role: "user".into(), content: msg });
    }
    if messages.is_empty() {
        return (StatusCode::BAD_REQUEST, "Message content is required").into_response();
    }
    let ollama_req = OllamaChatPayload {
        model: &state.ai_model_name,
        messages,
        stream: true,
    };
    let ollama_url = format!("{}/api/chat", state.ollama_base_url);
    let ollama_resp = match state.http_client.post(&ollama_url).json(&ollama_req).send().await {
        Ok(resp) if resp.status().is_success() => resp,
        Ok(resp) => {
            let status = resp.status();
            let err_txt = resp.text().await.unwrap_or_default();
            error!("Ollama responded with error {status}: {err_txt}");
            return (StatusCode::BAD_GATEWAY, format!("Ollama upstream error: {err_txt}")).into_response();
        }
        Err(err) => {
            error!("Failed to connect to Ollama: {err}");
            return (StatusCode::SERVICE_UNAVAILABLE, format!("Ollama service unavailable: {err}")).into_response();
        }
    };
    let (tx, rx) = tokio::sync::mpsc::channel::<Result<Event, Infallible>>(64);
    tokio::spawn(async move {
        let mut byte_stream = ollama_resp.bytes_stream();
        let mut buffer = String::new();
        while let Some(chunk_result) = byte_stream.next().await {
            let chunk = match chunk_result {
                Ok(bytes) => bytes,
                Err(_) => break,
            };
            buffer.push_str(&String::from_utf8_lossy(&chunk));
            while let Some(newline_pos) = buffer.find('\n') {
                let line = buffer[..newline_pos].trim().to_string();
                buffer.drain(..=newline_pos);
                if line.is_empty() {
                    continue;
                }
                if let Ok(parsed) = serde_json::from_str::<OllamaChunk>(&line) {
                    let content = parsed.message.and_then(|m| m.content).unwrap_or_default();
                    let done = parsed.done.unwrap_or(false);
                    let delta = StreamDeltaEvent { content, done };
                    if let Ok(json_data) = serde_json::to_string(&delta) {
                        if tx.send(Ok(Event::default().data(json_data))).await.is_err() {
                            return;
                        }
                    }
                    if done {
                        let _ = tx.send(Ok(Event::default().data("[DONE]"))).await;
                        return;
                    }
                }
            }
        }
        let _ = tx.send(Ok(Event::default().data("[DONE]"))).await;
    });
    let sse_stream = ReceiverStream::new(rx);
    Sse::new(sse_stream).keep_alive(KeepAlive::default()).into_response()
}

fn create_app(state: Arc<AppState>) -> Router {
    let cors = CorsLayer::new().allow_origin(Any).allow_methods(Any).allow_headers(Any);
    Router::new()
        .route("/api/v1/health", get(health_check))
        .route("/api/v1/advisor/chat", post(chat_advisor))
        .layer(cors)
        .with_state(state)
}

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt().with_env_filter(tracing_subscriber::EnvFilter::from_default_env()).init();
    let port = std::env::var("PORT").unwrap_or_else(|_| "8080".into()).parse::<u16>().unwrap_or(8080);
    let redis_host = std::env::var("REDIS_HOST").unwrap_or_else(|_| "localhost".into());
    let redis_port = std::env::var("REDIS_PORT").unwrap_or_else(|_| "6379".into());
    let ollama_base_url = std::env::var("OLLAMA_BASE_URL").unwrap_or_else(|_| "http://localhost:11434".into());
    let ai_model_name = std::env::var("AI_MODEL_NAME").unwrap_or_else(|_| "qwen2.5:3b".into());
    let redis_client = redis::Client::open(format!("redis://{redis_host}:{redis_port}")).ok();
    let http_client = reqwest::Client::builder().timeout(Duration::from_secs(60)).build().unwrap_or_default();
    let state = Arc::new(AppState {
        redis_client,
        ollama_base_url,
        ai_model_name,
        http_client,
    });
    let app = create_app(state);
    let addr = SocketAddr::from(([0, 0, 0, 0], port));
    info!("EnviVN backend running on http://{addr}");
    let listener = tokio::net::TcpListener::bind(addr).await.expect("Failed to bind port");
    axum::serve(listener, app).await.expect("Server failed");
}

#[cfg(test)]
mod tests {
    use super::*;
    use axum::body::Body;
    use axum::http::Request;
    use http_body_util::BodyExt;
    use tower::ServiceExt;

    #[tokio::test]
    async fn test_health_check_endpoint() {
        let state = Arc::new(AppState {
            redis_client: None,
            ollama_base_url: "http://127.0.0.1:19999".into(),
            ai_model_name: "qwen2.5:3b".into(),
            http_client: reqwest::Client::new(),
        });
        let app = create_app(state);
        let request = Request::builder().uri("/api/v1/health").body(Body::empty()).unwrap();
        let response = app.oneshot(request).await.unwrap();
        assert_eq!(response.status(), StatusCode::OK);
        let body_bytes = response.into_body().collect().await.unwrap().to_bytes();
        let body: serde_json::Value = serde_json::from_slice(&body_bytes).unwrap();
        assert_eq!(body["status"], "ok");
        assert_eq!(body["service"], "envivn-backend");
        assert_eq!(body["redis"], "disconnected");
        assert_eq!(body["ollama"], "disconnected");
    }

    #[tokio::test]
    async fn test_chat_advisor_empty_message() {
        let state = Arc::new(AppState {
            redis_client: None,
            ollama_base_url: "http://127.0.0.1:19999".into(),
            ai_model_name: "qwen2.5:3b".into(),
            http_client: reqwest::Client::new(),
        });
        let app = create_app(state);
        let request = Request::builder().method("POST").uri("/api/v1/advisor/chat").header("content-type", "application/json").body(Body::from(r#"{}"#)).unwrap();
        let response = app.oneshot(request).await.unwrap();
        assert_eq!(response.status(), StatusCode::BAD_REQUEST);
    }
}
