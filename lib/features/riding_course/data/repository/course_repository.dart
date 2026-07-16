// 라이딩 코스 API 통신 레이어.
// 백엔드 미완성 시 kDebugMode에서만 더미 데이터 fallback.
// 프로덕션 빌드에서는 예외 전파.

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../model/course_detail_response.dart';
import '../model/course_summary_response.dart';

final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  return CourseRepository(ref.watch(dioProvider));
});

class CourseRepository {
  final Dio _dio;

  CourseRepository(this._dio);

  // ── 더미 데이터 (kDebugMode 한정 fallback) ───────────────────────────────
  static const List<Map<String, dynamic>> _dummyCourses = [
    {
      'id': 'dummy-1',
      'name': '한계령 와인딩 코스',
      'distanceMeters': 128400,
      'authorNickname': 'jyl93',
      'ownedByMe': true,
      'isFavorited': false,
    },
    {
      'id': 'dummy-2',
      'name': '춘천 의암호 일주',
      'distanceMeters': 67200,
      'authorNickname': 'jyl93',
      'ownedByMe': true,
      'isFavorited': false,
    },
    {
      'id': 'dummy-3',
      'name': '대관령 업힐 루트',
      'distanceMeters': 94000,
      'authorNickname': '라이더K',
      'ownedByMe': false,
      'isFavorited': true,
    },
    {
      'id': 'dummy-4',
      'name': '제주 해안도로 완주',
      'distanceMeters': 210800,
      'authorNickname': 'jeju_rider',
      'ownedByMe': false,
      'isFavorited': true,
    },
    {
      'id': 'dummy-5',
      'name': '남해 바래길 해안코스',
      'distanceMeters': 156300,
      'authorNickname': '바다라이더',
      'ownedByMe': false,
      'isFavorited': true,
    },
    {
      'id': 'dummy-6',
      'name': '설악산 미시령 코스',
      'distanceMeters': 88100,
      'authorNickname': '알피니스트',
      'ownedByMe': false,
      'isFavorited': false,
    },
  ];

  static Map<String, dynamic> _dummyDetail(String id) {
    final summary = _dummyCourses.firstWhere(
      (c) => c['id'] == id,
      orElse: () => _dummyCourses.first,
    );
    return {
      ...summary,
      'waypoints': [
        {
          'id': '$id-wp-0',
          'seq': 0,
          'role': 'START',
          'name': '강원 인제군 인제읍 합강리',
          'latitude': 38.0543,
          'longitude': 128.1705,
          'placeId': null,
          'placeCategoryCode': null,
        },
        {
          'id': '$id-wp-1',
          'seq': 1,
          'role': 'VIA',
          'name': '강원 인제군 북면 한계리',
          'latitude': 38.1012,
          'longitude': 128.2214,
          'placeId': null,
          'placeCategoryCode': null,
        },
        {
          'id': '$id-wp-2',
          'seq': 2,
          'role': 'VIA',
          'name': '한계령 정상 (1,004m)',
          'latitude': 38.1211,
          'longitude': 128.3456,
          'placeId': null,
          'placeCategoryCode': null,
        },
        {
          'id': '$id-wp-3',
          'seq': 3,
          'role': 'END',
          'name': '강원 양양군 양양읍 남문리',
          'latitude': 38.0978,
          'longitude': 128.6281,
          'placeId': null,
          'placeCategoryCode': null,
        },
      ],
      'path': null, // fallback: 경유지 좌표로 폴리라인 그림
    };
  }
  // ──────────────────────────────────────────────────────────────────────────

  /// 내 코스 목록 (내가 만든 것 + 즐겨찾기한 것 포함).
  Future<List<CourseSummaryResponse>> fetchMyCourses() async {
    try {
      final resp = await _dio.get('/courses/my');
      final list = resp.data['data'] as List;
      return list
          .map((e) =>
              CourseSummaryResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('[CourseRepository] fetchMyCourses fallback: $e');
        return _dummyCourses
            .where((c) => c['ownedByMe'] == true || c['isFavorited'] == true)
            .map((c) => CourseSummaryResponse.fromJson(c))
            .toList();
      }
      rethrow;
    }
  }

  /// 전체 공개 코스 탐색 목록.
  Future<List<CourseSummaryResponse>> fetchAllCourses() async {
    try {
      final resp = await _dio.get('/courses');
      final list = resp.data['data'] as List;
      return list
          .map((e) =>
              CourseSummaryResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('[CourseRepository] fetchAllCourses fallback: $e');
        return _dummyCourses
            .map((c) => CourseSummaryResponse.fromJson(c))
            .toList();
      }
      rethrow;
    }
  }

  /// 코스 상세.
  Future<CourseDetailResponse> fetchCourse(String courseId) async {
    try {
      final resp = await _dio.get('/courses/$courseId');
      return CourseDetailResponse.fromJson(
        resp.data['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('[CourseRepository] fetchCourse fallback ($courseId): $e');
        return CourseDetailResponse.fromJson(_dummyDetail(courseId));
      }
      rethrow;
    }
  }

  /// 즐겨찾기 추가.
  /// 실패 시 예외 전파 — 낙관적 업데이트에서 롤백 처리 가능하도록.
  Future<void> addFavorite(String courseId) async {
    await _dio.post('/courses/$courseId/favorite');
  }

  /// 즐겨찾기 제거.
  /// 실패 시 예외 전파 — 낙관적 업데이트에서 롤백 처리 가능하도록.
  Future<void> removeFavorite(String courseId) async {
    await _dio.delete('/courses/$courseId/favorite');
  }

  /// 코스 삭제 (작성자 본인만, hard delete).
  /// 서버: DELETE /api/v1/courses/{id} → 204 No Content.
  Future<void> deleteCourse(String courseId) async {
    await _dio.delete('/courses/$courseId');
  }
}
