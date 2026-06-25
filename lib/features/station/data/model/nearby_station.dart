class NearbyStation {
  final String stationId;
  final String name;
  final String brand;
  final double lat;
  final double lng;
  final double distanceMeters;
  final double price;

  const NearbyStation({
    required this.stationId,
    required this.name,
    required this.brand,
    required this.lat,
    required this.lng,
    required this.distanceMeters,
    required this.price,
  });

  factory NearbyStation.fromJson(Map<String, dynamic> json) {
    return NearbyStation(
      stationId: json['UNI_ID'] as String,
      name: json['OS_NM'] as String,
      brand: json['POLL_DIV_CD'] as String,
      lat: (json['GIS_X_COOR'] as num).toDouble(),
      lng: (json['GIS_Y_COOR'] as num).toDouble(),
      distanceMeters: (json['DISTANCE'] as num).toDouble(),
      price: (json['PRICE'] as num).toDouble(),
    );
  }

  String get brandDisplayName {
    switch (brand) {
      case 'SKE':
        return 'SK에너지';
      case 'GSC':
        return 'GS칼텍스';
      case 'HDO':
        return '현대오일뱅크';
      case 'SOL':
        return 'S-OIL';
      case 'RTC':
        return '자영알뜰';
      case 'ETC':
        return '알뜰주유소';
      case 'E1G':
        return 'E1';
      case 'SKG':
        return 'SK가스';
      default:
        return brand;
    }
  }

  String get distanceDisplay {
    if (distanceMeters < 1000) {
      return '${distanceMeters.toStringAsFixed(0)}m';
    }
    return '${(distanceMeters / 1000).toStringAsFixed(1)}km';
  }

  String get priceDisplay {
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
}
