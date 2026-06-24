class NearbyStation {
  final String stationId;
  final String name;
  final String brand;
  final double lat;
  final double lng;
  final int distanceMeters;
  final int price;
  final String fuelType;

  const NearbyStation({
    required this.stationId,
    required this.name,
    required this.brand,
    required this.lat,
    required this.lng,
    required this.distanceMeters,
    required this.price,
    required this.fuelType,
  });

  factory NearbyStation.fromJson(Map<String, dynamic> json) {
    return NearbyStation(
      stationId: json['stationId'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      distanceMeters: json['distanceMeters'] as int,
      price: json['price'] as int,
      fuelType: json['fuelType'] as String,
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
      return '${distanceMeters}m';
    }
    return '${(distanceMeters / 1000).toStringAsFixed(1)}km';
  }

  String get priceDisplay {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
}
