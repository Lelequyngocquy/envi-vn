use crate::models::{
    ActivityAdviceInfo, AirQualityData, AqiInfo, FloodRiskInfo, HeatIndexInfo, QuickPromptEvaluation,
    QuickPromptsInfo, WeatherData,
};
use chrono::Local;

pub fn calculate_aqi_info(aqi_val: i32) -> AqiInfo {
    let aqi = aqi_val.max(0);
    if aqi <= 50 {
        AqiInfo {
            aqi,
            category: "good".into(),
            label: "Tốt".into(),
            description: "Chất lượng không khí lý tưởng, không gây nguy hại sức khỏe.".into(),
            color_hex: "#4ADE80".into(),
            health_advice: "Không khí trong lành, mở cửa sổ để đón gió tự nhiên.".into(),
            outdoor_advice: "Rất thích hợp cho chạy bộ, đạp xe và các hoạt động thể thao ngoài trời.".into(),
            wear_mask: false,
        }
    } else if aqi <= 100 {
        AqiInfo {
            aqi,
            category: "moderate".into(),
            label: "Trung bình".into(),
            description: "Chấp nhận được. Nhóm người cực kỳ nhạy cảm nên chú ý.".into(),
            color_hex: "#FACC15".into(),
            health_advice: "Chất lượng không khí ở mức chấp nhận được.".into(),
            outdoor_advice: "Có thể tham gia hoạt động ngoài trời bình thường.".into(),
            wear_mask: false,
        }
    } else if aqi <= 150 {
        AqiInfo {
            aqi,
            category: "unhealthy_sensitive".into(),
            label: "Kém (Nhạy cảm)".into(),
            description: "Người già, trẻ em và người bệnh hô hấp có thể bị ảnh hưởng.".into(),
            color_hex: "#FB923C".into(),
            health_advice: "Nhóm người nhạy cảm nên hạn chế ở ngoài trời lâu.".into(),
            outdoor_advice: "Nên giảm cường độ tập thể dục ngoài trời, chuyển vào phòng tập.".into(),
            wear_mask: true,
        }
    } else if aqi <= 200 {
        AqiInfo {
            aqi,
            category: "unhealthy".into(),
            label: "Xấu".into(),
            description: "Bắt đầu ảnh hưởng xấu đến sức khỏe của tất cả mọi người.".into(),
            color_hex: "#F87171".into(),
            health_advice: "Tránh các hoạt động gắng sức ngoài trời.".into(),
            outdoor_advice: "Không nên chạy bộ hoặc tập luyện ngoài trời vào khung giờ này.".into(),
            wear_mask: true,
        }
    } else if aqi <= 300 {
        AqiInfo {
            aqi,
            category: "very_unhealthy".into(),
            label: "Rất xấu".into(),
            description: "Cảnh báo nguy hại sức khỏe nghiêm trọng cho cộng đồng.".into(),
            color_hex: "#A855F7".into(),
            health_advice: "Mọi người nên ở trong nhà, đóng kín cửa sổ và bật máy lọc khí.".into(),
            outdoor_advice: "Tuyệt đối hạn chế tối đa ra ngoài trời.".into(),
            wear_mask: true,
        }
    } else {
        AqiInfo {
            aqi,
            category: "hazardous".into(),
            label: "Nguy hại".into(),
            description: "Mức độ khẩn cấp. Ảnh hưởng nghiêm trọng đến tính mạng.".into(),
            color_hex: "#DC2626".into(),
            health_advice: "Ở trong nhà, đóng kín cửa và bật máy lọc không khí mức cao nhất.".into(),
            outdoor_advice: "Tránh mọi hoạt động ngoài trời.".into(),
            wear_mask: true,
        }
    }
}

pub fn calculate_heat_index(temp_c: f64, humidity: i32, uv_index: f64) -> HeatIndexInfo {
    let hi_c = if temp_c < 26.7 {
        temp_c
    } else {
        let t = temp_c * 9.0 / 5.0 + 32.0;
        let rh = humidity as f64;
        let mut hi = -42.379 + 2.04901523 * t + 10.14333127 * rh
            - 0.22475541 * t * rh
            - 0.00683783 * t * t
            - 0.05481717 * rh * rh
            + 0.00122874 * t * t * rh
            + 0.00085282 * t * rh * rh
            - 0.00000199 * t * t * rh * rh;
        if rh < 13.0 && t >= 80.0 && t <= 112.0 {
            let adj = ((13.0 - rh) / 4.0) * ((17.0 - (t - 95.0).abs()) / 17.0).sqrt();
            hi -= adj;
        } else if rh > 85.0 && t >= 80.0 && t <= 87.0 {
            let adj = ((rh - 85.0) / 10.0) * ((87.0 - t) / 5.0);
            hi += adj;
        }
        (hi - 32.0) * 5.0 / 9.0
    };
    let (risk_level, risk_label, color_hex) = if hi_c < 30.0 {
        ("safe", "An toàn", "#4ADE80")
    } else if hi_c < 38.0 {
        ("caution", "Cần thận trọng", "#FACC15")
    } else if hi_c < 46.0 {
        ("danger", "Nguy cơ cao", "#FB923C")
    } else {
        ("extreme", "Cực kỳ nguy hiểm", "#DC2626")
    };
    let sunburn_time = if uv_index < 3.0 {
        "Trên 60 phút"
    } else if uv_index < 6.0 {
        "Khoảng 45 phút"
    } else if uv_index < 8.0 {
        "Khoảng 30 phút"
    } else if uv_index < 11.0 {
        "Khoảng 15 - 20 phút"
    } else {
        "Dưới 10 phút (Bỏng rát cấp tính)"
    };
    HeatIndexInfo {
        heat_index: (hi_c * 10.0).round() / 10.0,
        risk_level: risk_level.into(),
        risk_label: risk_label.into(),
        color_hex: color_hex.into(),
        sunburn_time_advice: sunburn_time.into(),
    }
}

pub fn calculate_flood_risk(precipitation: f64) -> FloodRiskInfo {
    if precipitation >= 50.0 {
        FloodRiskInfo {
            risk_level: "very_high".into(),
            label: "Rất cao".into(),
            description: "Nguy cơ ngập sâu diện rộng, hạn chế di chuyển".into(),
        }
    } else if precipitation >= 20.0 {
        FloodRiskInfo {
            risk_level: "high".into(),
            label: "Cao".into(),
            description: "Nguy cơ ngập cục bộ các tuyến đường trũng thấp".into(),
        }
    } else if precipitation >= 5.0 {
        FloodRiskInfo {
            risk_level: "medium".into(),
            label: "Trung bình".into(),
            description: "Có khả năng đọng nước cục bộ ở các hẻm nhỏ".into(),
        }
    } else {
        FloodRiskInfo {
            risk_level: "low".into(),
            label: "Thấp".into(),
            description: "Không có nguy cơ ngập úng đáng kể".into(),
        }
    }
}

pub fn calculate_activity_advice(
    aqi: i32,
    uv: f64,
    rain_prob: i32,
    precipitation: f64,
) -> ActivityAdviceInfo {
    let actually_raining = precipitation > 0.1;
    let is_safe = !actually_raining && aqi <= 100 && uv <= 7.0 && rain_prob <= 40;
    let is_avoid = actually_raining || aqi > 150 || uv > 9.0 || rain_prob > 70;
    let (level, status_label, color_hex, advice_text) = if is_safe {
        ("safe", "An toàn", "#4ADE80", "Điều kiện môi trường rất tốt, phù hợp cho tất cả hoạt động thể thao ngoài trời.")
    } else if is_avoid {
        ("avoid", "Không nên", "#F87171", "Thời tiết hoặc chất lượng không khí bất lợi, nên tập luyện trong nhà.")
    } else {
        ("caution", "Cần chú ý", "#FACC15", "Nên theo dõi sát chỉ số và giảm nhẹ cường độ tập luyện nếu thấy khó chịu.")
    };
    let morning_status = if aqi <= 80 { "Lý tưởng (05:30 - 07:00)" } else { "Cần thận trọng" };
    let evening_status = if aqi <= 100 { "Thích hợp (17:30 - 19:00)" } else { "Nên hạn chế" };
    ActivityAdviceInfo {
        level: level.into(),
        status_label: status_label.into(),
        color_hex: color_hex.into(),
        advice_text: advice_text.into(),
        morning_status: morning_status.into(),
        evening_status: evening_status.into(),
    }
}

pub fn evaluate_quick_prompts(
    aqi: i32,
    pm25: f64,
    temp: f64,
    uv: f64,
    precip: f64,
    weather_code: i32,
) -> QuickPromptsInfo {
    let is_raining = precip > 0.1 || matches!(weather_code, 51..=67 | 80..=82 | 95..=99);
    let running = if is_raining {
        QuickPromptEvaluation {
            decision: "Cảnh báo mưa".into(),
            is_safe: false,
            advice: "Đang có mưa hoặc sắp mưa to, nên chuyển sang chạy máy trong nhà.".into(),
        }
    } else if aqi > 150 || pm25 > 55.0 {
        QuickPromptEvaluation {
            decision: "Không khí ô nhiễm nghiêm trọng".into(),
            is_safe: false,
            advice: "Chỉ số bụi mịn vượt ngưỡng an toàn, tuyệt đối không chạy bộ ngoài trời.".into(),
        }
    } else if temp > 34.0 || uv >= 7.5 {
        QuickPromptEvaluation {
            decision: "Nguy cơ nắng nóng hoặc tia cực tím cao".into(),
            is_safe: false,
            advice: "Nhiệt độ hoặc chỉ số UV cao, có nguy cơ sốc nhiệt nếu vận động mạnh.".into(),
        }
    } else if aqi > 50 || pm25 > 15.0 {
        QuickPromptEvaluation {
            decision: "Cần chú ý".into(),
            is_safe: true,
            advice: "Không khí ở mức trung bình, có thể chạy cự ly vừa phải và đeo khẩu trang chuyên dụng nếu nhạy cảm.".into(),
        }
    } else {
        QuickPromptEvaluation {
            decision: "Thời điểm lý tưởng".into(),
            is_safe: true,
            advice: "Thời tiết và chất lượng không khí trong lành, rất thích hợp để chạy bộ!".into(),
        }
    };
    let ventilation = if aqi > 100 || pm25 > 35.0 {
        QuickPromptEvaluation {
            decision: "Đóng kín cửa".into(),
            is_safe: false,
            advice: "Bụi mịn ngoài trời khá cao, nên đóng cửa sổ và bật máy lọc không khí.".into(),
        }
    } else if aqi > 50 || pm25 > 15.0 {
        QuickPromptEvaluation {
            decision: "Mở thoáng ngắn".into(),
            is_safe: true,
            advice: "Có thể mở cửa thông gió trong khoảng 15-20 phút vào đầu giờ sáng.".into(),
        }
    } else {
        QuickPromptEvaluation {
            decision: "Thông gió tối ưu".into(),
            is_safe: true,
            advice: "Không khí rất sạch, hãy mở cửa để đón gió tự nhiên và lưu thông không khí.".into(),
        }
    };
    let children_outdoor = if is_raining {
        QuickPromptEvaluation {
            decision: "Tránh ra ngoài trời do mưa".into(),
            is_safe: false,
            advice: "Thời tiết ẩm ướt dễ gây cảm lạnh cho trẻ nhỏ và người cao tuổi.".into(),
        }
    } else if aqi > 100 || pm25 > 35.0 {
        QuickPromptEvaluation {
            decision: "Hạn chế ra ngoài".into(),
            is_safe: false,
            advice: "Không khí kém, trẻ em và người già nên ở trong phòng điều hòa lọc bụi.".into(),
        }
    } else {
        QuickPromptEvaluation {
            decision: "An toàn ra ngoài".into(),
            is_safe: true,
            advice: "Điều kiện thuận lợi cho các hoạt động dạo bộ nhẹ nhàng của gia đình.".into(),
        }
    };
    let commute = if is_raining {
        QuickPromptEvaluation {
            decision: "Chuẩn bị áo mưa".into(),
            is_safe: false,
            advice: "Có mưa, đường trơn trượt và tầm nhìn giảm, hãy đi chậm và giữ khoảng cách an toàn.".into(),
        }
    } else if aqi > 100 {
        QuickPromptEvaluation {
            decision: "Đeo khẩu trang N95".into(),
            is_safe: false,
            advice: "Khói bụi đường phố cao, hãy đeo khẩu trang chống bụi mịn khi di chuyển bằng xe máy.".into(),
        }
    } else {
        QuickPromptEvaluation {
            decision: "Lưu thông thuận lợi".into(),
            is_safe: true,
            advice: "Thời tiết thuận lợi cho việc di chuyển đi làm hoặc đi học.".into(),
        }
    };
    QuickPromptsInfo {
        running,
        ventilation,
        children_outdoor,
        commute,
    }
}

pub const DOMAIN_GUARDRAIL_RULES: &str = "\n[QUY TẮC PHẠM VI (BẮT BUỘC)]\n- Bạn là Trợ lý Môi trường EnviVN. Bạn CHỈ trả lời về thời tiết, chất lượng không khí, AQI, UV, mưa bão, ngập lụt, cháy rừng và sức khỏe/thể thao ngoài trời.\n- Khi hỏi đúng chủ đề: Hãy trả lời chi tiết, tận tình và đưa ra lời khuyên thiết thực.\n- Với câu hỏi NGOÀI LỀ (lập trình, giải toán, văn học, giải trí...): Bắt buộc từ chối, tuyệt đối không cung cấp code/giải toán, trả lời tối đa 1 câu ngắn.\nVí dụ từ chối:\nUser: Viết code Python cho tôi.\nAssistant: Xin lỗi, tôi là trợ lý EnviVN và chỉ hỗ trợ thông tin về thời tiết, chất lượng không khí và sức khỏe.\nUser: Làm thơ tình giúp tôi.\nAssistant: Xin lỗi, tôi chỉ hỗ trợ các câu hỏi liên quan đến môi trường và sức khỏe.";

pub fn build_default_guardrail_prompt() -> String {
    format!("[HỆ THỐNG CỐ VẤN MÔI TRƯỜNG ENVIVN]{}", DOMAIN_GUARDRAIL_RULES)
}

pub fn build_system_prompt(
    lat: f64,
    lon: f64,
    weather: &WeatherData,
    air_quality: &AirQualityData,
) -> String {
    let now = Local::now();
    let time_str = now.format("%d/%m/%Y %H:%M").to_string();
    let aqi = air_quality.us_aqi.max(air_quality.european_aqi).max(0);
    let aqi_info = calculate_aqi_info(aqi);
    let flood_risk = calculate_flood_risk(weather.precipitation);
    format!(
        "[HỆ THỐNG CỐ VẤN MÔI TRƯỜNG ENVIVN]\n- Vị trí: ({:.4}, {:.4})\n- Thời gian: {}\n- Thời tiết: {:.1}°C (Cảm giác như {:.1}°C), Độ ẩm {}%, Gió {:.1}km/h, UV {:.1}\n- Chất lượng không khí: AQI {} ({}), PM2.5: {:.1} µg/m³, PM10: {:.1} µg/m³\n- Cảnh báo đặc biệt: Mưa {:.1}mm, Nguy cơ ngập: {} ({})\n[YÊU CẦU]\nĐóng vai trò chuyên gia môi trường & sức khỏe. Trả lời ngắn gọn, thực tế, ân cần bằng tiếng Việt tự nhiên.{}",
        lat, lon, time_str, weather.temperature, weather.apparent_temperature, weather.relative_humidity, weather.wind_speed, weather.uv_index, aqi, aqi_info.label, air_quality.pm25, air_quality.pm10, weather.precipitation, flood_risk.label, flood_risk.description, DOMAIN_GUARDRAIL_RULES
    )
}
