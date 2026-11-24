/// Pure domain enum representing map environmental layers.
enum MapLayerType {
  weather(
    label: 'Thời tiết',
    shortLabel: 'Thời tiết',
    description: 'Nắng, mưa, bão, độ ẩm & nhiệt độ thời gian thực',
  ),
  airQuality(
    label: 'Chất lượng không khí',
    shortLabel: 'Không khí',
    description: 'Chỉ số ô nhiễm AQI, bụi mịn PM2.5 & PM10 chuyên sâu',
  ),
  thermal(
    label: 'Nhiệt độ & Điểm cháy',
    shortLabel: 'Nhiệt & Cháy',
    description: 'Chỉ số sốc nhiệt Heat Index, tia UV & điểm nhiệt vệ tinh',
  ),
  flood(
    label: 'Nguy cơ ngập úng',
    shortLabel: 'Ngập úng',
    description: 'Lượng mưa lớn cục bộ & mạng lưới điểm đen ngập đô thị',
  );

  final String label;
  final String shortLabel;
  final String description;

  const MapLayerType({
    required this.label,
    required this.shortLabel,
    required this.description,
  });
}
