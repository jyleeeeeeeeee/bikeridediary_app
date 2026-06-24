import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/model/course_response.dart';
import '../data/repository/course_repository.dart';

// 바이크별 코스 목록
final courseListProvider = AsyncNotifierProvider.family<CourseListNotifier, List<CourseResponse>, String>(
  CourseListNotifier.new,
);

class CourseListNotifier extends FamilyAsyncNotifier<List<CourseResponse>, String> {
  @override
  Future<List<CourseResponse>> build(String arg) {
    return ref.watch(courseRepositoryProvider).getCourses(arg);
  }

  Future<void> deleteCourse(String courseId) async {
    await ref.read(courseRepositoryProvider).deleteCourse(courseId);
    ref.invalidateSelf();
  }
}

// 코스 상세
final courseDetailProvider = FutureProvider.family<CourseResponse, String>((ref, courseId) {
  return ref.watch(courseRepositoryProvider).getCourse(courseId);
});
