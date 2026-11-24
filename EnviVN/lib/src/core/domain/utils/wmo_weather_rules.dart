/// Pure Dart WMO weather code classification rules aligned with Backend Rust.
class WmoWeatherRules {
  WmoWeatherRules._();

  static bool isRainCode(int? code) {
    if (code == null) return false;
    return (code >= 51 && code <= 67) || (code >= 80 && code <= 82) || (code >= 95 && code <= 99);
  }

  static bool isThunderCode(int? code) {
    if (code == null) return false;
    return code >= 95 && code <= 99;
  }

  static String describe(int? code) {
    switch (code) {
      case null:
        return 'Không rõ';
      case 0:
        return 'Trời quang đãng';
      case 1:
        return 'Hầu như không mây';
      case 2:
        return 'Mây rải rác';
      case 3:
        return 'Trời nhiều mây';
      case 45:
      case 48:
        return 'Có sương mù';
      case 51:
      case 53:
      case 55:
      case 56:
      case 57:
        return 'Mưa phùn nhẹ';
      case 61:
      case 66:
        return 'Mưa nhỏ';
      case 63:
        return 'Mưa vừa';
      case 65:
      case 67:
        return 'Mưa rào lớn';
      case 80:
      case 81:
      case 82:
        return 'Mưa rào bất chợt';
      case 95:
      case 96:
      case 99:
        return 'Dông sét & Mưa bão';
      default:
        return 'Có mây';
    }
  }
}
