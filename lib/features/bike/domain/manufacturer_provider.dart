import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/model/manufacturer_model.dart';
import '../data/repository/manufacturer_repository.dart';

final manufacturerListProvider =
    FutureProvider<List<ManufacturerModel>>((ref) async {
  return ref.watch(manufacturerRepositoryProvider).getManufacturers();
});
