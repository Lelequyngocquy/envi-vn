mod calculator;
mod clients;
mod models;

use axum::{
    extract::{Query, State},
    http::StatusCode,
    response::{
        sse::{Event, KeepAlive, Sse},
        IntoResponse, Response,
    },
    routing::{get, post},
    Json, Router,
};
use clients::ServiceClients;
use futures_util::StreamExt;
use models::{
    AirQualityData, EnvironmentalSummary, HotspotsResponse, LocationQuery, WeatherData,
};
use serde::{Deserialize, Serialize};
use std::{convert::Infallible, net::SocketAddr, sync::Arc, time::Duration};
use tokio_stream::wrappers::ReceiverStream;
use tower_http::cors::{Any, CorsLayer};
use tracing::{error, info};

#[derive(Clone)]
pub struct AppState {
    pub clients: Arc<ServiceClients>,
    pub ollama_base_url: String,
    pub ai_model_name: String,
}

#[derive(Serialize)]
pub struct HealthResponse {
    pub status: &'static str,
    pub service: &'static str,
    pub redis: &'static str,
    pub ollama: &'static str,
    pub model: String,
}

#[derive(Debug, Deserialize)]
pub struct ChatRequest {
    pub message: Option<String>,
    pub messages: Option<Vec<ChatMessage>>,
    pub system: Option<String>,
    pub lat: Option<f64>,
    pub lon: Option<f64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChatMessage {
    pub role: String,
    pub content: String,
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

#[derive(Debug, Deserialize)]
pub struct ForceQuery {
    pub force: Option<bool>,
}

async fn health_check(State(state): State<Arc<AppState>>) -> Json<HealthResponse> {
    let redis_status = match &state.clients.redis_client {
        Some(client) => match client.get_multiplexed_async_connection().await {
            Ok(mut con) => match redis::cmd("PING").query_async::<String>(&mut con).await {
                Ok(_) => "connected",
                Err(_) => "disconnected",
            },
            Err(_) => "disconnected",
        },
        None => "disconnected",
    };
    let ollama_status = match state.clients.http_client.get(format!("{}/api/tags", state.ollama_base_url)).timeout(Duration::from_millis(1500)).send().await {
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

async fn get_weather_handler(
    State(state): State<Arc<AppState>>,
    Query(q): Query<LocationQuery>,
) -> Result<Json<WeatherData>, (StatusCode, String)> {
    let force = q.force_refresh.unwrap_or(false);
    match state.clients.fetch_weather(q.lat, q.lon, force).await {
        Ok((data, _)) => Ok(Json(data)),
        Err(err) => Err((StatusCode::BAD_GATEWAY, err)),
    }
}

async fn get_air_quality_handler(
    State(state): State<Arc<AppState>>,
    Query(q): Query<LocationQuery>,
) -> Result<Json<AirQualityData>, (StatusCode, String)> {
    let force = q.force_refresh.unwrap_or(false);
    match state.clients.fetch_air_quality(q.lat, q.lon, force).await {
        Ok((data, _)) => Ok(Json(data)),
        Err(err) => Err((StatusCode::BAD_GATEWAY, err)),
    }
}

async fn get_environmental_summary_handler(
    State(state): State<Arc<AppState>>,
    Query(q): Query<LocationQuery>,
) -> Result<Json<EnvironmentalSummary>, (StatusCode, String)> {
    let force = q.force_refresh.unwrap_or(false);
    match state.clients.get_environmental_summary(q.lat, q.lon, force).await {
        Ok(summary) => Ok(Json(summary)),
        Err(err) => Err((StatusCode::BAD_GATEWAY, err)),
    }
}

async fn get_hotspots_handler(
    State(state): State<Arc<AppState>>,
    Query(q): Query<ForceQuery>,
) -> Result<Json<HotspotsResponse>, (StatusCode, String)> {
    let force = q.force.unwrap_or(false);
    match state.clients.fetch_hotspots(force).await {
        Ok(res) => Ok(Json(res)),
        Err(err) => Err((StatusCode::BAD_GATEWAY, err)),
    }
}

async fn chat_advisor(
    State(state): State<Arc<AppState>>,
    Json(payload): Json<ChatRequest>,
) -> Response {
    let has_user_content = payload.messages.as_ref().map(|m| !m.is_empty()).unwrap_or(false) || payload.message.as_ref().map(|m| !m.trim().is_empty()).unwrap_or(false);
    if !has_user_content {
        return (StatusCode::BAD_REQUEST, "Message content is required").into_response();
    }
    let mut messages = Vec::new();
    let system_prompt = match payload.system {
        Some(sys) => format!("{}\n{}", sys, calculator::DOMAIN_GUARDRAIL_RULES),
        None => if let (Some(lat), Some(lon)) = (payload.lat, payload.lon) {
            match state.clients.get_environmental_summary(lat, lon, false).await {
                Ok(summary) => summary.ai_system_prompt,
                Err(_) => calculator::build_default_guardrail_prompt(),
            }
        } else {
            calculator::build_default_guardrail_prompt()
        },
    };
    messages.push(ChatMessage { role: "system".into(), content: system_prompt });
    if let Some(history) = payload.messages {
        messages.extend(history);
    } else if let Some(msg) = payload.message {
        messages.push(ChatMessage { role: "user".into(), content: msg });
    }
    let ollama_req = OllamaChatPayload {
        model: &state.ai_model_name,
        messages,
        stream: true,
    };
    let ollama_url = format!("{}/api/chat", state.ollama_base_url);
    let ollama_resp = match state.clients.http_client.post(&ollama_url).json(&ollama_req).send().await {
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

pub fn create_app(state: Arc<AppState>) -> Router {
    let cors = CorsLayer::new().allow_origin(Any).allow_methods(Any).allow_headers(Any);
    Router::new()
        .route("/api/v1/health", get(health_check))
        .route("/api/v1/weather", get(get_weather_handler))
        .route("/api/v1/air-quality", get(get_air_quality_handler))
        .route("/api/v1/environmental-summary", get(get_environmental_summary_handler))
        .route("/api/v1/hotspots", get(get_hotspots_handler))
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
    let nasa_api_key = std::env::var("NASA_FIRMS_API_KEY").unwrap_or_else(|_| "aaa04b831a37f75677607b924c5df1de".into());
    let redis_client = if redis_host.is_empty() || redis_host.eq_ignore_ascii_case("disabled") || redis_host.eq_ignore_ascii_case("none") {
        None
    } else {
        redis::Client::open(format!("redis://{redis_host}:{redis_port}")).ok()
    };
    let http_client = reqwest::Client::builder().connect_timeout(Duration::from_secs(10)).timeout(Duration::from_secs(300)).build().unwrap_or_default();
    let clients = Arc::new(ServiceClients {
        http_client,
        redis_client,
        nasa_api_key,
    });
    let state = Arc::new(AppState {
        clients,
        ollama_base_url,
        ai_model_name,
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

    fn get_test_app() -> Router {
        let clients = Arc::new(ServiceClients {
            http_client: reqwest::Client::new(),
            redis_client: None,
            nasa_api_key: "".into(),
        });
        let state = Arc::new(AppState {
            clients,
            ollama_base_url: "http://127.0.0.1:19999".into(),
            ai_model_name: "qwen2.5:3b".into(),
        });
        create_app(state)
    }

    #[tokio::test]
    async fn test_health_check_endpoint() {
        let app = get_test_app();
        let request = Request::builder().uri("/api/v1/health").body(Body::empty()).unwrap();
        let response = app.oneshot(request).await.unwrap();
        assert_eq!(response.status(), StatusCode::OK);
        let body_bytes = response.into_body().collect().await.unwrap().to_bytes();
        let body: serde_json::Value = serde_json::from_slice(&body_bytes).unwrap();
        assert_eq!(body["status"], "ok");
        assert_eq!(body["service"], "envivn-backend");
    }

    #[tokio::test]
    async fn test_chat_advisor_empty_message() {
        let app = get_test_app();
        let request = Request::builder().method("POST").uri("/api/v1/advisor/chat").header("content-type", "application/json").body(Body::from(r#"{}"#)).unwrap();
        let response = app.oneshot(request).await.unwrap();
        assert_eq!(response.status(), StatusCode::BAD_REQUEST);
    }

    #[test]
    fn test_calculator_aqi_bounds() {
        let good = calculator::calculate_aqi_info(25);
        assert_eq!(good.category, "good");
        assert_eq!(good.wear_mask, false);
        let hazardous = calculator::calculate_aqi_info(350);
        assert_eq!(hazardous.category, "hazardous");
        assert_eq!(hazardous.wear_mask, true);
    }

    #[test]
    fn test_calculator_heat_index() {
        let hi = calculator::calculate_heat_index(35.0, 80, 8.5);
        assert!(hi.heat_index > 35.0);
        assert_eq!(hi.risk_level, "extreme");
    }

    #[test]
    fn test_calculator_flood_risk() {
        let low = calculator::calculate_flood_risk(1.0);
        assert_eq!(low.risk_level, "low");
        let severe = calculator::calculate_flood_risk(55.0);
        assert_eq!(severe.risk_level, "very_high");
    }
}
