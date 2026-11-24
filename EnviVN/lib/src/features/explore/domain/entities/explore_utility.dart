/// Pure domain catalog of Explore utilities without UI or navigation coupling.
enum ExploreUtility {
  storyShare(
    title: 'Chia sẻ thẻ Story',
    subtitle: 'Xuất ảnh tóm tắt vị trí chia sẻ mạng xã hội',
    badgeText: 'MỚI',
  ),
  desktopWidget(
    title: 'Widget Desktop',
    subtitle: 'Tiện ích 2x2 & 4x2 theo dõi AQI trực tiếp ngoài màn hình',
    badgeText: 'SẮP CÓ',
    futureTitle: 'Widget Màn hình chính',
    futureSubtitle:
        'Tiện ích màn hình chính WidgetKit (iOS) và Glance (Android) đang được hoàn thiện để cập nhật AQI mỗi 30 phút.',
  ),
  morningReport(
    title: 'Bản tin 06:30 sáng',
    subtitle: 'Thông báo định kỳ nhắc nhở chỉ số không khí đầu ngày',
    badgeText: 'SẮP CÓ',
    futureTitle: 'Thông báo Cục bộ 06:30 Sáng',
    futureSubtitle:
        'Lên lịch thông báo không cần Internet, nhắc nhở đeo khẩu trang và tóm tắt chỉ số AQI trước khi đi làm.',
  ),
  environmentalReport(
    title: 'Báo cáo môi trường',
    subtitle: 'Xuất dữ liệu quan trắc định dạng file PDF và CSV',
    badgeText: 'SẮP CÓ',
    futureTitle: 'Xuất Báo cáo Môi trường',
    futureSubtitle:
        'Công cụ tổng hợp biểu đồ diễn biến nồng độ và xuất bản báo cáo phân tích chất lượng không khí.',
  ),
  healthProfile(
    title: 'Hồ sơ sức khỏe',
    subtitle: 'Cá nhân hóa cảnh báo cho người hen suyễn, trẻ em',
    badgeText: 'SẮP CÓ',
    futureTitle: 'Hồ sơ Sức khỏe Cá nhân',
    futureSubtitle:
        'Thiết lập cảnh báo chuyên biệt theo tình trạng thể chất và bệnh lý hô hấp của bạn và người thân.',
  ),
  nasaRadar(
    title: 'Radar nhiệt NASA',
    subtitle: 'Phân tích điểm phát xạ nhiệt theo chu kỳ vệ tinh NOAA',
    badgeText: 'SẮP CÓ',
    futureTitle: 'Radar Dị thường nhiệt NASA',
    futureSubtitle:
        'Hệ thống quét vệ tinh thời gian thực phát hiện các điểm nhiệt độ bề mặt cao trên toàn quốc.',
  ),
  monitoringHistory(
    title: 'Lịch sử quan trắc',
    subtitle: 'Truy xuất biến động chất lượng không khí 30 ngày qua',
    badgeText: 'SẮP CÓ',
    futureTitle: 'Lịch sử Quan trắc 30 Ngày',
    futureSubtitle:
        'Dữ liệu lưu trữ cục bộ đối chiếu xu hướng ô nhiễm theo tuần và tháng.',
  ),
  multiPointCompare(
    title: 'So sánh đa điểm',
    subtitle: 'So sánh chỉ số ô nhiễm giữa các thành phố',
    badgeText: 'SẮP CÓ',
    futureTitle: 'So sánh Chất lượng Không khí',
    futureSubtitle:
        'Công cụ so sánh song song các chỉ số ô nhiễm giữa 2 hoặc nhiều tỉnh thành trên cả nước.',
  );

  final String title;
  final String subtitle;
  final String? badgeText;
  final String? futureTitle;
  final String? futureSubtitle;

  const ExploreUtility({
    required this.title,
    required this.subtitle,
    this.badgeText,
    this.futureTitle,
    this.futureSubtitle,
  });

  bool get isAvailable => this == ExploreUtility.storyShare;
}
