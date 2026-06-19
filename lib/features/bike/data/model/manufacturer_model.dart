class ManufacturerModel {
  final String manufacturerName;
  final String displayNameKo;
  final String? country;
  final int displayOrder;
  final String? imageUrl;

  ManufacturerModel({
    required this.manufacturerName,
    required this.displayNameKo,
    this.country,
    required this.displayOrder,
    this.imageUrl,
  });

  factory ManufacturerModel.fromJson(Map<String, dynamic> json) {
    return ManufacturerModel(
      manufacturerName: json['manufacturerName'] as String,
      displayNameKo: json['displayNameKo'] as String,
      country: json['country'] as String?,
      displayOrder: json['displayOrder'] as int,
      imageUrl: json['imageUrl'] as String?,
    );
  }
}
