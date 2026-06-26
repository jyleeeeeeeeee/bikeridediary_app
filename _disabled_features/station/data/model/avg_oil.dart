class AvgOil {
  final String tradeDt;
  final String prodcd;
  final String prodnm;
  final double price;
  final double diff;

  const AvgOil({
    required this.tradeDt,
    required this.prodcd,
    required this.prodnm,
    required this.price,
    required this.diff,
  });

  factory AvgOil.fromJson(Map<String, dynamic> json) {
    return AvgOil(
      tradeDt: json['TRADE_DT'] as String,
      prodcd: json['PRODCD'] as String,
      prodnm: json['PRODNM'] as String,
      price: (json['PRICE'] as num).toDouble(),
      diff: (json['DIFF'] as num).toDouble(),
    );
  }

  String get priceDisplay {
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
}
