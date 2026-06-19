// 제조사별 모델명 + 타입 (모델 선택 목록용)
class BikeModelName {
  final String name;
  final String? type;

  BikeModelName({required this.name, this.type});

  factory BikeModelName.fromJson(Map<String, dynamic> json) {
    return BikeModelName(
      name: json['name'] as String,
      type: json['type'] as String?,
    );
  }
}
