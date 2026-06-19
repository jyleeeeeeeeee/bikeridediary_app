// API-Ninjas type 문자열 → 한글 표시명 매핑
class BikeTypeDisplay {
  static const Map<String, String> _typeToKorean = {
    'Sport': '스포츠',
    'Naked bike': '네이키드',
    'Touring': '투어링',
    'Sport touring': '스포츠 투어링',
    'Enduro / offroad': '엔듀로/오프로드',
    'Cross / motocross': '모토크로스',
    'Super motard': '슈퍼모타드',
    'Custom / cruiser': '크루저',
    'Classic': '클래식',
    'Scooter': '스쿠터',
    'Allround': '올라운드',
    'ATV': 'ATV',
    'Minibike, cross': '미니바이크',
  };

  static String displayName(String? type) {
    if (type == null || type.isEmpty) return '기타';
    return _typeToKorean[type] ?? type;
  }
}
