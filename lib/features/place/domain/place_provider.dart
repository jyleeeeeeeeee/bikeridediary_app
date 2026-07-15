import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/model/place_category.dart';
import '../data/model/place_response.dart';
import '../data/repository/place_repository.dart';

/// 다중 선택 필터 상태.
/// 활성 카테고리와 찜(wish) 활성 여부를 각각 관리.
/// 아무 것도 활성이 아니면 마커 미표시.
class PlaceFilterState {
  final Set<PlaceCategory> activeCategories;
  final bool wishActive;

  const PlaceFilterState({
    this.activeCategories = const {},
    this.wishActive = false,
  });

  /// 모두 활성(찜 + 모든 카테고리) → "전체" chip 활성 판단 기준.
  bool get isAllActive =>
      wishActive && activeCategories.length == PlaceCategory.values.length;

  /// 마커 그릴 것도 없는 완전 비활성 상태.
  bool get isEmpty => !wishActive && activeCategories.isEmpty;

  bool isCategoryActive(PlaceCategory c) => activeCategories.contains(c);

  PlaceFilterState toggleCategory(PlaceCategory c) {
    final next = {...activeCategories};
    if (!next.remove(c)) next.add(c);
    return PlaceFilterState(
      activeCategories: next,
      wishActive: wishActive,
    );
  }

  PlaceFilterState toggleWish() {
    return PlaceFilterState(
      activeCategories: activeCategories,
      wishActive: !wishActive,
    );
  }

  /// "전체" 토글: 모두 켜져 있으면 전부 끄고, 아니면 전부 켬.
  PlaceFilterState toggleAll() {
    if (isAllActive) {
      return const PlaceFilterState();
    }
    return PlaceFilterState(
      activeCategories: PlaceCategory.values.toSet(),
      wishActive: true,
    );
  }
}

/// 필터 상태 provider. 기본은 빈 상태 — 지도에 마커 안 뜸.
final placeFilterProvider =
    StateProvider<PlaceFilterState>((ref) => const PlaceFilterState());

/// 전체 places를 서버에서 한 번 가져와 캐시. 다중 필터는 클라이언트 사이드에서 처리.
/// 장소 생성/수정/좌표 변경 시 invalidate하여 재조회.
final allPlacesProvider = FutureProvider<List<PlaceResponse>>((ref) async {
  return ref.read(placeRepositoryProvider).list(category: null);
});

/// 검색으로 선택된 장소. 카테고리 필터와 관계없이 지도에 마커로 강제 표시.
/// null이면 미선택. 사용자가 검색 목록에서 선택 시 세팅.
final selectedSearchResultProvider =
    StateProvider<PlaceResponse?>((ref) => null);

/// 검색 키워드에 따른 결과.
/// 서버 왕복 대신 allPlacesProvider의 in-memory 캐시에서 부분 일치 필터.
/// (서버 keyword 엔드포인트 미구현 상태 우회 + 매 키입력 렉 제거)
final placeSearchProvider = Provider.autoDispose
    .family<List<PlaceResponse>, String>((ref, keyword) {
  final trimmed = keyword.trim().toLowerCase();
  if (trimmed.isEmpty) return const [];
  final all = ref.watch(allPlacesProvider).valueOrNull ?? const [];
  return all
      .where((p) => p.name.toLowerCase().contains(trimmed))
      .toList();
});
