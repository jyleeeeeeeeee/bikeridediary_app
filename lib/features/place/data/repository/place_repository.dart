import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../model/place_category.dart';
import '../model/place_response.dart';

final placeRepositoryProvider = Provider<PlaceRepository>((ref) {
  return PlaceRepository(ref.watch(dioProvider));
});

class PlaceRepository {
  final Dio _dio;

  PlaceRepository(this._dio);

  /// 서버 places 조회. category = null이면 전체.
  /// 실패(백엔드 미준비 등) 시 빈 리스트 반환 — UI가 텅 비어 보이되 크래시는 방지.
  Future<List<PlaceResponse>> list({PlaceCategory? category}) async {
    try {
      final response = await _dio.get(
        '/places',
        queryParameters: {
          if (category != null) 'category': category.serverCode,
        },
      );
      final list = response.data['data'] as List;
      return list
          .map((e) => PlaceResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException {
      return const [];
    }
  }
}
