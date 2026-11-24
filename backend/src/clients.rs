use crate::calculator::{
    build_system_prompt, calculate_activity_advice, calculate_aqi_info, calculate_flood_risk,
    calculate_heat_index, evaluate_quick_prompts,
};
use crate::models::{
    AirQualityData, CatalogFloodBlackspot, CatalogLocationsResponse, CatalogStation,
    DailyWeatherItem, EnvironmentalSummary, Hotspot, HotspotsResponse, HourlyAqiItem,
    HourlyWeatherItem, MapStationItem, MapStationsResponse, WeatherData,
};
use chrono::{Duration as ChronoDuration, Local, NaiveDate, NaiveDateTime, NaiveTime};
use redis::AsyncCommands;
use std::time::Duration;

// Vietnam bounding box including Hoang Sa & Truong Sa archipelagos.
const VIETNAM_FIRMS_BBOX: &str = "102.1,8.1,114.6,23.5";

struct ProvinceCoord {
    name: &'static str,
    lat: f64,
    lon: f64,
}

const VIETNAM_PROVINCE_COORDS: &[ProvinceCoord] = &[
    ProvinceCoord { name: "Hà Nội", lat: 21.0285, lon: 105.8542 },
    ProvinceCoord { name: "Hà Giang", lat: 22.8026, lon: 104.9784 },
    ProvinceCoord { name: "Cao Bằng", lat: 22.6667, lon: 106.2500 },
    ProvinceCoord { name: "Bắc Kạn", lat: 22.1470, lon: 105.8348 },
    ProvinceCoord { name: "Tuyên Quang", lat: 21.8236, lon: 105.2142 },
    ProvinceCoord { name: "Lào Cai", lat: 22.4856, lon: 103.9707 },
    ProvinceCoord { name: "Điện Biên", lat: 21.3860, lon: 103.0230 },
    ProvinceCoord { name: "Lai Châu", lat: 22.3964, lon: 103.4703 },
    ProvinceCoord { name: "Sơn La", lat: 21.3256, lon: 103.9188 },
    ProvinceCoord { name: "Yên Bái", lat: 21.7168, lon: 104.8986 },
    ProvinceCoord { name: "Hòa Bình", lat: 20.8172, lon: 105.3376 },
    ProvinceCoord { name: "Thái Nguyên", lat: 21.5672, lon: 105.8252 },
    ProvinceCoord { name: "Lạng Sơn", lat: 21.8533, lon: 106.7619 },
    ProvinceCoord { name: "Quảng Ninh", lat: 20.9505, lon: 107.0734 },
    ProvinceCoord { name: "Bắc Giang", lat: 21.2731, lon: 106.1946 },
    ProvinceCoord { name: "Phú Thọ", lat: 21.3227, lon: 105.4020 },
    ProvinceCoord { name: "Vĩnh Phúc", lat: 21.3089, lon: 105.6049 },
    ProvinceCoord { name: "Bắc Ninh", lat: 21.1861, lon: 106.0763 },
    ProvinceCoord { name: "Hải Dương", lat: 20.9373, lon: 106.3146 },
    ProvinceCoord { name: "Hải Phòng", lat: 20.8449, lon: 106.6881 },
    ProvinceCoord { name: "Hưng Yên", lat: 20.6464, lon: 106.0511 },
    ProvinceCoord { name: "Thái Bình", lat: 20.4463, lon: 106.3366 },
    ProvinceCoord { name: "Hà Nam", lat: 20.5411, lon: 105.9229 },
    ProvinceCoord { name: "Nam Định", lat: 20.4388, lon: 106.1621 },
    ProvinceCoord { name: "Ninh Bình", lat: 20.2506, lon: 105.9745 },
    ProvinceCoord { name: "Thanh Hóa", lat: 19.8067, lon: 105.7852 },
    ProvinceCoord { name: "Nghệ An", lat: 18.6796, lon: 105.6813 },
    ProvinceCoord { name: "Hà Tĩnh", lat: 18.3559, lon: 105.9059 },
    ProvinceCoord { name: "Quảng Bình", lat: 17.4739, lon: 106.6000 },
    ProvinceCoord { name: "Quảng Trị", lat: 16.8167, lon: 107.1000 },
    ProvinceCoord { name: "Thừa Thiên Huế", lat: 16.4637, lon: 107.5909 },
    ProvinceCoord { name: "Đà Nẵng", lat: 16.0544, lon: 108.2022 },
    ProvinceCoord { name: "Quảng Nam", lat: 15.5667, lon: 108.4833 },
    ProvinceCoord { name: "Quảng Ngãi", lat: 15.1205, lon: 108.7923 },
    ProvinceCoord { name: "Bình Định", lat: 13.7830, lon: 109.2197 },
    ProvinceCoord { name: "Phú Yên", lat: 13.0882, lon: 109.3149 },
    ProvinceCoord { name: "Khánh Hòa", lat: 12.2388, lon: 109.1967 },
    ProvinceCoord { name: "Ninh Thuận", lat: 11.5643, lon: 108.9882 },
    ProvinceCoord { name: "Bình Thuận", lat: 10.9805, lon: 108.2615 },
    ProvinceCoord { name: "Kon Tum", lat: 14.3545, lon: 108.0076 },
    ProvinceCoord { name: "Gia Lai", lat: 13.9833, lon: 108.0000 },
    ProvinceCoord { name: "Đắk Lắk", lat: 12.6667, lon: 108.0500 },
    ProvinceCoord { name: "Đắk Nông", lat: 12.0000, lon: 107.6833 },
    ProvinceCoord { name: "Lâm Đồng", lat: 11.9404, lon: 108.4583 },
    ProvinceCoord { name: "Bình Phước", lat: 11.7512, lon: 106.7235 },
    ProvinceCoord { name: "Tây Ninh", lat: 11.3100, lon: 106.0983 },
    ProvinceCoord { name: "Bình Dương", lat: 11.1667, lon: 106.6500 },
    ProvinceCoord { name: "Đồng Nai", lat: 10.9574, lon: 106.8427 },
    ProvinceCoord { name: "Bà Rịa - Vũng Tàu", lat: 10.3460, lon: 107.0843 },
    ProvinceCoord { name: "TP. Hồ Chí Minh", lat: 10.7769, lon: 106.7009 },
    ProvinceCoord { name: "Long An", lat: 10.5359, lon: 106.4137 },
    ProvinceCoord { name: "Tiền Giang", lat: 10.3667, lon: 106.3667 },
    ProvinceCoord { name: "Bến Tre", lat: 10.2333, lon: 106.3833 },
    ProvinceCoord { name: "Trà Vinh", lat: 9.9333, lon: 106.3500 },
    ProvinceCoord { name: "Vĩnh Long", lat: 10.2500, lon: 105.9667 },
    ProvinceCoord { name: "Đồng Tháp", lat: 10.4500, lon: 105.6333 },
    ProvinceCoord { name: "An Giang", lat: 10.3833, lon: 105.4167 },
    ProvinceCoord { name: "Kiên Giang", lat: 10.0167, lon: 105.0833 },
    ProvinceCoord { name: "Cần Thơ", lat: 10.0452, lon: 105.7469 },
    ProvinceCoord { name: "Hậu Giang", lat: 9.7833, lon: 105.4667 },
    ProvinceCoord { name: "Sóc Trăng", lat: 9.6000, lon: 105.9667 },
    ProvinceCoord { name: "Bạc Liêu", lat: 9.2833, lon: 105.7167 },
    ProvinceCoord { name: "Cà Mau", lat: 9.1769, lon: 105.1500 },
    ProvinceCoord { name: "Hoàng Sa (Đà Nẵng)", lat: 16.5333, lon: 112.0333 },
    ProvinceCoord { name: "Trường Sa (Khánh Hòa)", lat: 9.8833, lon: 114.2500 },
];

pub fn catalog_locations() -> CatalogLocationsResponse {
    let stations = vec![
        CatalogStation { id: "vn_hn_01".into(), name: "Trạm Hoàn Kiếm".into(), province: "Hà Nội".into(), latitude: 21.0285, longitude: 105.8542 },
        CatalogStation { id: "vn_hcm_01".into(), name: "Trạm Quận 1".into(), province: "TP. Hồ Chí Minh".into(), latitude: 10.7769, longitude: 106.7009 },
        CatalogStation { id: "vn_dn_01".into(), name: "Trạm Hải Châu".into(), province: "Đà Nẵng".into(), latitude: 16.0544, longitude: 108.2022 },
        CatalogStation { id: "vn_hp_01".into(), name: "Trạm Hồng Bàng".into(), province: "Hải Phòng".into(), latitude: 20.8449, longitude: 106.6881 },
        CatalogStation { id: "vn_ct_01".into(), name: "Trạm Ninh Kiều".into(), province: "Cần Thơ".into(), latitude: 10.0452, longitude: 105.7469 },
        CatalogStation { id: "vn_hue_01".into(), name: "Trạm TP. Huế".into(), province: "Thừa Thiên Huế".into(), latitude: 16.4637, longitude: 107.5909 },
        CatalogStation { id: "vn_nt_01".into(), name: "Trạm Nha Trang".into(), province: "Khánh Hòa".into(), latitude: 12.2388, longitude: 109.1967 },
        CatalogStation { id: "vn_hl_01".into(), name: "Trạm Hạ Long".into(), province: "Quảng Ninh".into(), latitude: 20.9505, longitude: 107.0734 },
        CatalogStation { id: "vn_dl_01".into(), name: "Trạm TP. Đà Lạt".into(), province: "Lâm Đồng".into(), latitude: 11.9404, longitude: 108.4583 },
        CatalogStation { id: "vn_vt_01".into(), name: "Trạm TP. Vũng Tàu".into(), province: "Bà Rịa - Vũng Tàu".into(), latitude: 10.3460, longitude: 107.0843 },
        CatalogStation { id: "vn_hs_01".into(), name: "Trạm Quần đảo Hoàng Sa".into(), province: "TP. Đà Nẵng".into(), latitude: 16.5333, longitude: 112.0333 },
        CatalogStation { id: "vn_ts_01".into(), name: "Trạm Quần đảo Trường Sa".into(), province: "Tỉnh Khánh Hòa".into(), latitude: 9.8833, longitude: 114.2500 },
    ];
    let flood_blackspots = vec![
        CatalogFloodBlackspot { id: "hn_flood_01".into(), name: "Ngã tư Phan Bội Châu - Lý Thường Kiệt".into(), province: "Hà Nội".into(), latitude: 21.0258, longitude: 105.8458, description: "Vùng trũng trung tâm Hoàn Kiếm, nước thoát chậm vào hệ thống cống cổ".into(), average_depth_cm: 35, trigger_condition: "Mưa rào dồn dập trên 35mm/h trong 30-45 phút".into(), prone_time: "Mùa mưa bão miền Bắc (Tháng 5 - Tháng 9)".into() },
        CatalogFloodBlackspot { id: "hn_flood_02".into(), name: "Đường Thụy Khuê (Dốc La Pho)".into(), province: "Hà Nội".into(), latitude: 21.0425, longitude: 105.8285, description: "Đoạn trũng gần dốc Tam Đa, mực nước hồ Tây dâng cao làm chậm dòng chảy".into(), average_depth_cm: 30, trigger_condition: "Mưa dông lớn >40mm/h".into(), prone_time: "Mùa hè - thu (Tháng 6 - Tháng 9)".into() },
        CatalogFloodBlackspot { id: "hn_flood_03".into(), name: "Phố Nguyễn Khuyến (Khu vực Văn Miếu)".into(), province: "Hà Nội".into(), latitude: 21.0280, longitude: 105.8360, description: "Điểm trũng lịch sử Đống Đa, thường xuyên đọng nước cục bộ".into(), average_depth_cm: 45, trigger_condition: "Mưa rào kéo dài trên 40 phút (>30mm)".into(), prone_time: "Mùa mưa bão (Tháng 5 - Tháng 10)".into() },
        CatalogFloodBlackspot { id: "hn_flood_04".into(), name: "Phố Hoa Bằng (Cầu Giấy)".into(), province: "Hà Nội".into(), latitude: 21.0230, longitude: 105.7950, description: "Đoạn ngập kéo dài dọc ngõ phố dân cư, giao thông xe máy bị tê liệt".into(), average_depth_cm: 40, trigger_condition: "Mưa to cục bộ >35mm/h".into(), prone_time: "Cao điểm mùa hè (Tháng 6 - Tháng 8)".into() },
        CatalogFloodBlackspot { id: "hn_flood_05".into(), name: "Hầm chui Đại Lộ Thăng Long".into(), province: "Hà Nội".into(), latitude: 21.0020, longitude: 105.7600, description: "Hầm chui số 3, 5, 6 trũng thấp, nước gom nhanh từ lưu vực đường cao tốc".into(), average_depth_cm: 50, trigger_condition: "Mưa to dồn dập >50mm kết hợp xả tràn gom nước".into(), prone_time: "Mùa mưa bão (Tháng 6 - Tháng 10)".into() },
        CatalogFloodBlackspot { id: "hcm_flood_01".into(), name: "Đường Nguyễn Văn Khối (Cây Trâm cũ)".into(), province: "TP. Hồ Chí Minh".into(), latitude: 10.8420, longitude: 106.6540, description: "Khu vực Gò Vấp, địa hình trũng đón nước từ đường Lê Văn Thọ đổ về".into(), average_depth_cm: 45, trigger_condition: "Mưa lớn >40mm/h hoặc mưa dông chiều kết hợp triều dâng".into(), prone_time: "Mùa mưa Nam Bộ (Tháng 5 - Tháng 11)".into() },
        CatalogFloodBlackspot { id: "hcm_flood_02".into(), name: "Đường Quốc Hương (Thảo Điền)".into(), province: "TP. Hồ Chí Minh".into(), latitude: 10.8040, longitude: 106.7320, description: "Rốn ngập Thảo Điền TP. Thủ Đức, chịu tác động kép triều cường sông Sài Gòn".into(), average_depth_cm: 40, trigger_condition: "Triều cường vượt báo động 3 (>1.60m) hoặc mưa to >30mm".into(), prone_time: "Tháng 9 - Tháng 12 (Đỉnh triều) & Mùa mưa (T5 - T11)".into() },
        CatalogFloodBlackspot { id: "hcm_flood_03".into(), name: "Đường Huỳnh Tấn Phát (Quận 7)".into(), province: "TP. Hồ Chí Minh".into(), latitude: 10.7420, longitude: 106.7280, description: "Đoạn từ cầu Phú Xuân đến Nhà Bè, mép sông Nhà Bè dâng nhanh".into(), average_depth_cm: 35, trigger_condition: "Đỉnh triều rằm / mùng 1 âm lịch hoặc mưa kéo dài".into(), prone_time: "Tháng 8 - Tháng 12 âm lịch".into() },
        CatalogFloodBlackspot { id: "hcm_flood_04".into(), name: "Đường Ung Văn Khiêm (Bình Thạnh)".into(), province: "TP. Hồ Chí Minh".into(), latitude: 10.8080, longitude: 106.7150, description: "Đoạn ngã ba Nguyễn Gia Trí, cống tiêu ra sông Sài Gòn bị áp lực nước dâng".into(), average_depth_cm: 35, trigger_condition: "Mưa to trên 40mm/h trong 1 giờ".into(), prone_time: "Mùa mưa (Tháng 5 - Tháng 11)".into() },
        CatalogFloodBlackspot { id: "hcm_flood_05".into(), name: "Đường Tô Ngọc Vân (TP. Thủ Đức)".into(), province: "TP. Hồ Chí Minh".into(), latitude: 10.8620, longitude: 106.7550, description: "Đoạn giao cắt đường sắt Bắc Nam, độ dốc lớn dồn dòng nước cuộn xiết".into(), average_depth_cm: 45, trigger_condition: "Mưa dông lớn >35mm/h".into(), prone_time: "Mùa mưa bão (Tháng 6 - Tháng 11)".into() },
        CatalogFloodBlackspot { id: "dn_flood_01".into(), name: "Khu vực Hàm Nghi - Bờ Hồ".into(), province: "Đà Nẵng".into(), latitude: 16.0610, longitude: 108.2120, description: "Vùng trũng hồ Thạc Gián - Vĩnh Trung trung tâm Hải Châu/Thanh Khê".into(), average_depth_cm: 35, trigger_condition: "Mưa lớn dồn dập sau áp thấp nhiệt đới (>50mm/h)".into(), prone_time: "Mùa mưa bão miền Trung (Tháng 9 - Tháng 12)".into() },
        CatalogFloodBlackspot { id: "dn_flood_02".into(), name: "Đường Trưng Nữ Vương".into(), province: "Đà Nẵng".into(), latitude: 16.0520, longitude: 108.2190, description: "Đoạn gần cầu Rồng và chợ Mới, cống thoát ra sông Hàn bị hạn chế khi thủy triều cao".into(), average_depth_cm: 30, trigger_condition: "Mưa lớn >40mm/h kết hợp triều cường sông Hàn".into(), prone_time: "Tháng 10 - Tháng 12".into() },
        CatalogFloodBlackspot { id: "ct_flood_01".into(), name: "Đường Mậu Thân - Nguyễn Văn Cừ".into(), province: "Cần Thơ".into(), latitude: 10.0380, longitude: 105.7720, description: "Giao lộ trọng điểm Ninh Kiều, chịu tác động trực tiếp của lũ thượng nguồn sông Hậu".into(), average_depth_cm: 40, trigger_condition: "Đỉnh triều rằm tháng 9 - 10 âm lịch kết hợp mưa chiều".into(), prone_time: "Tháng 9 - Tháng 11 (Mùa nước nổi & triều cường ĐBSCL)".into() },
    ];
    CatalogLocationsResponse { stations, flood_blackspots }
}

fn haversine_km(lat1: f64, lon1: f64, lat2: f64, lon2: f64) -> f64 {
    let p = std::f64::consts::PI / 180.0;
    let dlat = (lat2 - lat1) * p;
    let dlon = (lon2 - lon1) * p;
    let a = (dlat / 2.0).sin().powi(2) + (lat1 * p).cos() * (lat2 * p).cos() * (dlon / 2.0).sin().powi(2);
    12742.0 * a.clamp(0.0, 1.0).sqrt().asin()
}

fn find_closest_province(lat: f64, lon: f64) -> (&'static str, f64) {
    let mut best_name = "Việt Nam";
    let mut best_dist = f64::INFINITY;
    for p in VIETNAM_PROVINCE_COORDS {
        let d = haversine_km(lat, lon, p.lat, p.lon);
        if d < best_dist {
            best_dist = d;
            best_name = p.name;
        }
    }
    (best_name, best_dist)
}

fn format_acq_vn_time(acq_date: &str, acq_time: &str) -> String {
    let padded = format!("{:0>4}", acq_time);
    let parsed = NaiveDate::parse_from_str(acq_date, "%Y-%m-%d").ok().and_then(|d| {
        let h = padded.get(0..2)?.parse::<u32>().ok()?;
        let m = padded.get(2..4)?.parse::<u32>().ok()?;
        Some(NaiveDateTime::new(d, NaiveTime::from_hms_opt(h, m, 0)?))
    });
    match parsed {
        Some(utc) => {
            let vn = utc + ChronoDuration::hours(7);
            format!("{} (Vệ tinh NOAA-20 quét)", vn.format("%d/%m lúc %H:%M"))
        }
        None => format!("{acq_date} {acq_time} (UTC)"),
    }
}

fn classify_fire_type(province: &str, frp: f64) -> String {
    let norm = province.to_lowercase();
    let is_delta = norm.contains("đồng tháp") || norm.contains("an giang") || norm.contains("cần thơ") || norm.contains("kiên giang") || norm.contains("long an") || norm.contains("hà nội") || norm.contains("hưng yên");
    if is_delta {
        return if frp >= 20.0 { "Điểm phát xạ nhiệt ở vùng đồng bằng (công suất cao)".into() } else { "Điểm nhiệt bề mặt ở vùng đồng bằng".into() };
    }
    let is_highland = norm.contains("gia lai") || norm.contains("kon tum") || norm.contains("đắk lắk") || norm.contains("lâm đồng") || norm.contains("sơn la") || norm.contains("bình phước");
    if is_highland {
        return if frp >= 20.0 { "Điểm phát xạ nhiệt ở vùng cao (công suất cao)".into() } else { "Điểm nhiệt bề mặt ở vùng cao".into() };
    }
    if frp >= 20.0 { "Điểm phát xạ nhiệt bề mặt quy mô lớn".into() } else { "Điểm nhiệt bề mặt ghi nhận từ vệ tinh".into() }
}

pub fn parse_firms_csv(csv_text: &str) -> Vec<Hotspot> {
    let mut raw_rows: Vec<(f64, f64, f64, String, String, f64, f64)> = Vec::new();
    for line in csv_text.lines().skip(1) {
        let cols: Vec<&str> = line.split(',').collect();
        if cols.len() < 13 { continue; }
        let lat = match cols[0].trim().parse::<f64>() { Ok(v) if v.is_finite() && (-90.0..=90.0).contains(&v) => v, _ => continue };
        let lon = match cols[1].trim().parse::<f64>() { Ok(v) if v.is_finite() && (-180.0..=180.0).contains(&v) => v, _ => continue };
        let bright = match cols[2].trim().parse::<f64>() { Ok(v) if v.is_finite() => v, _ => continue };
        let acq_date = cols[5].trim().to_string();
        let acq_time = cols[6].trim().to_string();
        let conf = match cols[9].trim().to_lowercase().as_str() {
            "h" => 95.0,
            "n" => 80.0,
            "l" => 50.0,
            other => other.parse::<f64>().unwrap_or(80.0),
        };
        let frp = cols[12].trim().parse::<f64>().unwrap_or(0.0);
        raw_rows.push((lat, lon, bright, acq_date, acq_time, conf, frp));
    }
    // Sort and truncate to top 75 BEFORE province reverse-geocoding for O(75) performance.
    raw_rows.sort_by(|a, b| b.2.partial_cmp(&a.2).unwrap_or(std::cmp::Ordering::Equal));
    raw_rows.truncate(75);
    raw_rows.into_iter().map(|(lat, lon, bright, acq_date, acq_time, conf, frp)| {
        let (province, dist_km) = find_closest_province(lat, lon);
        let location_name = if dist_km < 15.0 {
            format!("Khu vực {province}")
        } else {
            format!("Cách {province} ~{:.0}km", dist_km)
        };
        let detected_time = format_acq_vn_time(&acq_date, &acq_time);
        let fire_type = classify_fire_type(province, frp);
        let description = if frp >= 20.0 {
            format!("Tín hiệu phát xạ nhiệt tăng cao ({:.1} MW) • Phát hiện bởi vệ tinh NOAA-20 (VIIRS 375m)", frp)
        } else {
            format!("Ghi nhận tín hiệu nhiệt bề mặt ({:.1} MW) • Phát hiện bởi vệ tinh NOAA-20 (VIIRS 375m)", frp)
        };
        Hotspot {
            id: format!("nasa_viirs_{acq_date}_{acq_time}_{lat:.4}_{lon:.4}"),
            location_name,
            province: province.into(),
            latitude: lat,
            longitude: lon,
            brightness_kelvin: bright,
            frp,
            confidence: conf,
            fire_type,
            is_active_fire: true,
            prone_season: "Dữ liệu vệ tinh thời gian thực (NOAA-20 VIIRS)".into(),
            detected_time,
            description,
        }
    }).collect()
}

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
        let cache_key = format!("envivn:weather:v2:{:.2}:{:.2}", lat, lon);
        if !force {
            if let Some(cached_json) = self.get_cached_string(&cache_key).await {
                if let Ok(data) = serde_json::from_str::<WeatherData>(&cached_json) {
                    return Ok((data, true));
                }
            }
        }
        let url = format!(
            "https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lon}&current=temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m,surface_pressure,uv_index&hourly=temperature_2m,relative_humidity_2m,weather_code,precipitation_probability&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum&timezone=auto"
        );
        let resp = self.http_client.get(&url).timeout(Duration::from_secs(10)).send().await.map_err(|_| "Weather upstream connection failed".to_string())?;
        let json_val = resp.json::<serde_json::Value>().await.map_err(|_| "Invalid weather upstream JSON".to_string())?;
        let current = json_val.get("current").ok_or_else(|| "Missing current in weather response".to_string())?;
        let mut hourly = Vec::new();
        if let Some(h_obj) = json_val.get("hourly") {
            let times = h_obj.get("time").and_then(|v| v.as_array());
            let temps = h_obj.get("temperature_2m").and_then(|v| v.as_array());
            let humids = h_obj.get("relative_humidity_2m").and_then(|v| v.as_array());
            let rains = h_obj.get("precipitation_probability").and_then(|v| v.as_array());
            let codes = h_obj.get("weather_code").and_then(|v| v.as_array());
            if let Some(t_arr) = times {
                let cutoff = (Local::now().naive_local() - ChronoDuration::hours(1)).format("%Y-%m-%dT%H:%M").to_string();
                for (i, t_val) in t_arr.iter().enumerate() {
                    if hourly.len() >= 24 { break; }
                    let Some(t_str) = t_val.as_str() else { continue };
                    if t_str < cutoff.as_str() { continue; }
                    hourly.push(HourlyWeatherItem {
                        time: t_str.to_string(),
                        temperature: temps.and_then(|a| a.get(i)).and_then(|v| v.as_f64()).unwrap_or(0.0),
                        relative_humidity: humids.and_then(|a| a.get(i)).and_then(|v| v.as_f64()).unwrap_or(0.0).round() as i32,
                        precipitation_probability: rains.and_then(|a| a.get(i)).and_then(|v| v.as_f64()).unwrap_or(0.0).round() as i32,
                        weather_code: codes.and_then(|a| a.get(i)).and_then(|v| v.as_f64()).unwrap_or(0.0).round() as i32,
                    });
                }
            }
        }
        let mut daily = Vec::new();
        if let Some(d_obj) = json_val.get("daily") {
            let dates = d_obj.get("time").and_then(|v| v.as_array());
            let codes = d_obj.get("weather_code").and_then(|v| v.as_array());
            let max_t = d_obj.get("temperature_2m_max").and_then(|v| v.as_array());
            let min_t = d_obj.get("temperature_2m_min").and_then(|v| v.as_array());
            let rain_s = d_obj.get("precipitation_sum").and_then(|v| v.as_array());
            if let Some(d_arr) = dates {
                for (i, d_val) in d_arr.iter().take(7).enumerate() {
                    let Some(d_str) = d_val.as_str() else { continue };
                    daily.push(DailyWeatherItem {
                        date: d_str.to_string(),
                        weather_code: codes.and_then(|a| a.get(i)).and_then(|v| v.as_f64()).unwrap_or(0.0).round() as i32,
                        max_temp: max_t.and_then(|a| a.get(i)).and_then(|v| v.as_f64()).unwrap_or(0.0),
                        min_temp: min_t.and_then(|a| a.get(i)).and_then(|v| v.as_f64()).unwrap_or(0.0),
                        precipitation_sum: rain_s.and_then(|a| a.get(i)).and_then(|v| v.as_f64()).unwrap_or(0.0),
                    });
                }
            }
        }
        let weather = WeatherData {
            temperature: current.get("temperature_2m").and_then(|v| v.as_f64()).unwrap_or(0.0),
            apparent_temperature: current.get("apparent_temperature").and_then(|v| v.as_f64()).unwrap_or(0.0),
            relative_humidity: current.get("relative_humidity_2m").and_then(|v| v.as_f64()).unwrap_or(0.0).round() as i32,
            precipitation: current.get("precipitation").and_then(|v| v.as_f64()).unwrap_or(0.0),
            weather_code: current.get("weather_code").and_then(|v| v.as_f64()).unwrap_or(0.0).round() as i32,
            wind_speed: current.get("wind_speed_10m").and_then(|v| v.as_f64()).unwrap_or(0.0),
            uv_index: current.get("uv_index").and_then(|v| v.as_f64()).unwrap_or(0.0),
            surface_pressure: current.get("surface_pressure").and_then(|v| v.as_f64()).unwrap_or(1013.0),
            hourly,
            daily,
        };
        if let Ok(serialized) = serde_json::to_string(&weather) {
            self.set_cached_string(&cache_key, &serialized, 600).await;
        }
        Ok((weather, false))
    }

    pub async fn fetch_air_quality(&self, lat: f64, lon: f64, force: bool) -> Result<(AirQualityData, bool), String> {
        let cache_key = format!("envivn:airquality:v2:{:.2}:{:.2}", lat, lon);
        if !force {
            if let Some(cached_json) = self.get_cached_string(&cache_key).await {
                if let Ok(data) = serde_json::from_str::<AirQualityData>(&cached_json) {
                    return Ok((data, true));
                }
            }
        }
        let url = format!(
            "https://air-quality-api.open-meteo.com/v1/air-quality?latitude={lat}&longitude={lon}&current=european_aqi,us_aqi,pm10,pm2_5,carbon_monoxide,nitrogen_dioxide,sulphur_dioxide,ozone&hourly=pm2_5,pm10,us_aqi&timezone=auto"
        );
        let resp = self.http_client.get(&url).timeout(Duration::from_secs(10)).send().await.map_err(|_| "Air quality upstream connection failed".to_string())?;
        let json_val = resp.json::<serde_json::Value>().await.map_err(|_| "Invalid air quality upstream JSON".to_string())?;
        let current = json_val.get("current").ok_or_else(|| "Missing current in air quality response".to_string())?;
        let mut hourly = Vec::new();
        if let Some(h_obj) = json_val.get("hourly") {
            let times = h_obj.get("time").and_then(|v| v.as_array());
            let aqis = h_obj.get("us_aqi").and_then(|v| v.as_array());
            let pm25s = h_obj.get("pm2_5").and_then(|v| v.as_array());
            let pm10s = h_obj.get("pm10").and_then(|v| v.as_array());
            if let Some(t_arr) = times {
                let cutoff = (Local::now().naive_local() - ChronoDuration::hours(1)).format("%Y-%m-%dT%H:%M").to_string();
                for (i, t_val) in t_arr.iter().enumerate() {
                    if hourly.len() >= 24 { break; }
                    let Some(t_str) = t_val.as_str() else { continue };
                    if t_str < cutoff.as_str() { continue; }
                    hourly.push(HourlyAqiItem {
                        time: t_str.to_string(),
                        us_aqi: aqis.and_then(|a| a.get(i)).and_then(|v| v.as_f64()).unwrap_or(0.0).round() as i32,
                        pm25: pm25s.and_then(|a| a.get(i)).and_then(|v| v.as_f64()).unwrap_or(0.0),
                        pm10: pm10s.and_then(|a| a.get(i)).and_then(|v| v.as_f64()).unwrap_or(0.0),
                    });
                }
            }
        }
        let air_quality = AirQualityData {
            us_aqi: current.get("us_aqi").and_then(|v| v.as_f64()).unwrap_or(0.0).round() as i32,
            european_aqi: current.get("european_aqi").and_then(|v| v.as_f64()).unwrap_or(0.0).round() as i32,
            pm25: current.get("pm2_5").and_then(|v| v.as_f64()).unwrap_or(0.0),
            pm10: current.get("pm10").and_then(|v| v.as_f64()).unwrap_or(0.0),
            co: current.get("carbon_monoxide").and_then(|v| v.as_f64()).unwrap_or(0.0),
            no2: current.get("nitrogen_dioxide").and_then(|v| v.as_f64()).unwrap_or(0.0),
            so2: current.get("sulphur_dioxide").and_then(|v| v.as_f64()).unwrap_or(0.0),
            o3: current.get("ozone").and_then(|v| v.as_f64()).unwrap_or(0.0),
            hourly,
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
        let rain_prob = weather.hourly.first().map(|h| h.precipitation_probability).unwrap_or(0);
        let aqi_info = calculate_aqi_info(aqi_val);
        let heat_index_info = calculate_heat_index(weather.temperature, weather.relative_humidity, weather.uv_index);
        let flood_risk = calculate_flood_risk(weather.precipitation);
        let activity_advice = calculate_activity_advice(aqi_val, weather.uv_index, rain_prob, weather.precipitation);
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

    pub async fn fetch_map_stations(&self, force: bool) -> Result<MapStationsResponse, String> {
        let cache_key = "envivn:map:stations:v1";
        if !force {
            if let Some(cached_json) = self.get_cached_string(cache_key).await {
                if let Ok(data) = serde_json::from_str::<MapStationsResponse>(&cached_json) {
                    return Ok(data);
                }
            }
        }
        let catalog = catalog_locations().stations;
        let lats: String = catalog.iter().map(|s| s.latitude.to_string()).collect::<Vec<_>>().join(",");
        let lons: String = catalog.iter().map(|s| s.longitude.to_string()).collect::<Vec<_>>().join(",");
        let aqi_url = format!("https://air-quality-api.open-meteo.com/v1/air-quality?latitude={lats}&longitude={lons}&current=us_aqi,pm2_5,pm10&timezone=auto");
        let weather_url = format!("https://api.open-meteo.com/v1/forecast?latitude={lats}&longitude={lons}&current=temperature_2m,apparent_temperature,relative_humidity_2m,precipitation,weather_code,wind_speed_10m,uv_index&timezone=auto");
        let (aqi_res, weather_res) = tokio::join!(
            self.http_client.get(&aqi_url).timeout(Duration::from_secs(12)).send(),
            self.http_client.get(&weather_url).timeout(Duration::from_secs(12)).send()
        );
        let aqi_json = aqi_res.map_err(|_| "Station air quality upstream failed".to_string())?.json::<serde_json::Value>().await.map_err(|_| "Invalid station air quality JSON".to_string())?;
        let weather_json = match weather_res {
            Ok(r) => r.json::<serde_json::Value>().await.ok(),
            Err(_) => None,
        };
        let aqi_arr = aqi_json.as_array().ok_or_else(|| "Unexpected station air quality batch format".to_string())?;
        let weather_arr = weather_json.as_ref().and_then(|v| v.as_array());
        let updated_at = Local::now().to_rfc3339();
        let mut stations = Vec::with_capacity(catalog.len());
        for (i, st) in catalog.iter().enumerate() {
            let cur_aqi = aqi_arr.get(i).and_then(|v| v.get("current"));
            let cur_w = weather_arr.and_then(|arr| arr.get(i)).and_then(|v| v.get("current"));
            stations.push(MapStationItem {
                id: st.id.clone(),
                name: st.name.clone(),
                province: st.province.clone(),
                latitude: st.latitude,
                longitude: st.longitude,
                aqi: cur_aqi.and_then(|c| c.get("us_aqi")).and_then(|v| v.as_f64()).unwrap_or(0.0).round() as i32,
                pm25: cur_aqi.and_then(|c| c.get("pm2_5")).and_then(|v| v.as_f64()).unwrap_or(0.0),
                pm10: cur_aqi.and_then(|c| c.get("pm10")).and_then(|v| v.as_f64()).unwrap_or(0.0),
                temperature: cur_w.and_then(|c| c.get("temperature_2m")).and_then(|v| v.as_f64()),
                apparent_temperature: cur_w.and_then(|c| c.get("apparent_temperature")).and_then(|v| v.as_f64()),
                weather_code: cur_w.and_then(|c| c.get("weather_code")).and_then(|v| v.as_f64()).map(|v| v.round() as i32),
                relative_humidity: cur_w.and_then(|c| c.get("relative_humidity_2m")).and_then(|v| v.as_f64()).map(|v| v.round() as i32),
                wind_speed: cur_w.and_then(|c| c.get("wind_speed_10m")).and_then(|v| v.as_f64()),
                precipitation: cur_w.and_then(|c| c.get("precipitation")).and_then(|v| v.as_f64()),
                uv_index: cur_w.and_then(|c| c.get("uv_index")).and_then(|v| v.as_f64()),
                updated_at: updated_at.clone(),
            });
        }
        let res = MapStationsResponse { total: stations.len(), cached: false, stations };
        let mut cached_copy = res.clone();
        cached_copy.cached = true;
        if let Ok(serialized) = serde_json::to_string(&cached_copy) {
            self.set_cached_string(cache_key, &serialized, 600).await;
        }
        Ok(res)
    }

    async fn fetch_firms_range(&self, api_key: &str, day_range: u8) -> Result<Vec<Hotspot>, String> {
        let url = format!("https://firms.modaps.eosdis.nasa.gov/api/area/csv/{api_key}/VIIRS_NOAA20_NRT/{VIETNAM_FIRMS_BBOX}/{day_range}");
        let resp = self.http_client.get(&url).timeout(Duration::from_secs(12)).send().await.map_err(|_| "NASA FIRMS upstream connection failed".to_string())?;
        let status = resp.status();
        if status.as_u16() == 429 { return Err("NASA FIRMS rate limit exceeded".into()); }
        if status.as_u16() == 403 { return Err("NASA FIRMS authentication failed".into()); }
        if !status.is_success() { return Err(format!("NASA FIRMS upstream status: {status}")); }
        let csv_text = resp.text().await.map_err(|_| "Failed reading NASA FIRMS body".to_string())?;
        if csv_text.trim().starts_with("Invalid") { return Err("NASA FIRMS invalid response".into()); }
        Ok(parse_firms_csv(&csv_text))
    }

    pub async fn fetch_hotspots(&self, force: bool) -> Result<HotspotsResponse, String> {
        let cache_key = "envivn:hotspots:vietnam:v2";
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
        let mut hotspots = self.fetch_firms_range(api_key, 1).await?;
        let mut source = "VIIRS_NOAA20_NRT (24h)".to_string();
        if hotspots.is_empty() {
            hotspots = self.fetch_firms_range(api_key, 2).await?;
            source = "VIIRS_NOAA20_NRT (48h)".to_string();
        }
        let res = HotspotsResponse { total: hotspots.len(), source, cached: false, hotspots };
        let mut cached_copy = res.clone();
        cached_copy.cached = true;
        if let Ok(serialized) = serde_json::to_string(&cached_copy) {
            self.set_cached_string(cache_key, &serialized, 900).await;
        }
        Ok(res)
    }
}
