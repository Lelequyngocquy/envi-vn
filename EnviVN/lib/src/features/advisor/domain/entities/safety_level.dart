enum SafetyLevel {
  safe(label: 'An toàn & Lý tưởng'),
  caution(label: 'Cần lưu ý & Thận trọng'),
  warning(label: 'Cảnh báo nguy cơ'),
  danger(label: 'Nguy hại - Không nên');

  final String label;

  const SafetyLevel({required this.label});
}
