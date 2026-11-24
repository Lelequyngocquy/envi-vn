use crate::calculator::{
    build_system_prompt, calculate_activity_advice, calculate_aqi_info, calculate_flood_risk,
    calculate_heat_index, evaluate_quick_prompts,
};
use crate::models::{
    AirQualityData, EnvironmentalSummary, Hotspot, HotspotsResponse, WeatherData,
};
use redis::AsyncCommands;
use std::time::Duration;

pub struct ServiceClients {
    pub http_client: reqwest::Client,
    pub redis_client: Option<redis::Client>,
    pub nasa_api_key: String,
}

impl ServiceClients {
    pub async fn get_cached_string(&self, key: &str) -> Option<String> {
        if let Some(client) = &self.redis_client {
            if let Ok(mut con) = client.get_multiplexed_async_connection().await {
                if let Ok(val) = con.get::<&str, Option<String>>(key).await {
                    return val;
                }
            }
        }
        None
    }

    pub async fn set_cached_string(&self, key: &str, value: &str, ttl_secs: u64) {
        if let Some(client) = &self.redis_client {
            if let Ok(mut con) = client.get_multiplexed_async_connection().await {
                let _: Result<(), _> = con.set_ex(key, value, ttl_secs).await;
            }
        }
    }

    pub async fn fetch_weather(&self, lat: f64, lon: f64, force: bool) -> Result<(WeatherData, bool), String> {
        let cache_key = format!("envivn:weather:{:.2}:{:.2}", lat, lon);
        if !force {
            if let Some(cached_json) = self.get_cached_string(&cache_key).await {
                if let Ok(data) = serde_json::from_str::<WeatherData>(&cached_json) {
                    return Ok((data, true));
                }
            }
        }
        let url = format!(
            "https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lon}&current=temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m,uv_index&timezone=auto"
        );
        let resp = self.http_client.get(&url).timeout(Duration::from_secs(8)).send().await.map_err(|e| e.to_string())?;
        let json_val = resp.json::<serde_json::Value>().await.map_err(|e| e.to_string())?;
        let current = json_val.get("current").ok_or_else(|| "Missing current in weather response".to_string())?;
        let weather = WeatherData {
            temperature: current.get("temperature_2m").and_then(|v| v.as_f64()).unwrap_or(27.0),
            apparent_temperature: current.get("apparent_temperature").and_then(|v| v.as_f64()).unwrap_or(29.0),
            relative_humidity: current.get("relative_humidity_2m").and_then(|v| v.as_i64()).unwrap_or(70) as i32,
            precipitation: current.get("precipitation").and_then(|v| v.as_f64()).unwrap_or(0.0),
            weather_code: current.get("weather_code").and_then(|v| v.as_i64()).unwrap_or(0) as i32,
            wind_speed: current.get("wind_speed_10m").and_then(|v| v.as_f64()).unwrap_or(10.0),
            uv_index: current.get("uv_index").and_then(|v| v.as_f64()).unwrap_or(3.0),
        };
        if let Ok(serialized) = serde_json::to_string(&weather) {
            self.set_cached_string(&cache_key, &serialized, 600).await;
        }
        Ok((weather, false))
    }

    pub async fn fetch_air_quality(&self, lat: f64, lon: f64, force: bool) -> Result<(AirQualityData, bool), String> {
        let cache_key = format!("envivn:airquality:{:.2}:{:.2}", lat, lon);
        if !force {
            if let Some(cached_json) = self.get_cached_string(&cache_key).await {
                if let Ok(data) = serde_json::from_str::<AirQualityData>(&cached_json) {
                    return Ok((data, true));
                }
            }
        }
        let url = format!(
            "https://air-quality-api.open-meteo.com/v1/air-quality?latitude={lat}&longitude={lon}&current=european_aqi,us_aqi,pm10,pm2_5,carbon_monoxide,nitrogen_dioxide,sulphur_dioxide,ozone&timezone=auto"
        );
        let resp = self.http_client.get(&url).timeout(Duration::from_secs(8)).send().await.map_err(|e| e.to_string())?;
        let json_val = resp.json::<serde_json::Value>().await.map_err(|e| e.to_string())?;
        let current = json_val.get("current").ok_or_else(|| "Missing current in air quality response".to_string())?;
        let air_quality = AirQualityData {
            us_aqi: current.get("us_aqi").and_then(|v| v.as_i64()).unwrap_or(45) as i32,
            european_aqi: current.get("european_aqi").and_then(|v| v.as_i64()).unwrap_or(35) as i32,
            pm25: current.get("pm2_5").and_then(|v| v.as_f64()).unwrap_or(12.0),
            pm10: current.get("pm10").and_then(|v| v.as_f64()).unwrap_or(22.0),
            co: current.get("carbon_monoxide").and_then(|v| v.as_f64()).unwrap_or(200.0),
            no2: current.get("nitrogen_dioxide").and_then(|v| v.as_f64()).unwrap_or(15.0),
            so2: current.get("sulphur_dioxide").and_then(|v| v.as_f64()).unwrap_or(5.0),
            o3: current.get("ozone").and_then(|v| v.as_f64()).unwrap_or(30.0),
        };
        if let Ok(serialized) = serde_json::to_string(&air_quality) {
            self.set_cached_string(&cache_key, &serialized, 600).await;
        }
        Ok((air_quality, false))
    }

    pub async fn get_environmental_summary(&self, lat: f64, lon: f64, force: bool) -> Result<EnvironmentalSummary, String> {
        let (weather, w_cached) = self.fetch_weather(lat, lon, force).await?;
        let (air_quality, a_cached) = self.fetch_air_quality(lat, lon, force).await?;
        let aqi_val = air_quality.us_aqi.max(air_quality.european_aqi).max(0);
        let aqi_info = calculate_aqi_info(aqi_val);
        let heat_index_info = calculate_heat_index(weather.temperature, weather.relative_humidity, weather.uv_index);
        let flood_risk = calculate_flood_risk(weather.precipitation);
        let activity_advice = calculate_activity_advice(aqi_val, weather.uv_index, 20, weather.precipitation);
        let quick_prompts = evaluate_quick_prompts(aqi_val, air_quality.pm25, weather.temperature, weather.uv_index, weather.precipitation, weather.weather_code);
        let ai_system_prompt = build_system_prompt(lat, lon, &weather, &air_quality);
        Ok(EnvironmentalSummary {
            latitude: lat,
            longitude: lon,
            weather,
            air_quality,
            aqi_info,
            heat_index_info,
            flood_risk,
            activity_advice,
            quick_prompts,
            ai_system_prompt,
            cached: w_cached && a_cached,
        })
    }

    pub async fn fetch_hotspots(&self, force: bool) -> Result<HotspotsResponse, String> {
        let cache_key = "envivn:hotspots:vietnam";
        if !force {
            if let Some(cached_json) = self.get_cached_string(cache_key).await {
                if let Ok(data) = serde_json::from_str::<HotspotsResponse>(&cached_json) {
                    return Ok(data);
                }
            }
        }
        let api_key = &self.nasa_api_key;
        if api_key.is_empty() {
            return Err("NASA FIRMS API key not configured".into());
        }
        let url = format!(
            "https://firms.modaps.eosdis.nasa.gov/api/area/csv/{api_key}/VIIRS_NOAA20_NRT/102.14,8.18,109.46,23.39/1"
        );
        let resp = self.http_client.get(&url).timeout(Duration::from_secs(12)).send().await.map_err(|_| "NASA FIRMS upstream connection failed".to_string())?;
        let status = resp.status();
        if !status.is_success() {
            return Err(format!("NASA FIRMS upstream status: {status}"));
        }
        let csv_text = resp.text().await.map_err(|e| e.to_string())?;
        let mut hotspots = Vec::new();
        for line in csv_text.lines().skip(1) {
            let cols: Vec<&str> = line.split(',').collect();
            if cols.len() >= 10 {
                let lat = match cols[0].parse::<f64>() { Ok(v) => v, Err(_) => continue };
                let lon = match cols[1].parse::<f64>() { Ok(v) => v, Err(_) => continue };
                let brightness = cols[2].parse::<f64>().unwrap_or(0.0);
                let confidence = cols[9].to_string();
                let acq_date = cols[5].to_string();
                let acq_time = cols[6].to_string();
                hotspots.push(Hotspot {
                    latitude: lat,
                    longitude: lon,
                    brightness,
                    confidence,
                    acq_date,
                    acq_time,
                });
            }
        }
        let res = HotspotsResponse {
            total: hotspots.len(),
            source: "VIIRS_NOAA20_NRT".into(),
            cached: false,
            hotspots,
        };
        let mut cached_copy = res.clone();
        cached_copy.cached = true;
        if let Ok(serialized) = serde_json::to_string(&cached_copy) {
            self.set_cached_string(cache_key, &serialized, 900).await;
        }
        Ok(res)
    }
}
