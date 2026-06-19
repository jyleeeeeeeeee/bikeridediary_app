import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/model/bike_model_name.dart';
import '../data/model/manufacturer_model.dart';
import '../data/repository/manufacturer_repository.dart';

final manufacturerListProvider =
    FutureProvider<List<ManufacturerModel>>((ref) async {
  return ref.watch(manufacturerRepositoryProvider).getManufacturers();
});

final modelNamesProvider =
    FutureProvider.family<List<BikeModelName>, String>((ref, manufacturerName) async {
  return ref.watch(manufacturerRepositoryProvider).getModelNames(manufacturerName);
});
