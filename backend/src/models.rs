use serde::{Deserialize, Serialize};

#[derive(Debug, Deserialize)]
pub struct LocationQuery {
    pub lat: f64,
    pub lon: f64,
    pub force_refresh: Option<bool>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WeatherData {
    pub temperature: f64,
    pub apparent_temperature: f64,
    pub relative_humidity: i32,
    pub precipitation: f64,
    pub weather_code: i32,
    pub wind_speed: f64,
    pub uv_index: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AirQualityData {
    pub us_aqi: i32,
    pub european_aqi: i32,
    pub pm25: f64,
    pub pm10: f64,
    pub co: f64,
    pub no2: f64,
    pub so2: f64,
    pub o3: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AqiInfo {
    pub aqi: i32,
    pub category: String,
    pub label: String,
    pub description: String,
    pub color_hex: String,
    pub health_advice: String,
    pub outdoor_advice: String,
    pub wear_mask: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HeatIndexInfo {
    pub heat_index: f64,
    pub risk_level: String,
    pub risk_label: String,
    pub color_hex: String,
    pub sunburn_time_advice: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FloodRiskInfo {
    pub risk_level: String,
    pub label: String,
    pub description: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ActivityAdviceInfo {
    pub level: String,
    pub status_label: String,
    pub color_hex: String,
    pub advice_text: String,
    pub morning_status: String,
    pub evening_status: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct QuickPromptEvaluation {
    pub decision: String,
    pub is_safe: bool,
    pub advice: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct QuickPromptsInfo {
    pub running: QuickPromptEvaluation,
    pub ventilation: QuickPromptEvaluation,
    pub children_outdoor: QuickPromptEvaluation,
    pub commute: QuickPromptEvaluation,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EnvironmentalSummary {
    pub latitude: f64,
    pub longitude: f64,
    pub weather: WeatherData,
    pub air_quality: AirQualityData,
    pub aqi_info: AqiInfo,
    pub heat_index_info: HeatIndexInfo,
    pub flood_risk: FloodRiskInfo,
    pub activity_advice: ActivityAdviceInfo,
    pub quick_prompts: QuickPromptsInfo,
    pub ai_system_prompt: String,
    pub cached: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Hotspot {
    pub latitude: f64,
    pub longitude: f64,
    pub brightness: f64,
    pub confidence: String,
    pub acq_date: String,
    pub acq_time: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HotspotsResponse {
    pub total: usize,
    pub source: String,
    pub cached: bool,
    pub hotspots: Vec<Hotspot>,
}
