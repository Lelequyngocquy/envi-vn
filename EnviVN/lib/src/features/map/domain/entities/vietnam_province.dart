import 'package:envivn/src/common/utils/geo_distance_helper.dart';

/// Canonical 63 Vietnamese provinces/municipalities plus Hoang Sa & Truong Sa archipelagos.
enum VietnamProvince {
  haNoi('Hà Nội', 21.0285, 105.8542),
  haGiang('Hà Giang', 22.8026, 104.9784),
  caoBang('Cao Bằng', 22.6667, 106.2500),
  bacKan('Bắc Kạn', 22.1470, 105.8348),
  tuyenQuang('Tuyên Quang', 21.8236, 105.2142),
  laoCai('Lào Cai', 22.4856, 103.9707),
  dienBien('Điện Biên', 21.3860, 103.0230),
  laiChau('Lai Châu', 22.3964, 103.4703),
  sonLa('Sơn La', 21.3256, 103.9188),
  yenBai('Yên Bái', 21.7168, 104.8986),
  hoaBinh('Hòa Bình', 20.8172, 105.3376),
  thaiNguyen('Thái Nguyên', 21.5672, 105.8252),
  langSon('Lạng Sơn', 21.8533, 106.7619),
  quangNinh('Quảng Ninh', 20.9505, 107.0734),
  bacGiang('Bắc Giang', 21.2731, 106.1946),
  phuTho('Phú Thọ', 21.3227, 105.4020),
  vinhPhuc('Vĩnh Phúc', 21.3089, 105.6049),
  bacNinh('Bắc Ninh', 21.1861, 106.0763),
  haiDuong('Hải Dương', 20.9373, 106.3146),
  haiPhong('Hải Phòng', 20.8449, 106.6881),
  hungYen('Hưng Yên', 20.6464, 106.0511),
  thaiBinh('Thái Bình', 20.4463, 106.3366),
  haNam('Hà Nam', 20.5411, 105.9229),
  namDinh('Nam Định', 20.4388, 106.1621),
  ninhBinh('Ninh Bình', 20.2506, 105.9745),
  thanhHoa('Thanh Hóa', 19.8067, 105.7852),
  ngheAn('Nghệ An', 18.6796, 105.6813),
  haTinh('Hà Tĩnh', 18.3559, 105.9059),
  quangBinh('Quảng Bình', 17.4739, 106.6000),
  quangTri('Quảng Trị', 16.8167, 107.1000),
  thuaThienHue('Thừa Thiên Huế', 16.4637, 107.5909),
  daNang('Đà Nẵng', 16.0544, 108.2022),
  quangNam('Quảng Nam', 15.5667, 108.4833),
  quangNgai('Quảng Ngãi', 15.1205, 108.7923),
  binhDinh('Bình Định', 13.7830, 109.2197),
  phuYen('Phú Yên', 13.0882, 109.3149),
  khanhHoa('Khánh Hòa', 12.2388, 109.1967),
  ninhThuan('Ninh Thuận', 11.5643, 108.9882),
  binhThuan('Bình Thuận', 10.9805, 108.2615),
  konTum('Kon Tum', 14.3545, 108.0076),
  giaLai('Gia Lai', 13.9833, 108.0000),
  dakLak('Đắk Lắk', 12.6667, 108.0500),
  dakNong('Đắk Nông', 12.0000, 107.6833),
  lamDong('Lâm Đồng', 11.9404, 108.4583),
  binhPhuoc('Bình Phước', 11.7512, 106.7235),
  tayNinh('Tây Ninh', 11.3100, 106.0983),
  binhDuong('Bình Dương', 11.1667, 106.6500),
  dongNai('Đồng Nai', 10.9574, 106.8427),
  baRiaVungTau('Bà Rịa - Vũng Tàu', 10.3460, 107.0843),
  hoChiMinh('TP. Hồ Chí Minh', 10.7769, 106.7009),
  longAn('Long An', 10.5359, 106.4137),
  tienGiang('Tiền Giang', 10.3667, 106.3667),
  benTre('Bến Tre', 10.2333, 106.3833),
  traVinh('Trà Vinh', 9.9333, 106.3500),
  vinhLong('Vĩnh Long', 10.2500, 105.9667),
  dongThap('Đồng Tháp', 10.4500, 105.6333),
  anGiang('An Giang', 10.3833, 105.4167),
  kienGiang('Kiên Giang', 10.0167, 105.0833),
  canTho('Cần Thơ', 10.0452, 105.7469),
  hauGiang('Hậu Giang', 9.7833, 105.4667),
  socTrang('Sóc Trăng', 9.6000, 105.9667),
  bacLieu('Bạc Liêu', 9.2833, 105.7167),
  caMau('Cà Mau', 9.1769, 105.1500),
  hoangSa('Hoàng Sa (Đà Nẵng)', 16.5333, 112.0333),
  truongSa('Trường Sa (Khánh Hòa)', 9.8833, 114.2500);

  final String provinceName;
  final double latitude;
  final double longitude;

  const VietnamProvince(this.provinceName, this.latitude, this.longitude);

  static ({VietnamProvince province, double distanceKm}) findClosest(double lat, double lon) {
    VietnamProvince closest = VietnamProvince.haNoi;
    double minD = double.infinity;
    for (final p in VietnamProvince.values) {
      final d = GeoDistanceHelper.distanceInKm(lat, lon, p.latitude, p.longitude);
      if (d < minD) {
        minD = d;
        closest = p;
      }
    }
    return (province: closest, distanceKm: minD);
  }
}
