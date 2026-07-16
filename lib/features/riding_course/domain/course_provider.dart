// 라이딩 코스 Riverpod provider 정의.
// - myCoursesProvider: 내 코스 목록 (내가 만든 것 + 즐겨찾기)
// - allCoursesProvider: 탐색 탭 전체 공개 코스 (in-memory 검색 소스)
// - courseDetailProvider.family: 코스 상세 (courseId 기준)
// - courseSearchProvider.family: 키워드 기반 in-memory 필터 (서버 왕복 없음)

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/model/course_detail_response.dart';
import '../data/model/course_summary_response.dart';
import '../data/repository/course_repository.dart';

/// 내 코스 목록 (내가 만든 것 + 즐겨찾기한 남의 것).
final myCoursesProvider =
    FutureProvider<List<CourseSummaryResponse>>((ref) async {
  return ref.read(courseRepositoryProvider).fetchMyCourses();
});

/// 전체 공개 코스 목록 (탐색 탭 소스, in-memory 검색에도 사용).
final allCoursesProvider =
    FutureProvider<List<CourseSummaryResponse>>((ref) async {
  return ref.read(courseRepositoryProvider).fetchAllCourses();
});

/// 코스 상세. courseId를 키로 사용.
final courseDetailProvider =
    FutureProvider.family<CourseDetailResponse, String>((ref, courseId) async {
  return ref.read(courseRepositoryProvider).fetchCourse(courseId);
});

/// 탐색 탭 검색 — allCoursesProvider 캐시에서 in-memory 부분 일치.
/// 키워드가 비면 전체 반환.
final courseSearchProvider =
    Provider.autoDispose.family<List<CourseSummaryResponse>, String>(
        (ref, keyword) {
  final all = ref.watch(allCoursesProvider).valueOrNull ?? const [];
  final trimmed = keyword.trim().toLowerCase();
  if (trimmed.isEmpty) return all;
  return all
      .where((c) => c.name.toLowerCase().contains(trimmed))
      .toList();
});
