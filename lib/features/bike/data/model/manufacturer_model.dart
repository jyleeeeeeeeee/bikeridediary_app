class ManufacturerModel {
  final int id;
  final String apiName;
  final String displayNameKo;
  final String? country;
  final int displayOrder;
  final String? logoUrl;

  ManufacturerModel({
    required this.id,
    required this.apiName,
    required this.displayNameKo,
    this.country,
    required this.displayOrder,
    this.logoUrl,
  });

  factory ManufacturerModel.fromJson(Map<String, dynamic> json) {
    return ManufacturerModel(
      id: json['id'] as int,
      apiName: json['apiName'] as String,
      displayNameKo: json['displayNameKo'] as String,
      country: json['country'] as String?,
      displayOrder: json['displayOrder'] as int,
      logoUrl: json['logoUrl'] as String?,
    );
  }
}
