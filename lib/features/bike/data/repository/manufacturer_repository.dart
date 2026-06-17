import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../model/manufacturer_model.dart';

final manufacturerRepositoryProvider = Provider<ManufacturerRepository>((ref) {
  return ManufacturerRepository(ref.watch(dioProvider));
});

class ManufacturerRepository {
  final Dio _dio;

  ManufacturerRepository(this._dio);

  Future<List<ManufacturerModel>> getManufacturers() async {
    final response = await _dio.get('/bike-models/manufacturers');
    final list = response.data['data'] as List;
    return list.map((e) => ManufacturerModel.fromJson(e)).toList();
  }
}
