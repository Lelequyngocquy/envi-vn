use serde::{Deserialize, Serialize};

#[derive(Debug, Deserialize)]
pub struct LocationQuery {
    pub lat: f64,
    pub lon: f64,
    pub force_refresh: Option<bool>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HourlyWeatherItem {
    pub time: String,
    pub temperature: f64,
    pub relative_humidity: i32,
    pub precipitation_probability: i32,
    pub weather_code: i32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DailyWeatherItem {
    pub date: String,
    pub weather_code: i32,
    pub max_temp: f64,
    pub min_temp: f64,
    pub precipitation_sum: f64,
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
    #[serde(default = "default_pressure")]
    pub surface_pressure: f64,
    #[serde(default)]
    pub hourly: Vec<HourlyWeatherItem>,
    #[serde(default)]
    pub daily: Vec<DailyWeatherItem>,
}

fn default_pressure() -> f64 {
    1013.0
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HourlyAqiItem {
    pub time: String,
    pub us_aqi: i32,
    pub pm25: f64,
    pub pm10: f64,
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
    #[serde(default)]
    pub hourly: Vec<HourlyAqiItem>,
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
    pub id: String,
    pub location_name: String,
    pub province: String,
    pub latitude: f64,
    pub longitude: f64,
    pub brightness_kelvin: f64,
    pub frp: f64,
    pub confidence: f64,
    pub fire_type: String,
    pub is_active_fire: bool,
    pub prone_season: String,
    pub detected_time: String,
    pub description: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HotspotsResponse {
    pub total: usize,
    pub source: String,
    pub cached: bool,
    pub hotspots: Vec<Hotspot>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MapStationItem {
    pub id: String,
    pub name: String,
    pub province: String,
    pub latitude: f64,
    pub longitude: f64,
    pub aqi: i32,
    pub pm25: f64,
    pub pm10: f64,
    pub temperature: Option<f64>,
    pub apparent_temperature: Option<f64>,
    pub weather_code: Option<i32>,
    pub relative_humidity: Option<i32>,
    pub wind_speed: Option<f64>,
    pub precipitation: Option<f64>,
    pub uv_index: Option<f64>,
    pub updated_at: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MapStationsResponse {
    pub total: usize,
    pub cached: bool,
    pub stations: Vec<MapStationItem>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CatalogStation {
    pub id: String,
    pub name: String,
    pub province: String,
    pub latitude: f64,
    pub longitude: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CatalogFloodBlackspot {
    pub id: String,
    pub name: String,
    pub province: String,
    pub latitude: f64,
    pub longitude: f64,
    pub description: String,
    pub average_depth_cm: i32,
    pub trigger_condition: String,
    pub prone_time: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CatalogLocationsResponse {
    pub stations: Vec<CatalogStation>,
    pub flood_blackspots: Vec<CatalogFloodBlackspot>,
}
