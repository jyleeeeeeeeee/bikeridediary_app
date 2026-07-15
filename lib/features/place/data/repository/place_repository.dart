import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../model/place_candidate.dart';
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

  /// place_name 부분 일치 검색. 백엔드는 GET /places?keyword=... 지원 (구현 예정).
  /// 실패 시 빈 리스트.
  Future<List<PlaceResponse>> search(String keyword) async {
    try {
      final response = await _dio.get(
        '/places',
        queryParameters: {'keyword': keyword},
      );
      final list = response.data['data'] as List;
      return list
          .map((e) => PlaceResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException {
      return const [];
    }
  }

  /// Naver 지역검색 API를 서버 프록시로 호출.
  /// 반환된 좌표는 WGS84로 이미 변환됨. 실패 시 빈 리스트.
  Future<List<PlaceCandidate>> searchExternal(String query) async {
    try {
      final response = await _dio.get(
        '/places/search-external',
        queryParameters: {'query': query},
      );
      final list = response.data['data'] as List;
      return list
          .map((e) => PlaceCandidate.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException {
      return const [];
    }
  }

  /// 좌표 보정. 서버가 즉시 반영하고 갱신된 PlaceResponse 반환.
  Future<PlaceResponse> updateCoordinates(
    String placeId,
    double latitude,
    double longitude,
  ) async {
    final response = await _dio.patch(
      '/places/$placeId/coordinates',
      data: {'latitude': latitude, 'longitude': longitude},
    );
    return PlaceResponse.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  /// 장소 이름/카테고리 수정. 백엔드 PATCH /places/{id}/info (구현 예정).
  Future<PlaceResponse> updateInfo(
    String placeId,
    String name,
    PlaceCategory category,
  ) async {
    final response = await _dio.patch(
      '/places/$placeId/info',
      data: {
        'placeName': name,
        'category': category.serverCode,
      },
    );
    return PlaceResponse.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  /// 새 장소 등록. 백엔드 POST /places.
  Future<PlaceResponse> create({
    required String name,
    required PlaceCategory category,
    required double latitude,
    required double longitude,
    String? address,
    String? roadAddress,
    String? description,
  }) async {
    final response = await _dio.post(
      '/places',
      data: {
        'placeName': name,
        'category': category.serverCode,
        'latitude': latitude,
        'longitude': longitude,
        if (address != null && address.isNotEmpty) 'address': address,
        if (roadAddress != null && roadAddress.isNotEmpty)
          'roadAddress': roadAddress,
        if (description != null && description.isNotEmpty)
          'description': description,
      },
    );
    return PlaceResponse.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }
}
