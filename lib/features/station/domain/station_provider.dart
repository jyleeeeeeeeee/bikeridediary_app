import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/model/avg_oil.dart';
import '../data/repository/station_repository.dart';

final avgOilPriceProvider = FutureProvider<List<AvgOil>>((ref) {
  return ref.watch(stationRepositoryProvider).getAvgPrice();
});
