import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/model/place_category.dart';
import '../data/model/place_response.dart';
import '../data/repository/place_repository.dart';

/// 선택된 카테고리 집합 (다중 선택 가능). 기본은 모두 활성.
final selectedCategoriesProvider =
    StateProvider<Set<PlaceCategory>>((ref) {
  return PlaceCategory.values.toSet();
});

/// 카테고리 필터가 적용된 places 리스트.
/// 서버는 카테고리 파라미터 하나만 받으므로, 여러 카테고리 선택 시 전체 조회 후 로컬 필터.
/// MVP 규모(수백 개)에서는 이 방식이 실용적. 데이터 커지면 bbox 검색으로 전환.
final placesProvider = FutureProvider<List<PlaceResponse>>((ref) async {
  final selected = ref.watch(selectedCategoriesProvider);
  if (selected.isEmpty) return const [];
  final all = await ref.read(placeRepositoryProvider).list();
  return all.where((p) => selected.contains(p.category)).toList();
});
