import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../model/course_create_request.dart';
import '../model/course_response.dart';

final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  return CourseRepository(ref.watch(dioProvider));
});

class CourseRepository {
  final Dio _dio;

  CourseRepository(this._dio);

  Future<List<CourseResponse>> getCourses(String bikeId) async {
    final response = await _dio.get('/courses', queryParameters: {'bikeId': bikeId});
    final list = response.data['data'] as List;
    return list.map((e) => CourseResponse.fromJson(e)).toList();
  }

  Future<CourseResponse> getCourse(String id) async {
    final response = await _dio.get('/courses/$id');
    return CourseResponse.fromJson(response.data['data']);
  }

  Future<CourseResponse> createCourse(CourseCreateRequest request) async {
    final response = await _dio.post('/courses', data: request.toJson());
    return CourseResponse.fromJson(response.data['data']);
  }

  Future<void> deleteCourse(String id) async {
    await _dio.delete('/courses/$id');
  }
}
