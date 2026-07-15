import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../place/data/model/place_category.dart';
import '../../place/data/model/place_response.dart';
import '../../place/domain/place_provider.dart';
import '../../place/presentation/place_coordinate_edit_screen.dart';
import '../../place/presentation/place_info_edit_screen.dart';
import '../../place/presentation/place_search_add_screen.dart';

/// 지도/필터 공통 액센트 색. iOS 블루로 통일.
const _accentColor = Color(0xFF007AFF);

/// 네이버 지도 + 카테고리 필터 + 검색 + POI 마커.
class CourseMapScreen extends ConsumerStatefulWidget {
  const CourseMapScreen({super.key});

  @override
  ConsumerState<CourseMapScreen> createState() => _CourseMapScreenState();
}

class _CourseMapScreenState extends ConsumerState<CourseMapScreen> {
  NaverMapController? _mapController;
  NOverlayImage? _pinIcon;

  /// 지도에 한 번 올린 모든 마커 (place id → marker).
  /// 필터 변경 시 clear/re-add 대신 setIsVisible로 토글만 함.
  final Map<String, NMarker> _markers = {};

  /// 마커가 참조하는 place 데이터 (visibility 판단용).
  /// _markers와 항상 같은 키셋 유지.
  final Map<String, PlaceResponse> _markerPlaces = {};

  /// 마커 아이콘용 emoji를 이미지로 한 번만 렌더링해서 캐시.
  Future<void> _ensurePinIcon() async {
    if (_pinIcon != null) return;
    if (!mounted) return;
    _pinIcon = await NOverlayImage.fromWidget(
      widget: const SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: Text('📍', style: TextStyle(fontSize: 32)),
        ),
      ),
      size: const Size(40, 40),
      context: context,
    );
  }

  /// 서버에서 받은 전체 places로 마커를 재구성.
  /// 새로 추가된 place 있으면 addOverlay, 사라진 건 removeOverlay.
  /// (지도 진입 초기 1회 + 장소 생성/좌표수정 후 invalidate 시 실행)
  Future<void> _syncMarkers(List<PlaceResponse> places) async {
    final controller = _mapController;
    if (controller == null) return;
    await _ensurePinIcon();

    final newIds = places.map((p) => p.id).toSet();

    // 사라진 마커 제거
    final removed = _markers.keys.where((id) => !newIds.contains(id)).toList();
    for (final id in removed) {
      final m = _markers.remove(id);
      _markerPlaces.remove(id);
      if (m != null) await controller.deleteOverlay(m.info);
    }

    // 새/기존 마커 추가 + 좌표 갱신
    for (final p in places) {
      final existing = _markers[p.id];
      if (existing != null) {
        // 좌표 변경 반영
        existing.setPosition(NLatLng(p.latitude, p.longitude));
        _markerPlaces[p.id] = p;
        continue;
      }
      final marker = NMarker(
        id: p.id,
        position: NLatLng(p.latitude, p.longitude),
        icon: _pinIcon,
        anchor: const NPoint(0.5, 1.0),
        caption: NOverlayCaption(
          text: '${p.category.icon} ${p.name}',
          textSize: 11,
        ),
      );
      marker.setOnTapListener((_) => _showPlaceSheet(p));
      marker.setIsVisible(false); // 필터 적용 전까지 숨김
      await controller.addOverlay(marker);
      _markers[p.id] = marker;
      _markerPlaces[p.id] = p;
    }

    _applyVisibility();
  }

  /// 현재 필터 + 검색 선택에 따라 각 마커의 visibility를 갱신.
  /// 필터 상태 바뀔 때마다 호출 — 마커 재생성 없이 O(n) 토글만.
  void _applyVisibility() {
    final filter = ref.read(placeFilterProvider);
    final selected = ref.read(selectedSearchResultProvider);
    for (final entry in _markers.entries) {
      final place = _markerPlaces[entry.key];
      if (place == null) continue;
      final visible = filter.activeCategories.contains(place.category) ||
          selected?.id == place.id;
      entry.value.setIsVisible(visible);
    }
  }

  void _showPlaceSheet(PlaceResponse place) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _PlaceDetailSheet(place: place),
    );
  }

  /// 검색 결과에서 장소 선택 시:
  /// 1) 해당 카테고리 자동 활성화 (필터를 통해 마커 표시)
  /// 2) selectedSearchResultProvider 세팅 → 필터 비활성 상태여도 강제 표시 백업
  /// 3) 카메라 이동 + 확대
  /// 4) 상세 시트 오픈
  Future<void> _handleSearchSelect(PlaceResponse place) async {
    final filter = ref.read(placeFilterProvider);
    if (!filter.isCategoryActive(place.category)) {
      ref.read(placeFilterProvider.notifier).state =
          filter.toggleCategory(place.category);
    }
    ref.read(selectedSearchResultProvider.notifier).state = place;
    final controller = _mapController;
    if (controller != null) {
      await controller.updateCamera(
        NCameraUpdate.scrollAndZoomTo(
          target: NLatLng(place.latitude, place.longitude),
          zoom: 16,
        ),
      );
    }
    if (!mounted) return;
    _showPlaceSheet(place);
  }

  @override
  Widget build(BuildContext context) {
    // 화면 진입 즉시 places fetch 트리거 (필터와 무관).
    ref.watch(allPlacesProvider);
    // 전체 places가 로드되면 마커 생성/동기화 (1회 + 이후 invalidate 시).
    ref.listen<AsyncValue<List<PlaceResponse>>>(allPlacesProvider, (_, next) {
      next.whenData(_syncMarkers);
    });
    // 필터/검색 상태 바뀌면 visibility만 토글.
    ref.listen<PlaceFilterState>(placeFilterProvider,
        (_, _) => _applyVisibility());
    ref.listen<PlaceResponse?>(selectedSearchResultProvider,
        (_, _) => _applyVisibility());

    return Scaffold(
      appBar: AppBar(
        title: const Text('코스 탐색'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          NaverMap(
            options: NaverMapViewOptions(
              initialCameraPosition: const NCameraPosition(
                target: NLatLng(37.5666, 126.9782),
                zoom: 11,
              ),
              locationButtonEnable: true,
              contentPadding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewPadding.bottom,
              ),
            ),
            onMapReady: (controller) async {
              _mapController = controller;
              // ref.listen은 최초 값에 대해 실행 안 되므로,
              // map ready 시점에 이미 로드된 places가 있으면 직접 동기화.
              final loaded = ref.read(allPlacesProvider).valueOrNull;
              if (loaded != null) await _syncMarkers(loaded);
            },
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: _CategoryFilterBar(onSelectSearch: _handleSearchSelect),
          ),
        ],
      ),
    );
  }
}

/// 상단 필터 바.
/// 상단 Row: [접기/펼치기 chip, 검색창]
/// 펼침 시 chip 아래로 세로 나열: [전체, 찜, 명소, 카페, 식당, 센터, 추가]
class _CategoryFilterBar extends ConsumerStatefulWidget {
  final Future<void> Function(PlaceResponse) onSelectSearch;
  const _CategoryFilterBar({required this.onSelectSearch});

  @override
  ConsumerState<_CategoryFilterBar> createState() =>
      _CategoryFilterBarState();
}

class _CategoryFilterBarState extends ConsumerState<_CategoryFilterBar> {
  bool _expanded = true;

  void _update(PlaceFilterState state) {
    // 다중 선택이라 카테고리 클릭해도 접지 않음. 접기 chip만 접힘 제어.
    ref.read(placeFilterProvider.notifier).state = state;
    // 사용자가 필터를 조작하면 검색 선택은 해제 → 카테고리 규칙만 따르도록.
    ref.read(selectedSearchResultProvider.notifier).state = null;
  }

  void _openAddPlace() async {
    // 네이버 지역검색 기반 신규 등록 흐름.
    // (기존 좌표 직접 지정 방식 PlaceCreateScreen은 사용 안 함.)
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PlaceSearchAddScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(placeFilterProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 상단: 토글 chip + 검색창
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CategoryChip(
              label: _expanded ? '접기' : '펼치기',
              icon: _expanded ? '📁' : '📂',
              isSelected: false,
              onTap: () => setState(() => _expanded = !_expanded),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _PlaceSearchBar(onSelect: widget.onSelectSearch),
            ),
          ],
        ),
        // 펼침: chip 아래로 세로 나열
        if (_expanded) ...[
          const SizedBox(height: 10),
          _CategoryChip(
            label: '전체',
            icon: '🗺️',
            isSelected: filter.isAllActive,
            onTap: () => _update(filter.toggleAll()),
          ),
          const SizedBox(height: 8),
          _CategoryChip(
            label: '찜',
            icon: '💖',
            isSelected: filter.wishActive,
            onTap: () => _update(filter.toggleWish()),
          ),
          for (final cat in PlaceCategory.values) ...[
            const SizedBox(height: 8),
            _CategoryChip(
              label: cat.label,
              icon: cat.icon,
              isSelected: filter.isCategoryActive(cat),
              onTap: () => _update(filter.toggleCategory(cat)),
            ),
          ],
          const SizedBox(height: 8),
          _AddPlaceButton(onTap: _openAddPlace),
        ],
      ],
    );
  }
}

/// 카테고리 오른쪽 상시 노출되는 + 버튼.
class _AddPlaceButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddPlaceButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 34,
          height: 34,
          child: Material(
            color: _accentColor,
            elevation: 3,
            shadowColor: Colors.black26,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: const Center(
                child: Icon(Icons.add, size: 18, color: Colors.white),
              ),
            ),
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          '추가',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: _accentColor,
            shadows: [Shadow(color: Colors.white, blurRadius: 3)],
          ),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final String icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 34,
          height: 34,
          child: Material(
            color: Colors.white,
            elevation: 3,
            shadowColor: Colors.black26,
            shape: CircleBorder(
              side: isSelected
                  ? const BorderSide(color: _accentColor, width: 2)
                  : BorderSide.none,
            ),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 16)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isSelected ? _accentColor : const Color(0xFF1C1C1E),
            shadows: const [
              Shadow(color: Colors.white, blurRadius: 3),
            ],
          ),
        ),
      ],
    );
  }
}

/// 상단 검색창. 타이핑 시 서버 검색 (300ms 디바운스) →
/// 결과 dropdown → 선택 시 지도 이동/확대 + 상세 시트.
class _PlaceSearchBar extends ConsumerStatefulWidget {
  final Future<void> Function(PlaceResponse) onSelect;
  const _PlaceSearchBar({required this.onSelect});

  @override
  ConsumerState<_PlaceSearchBar> createState() => _PlaceSearchBarState();
}

class _PlaceSearchBarState extends ConsumerState<_PlaceSearchBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String _keyword = ''; // 현재 필터에 쓰는 값.

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    // 클라이언트 필터라 디바운스 불필요 — 즉시 반응.
    setState(() => _keyword = value.trim());
  }

  void _clear() {
    _controller.clear();
    setState(() => _keyword = '');
  }

  Future<void> _onTapResult(PlaceResponse place) async {
    _focusNode.unfocus();
    _clear();
    await widget.onSelect(place);
  }

  @override
  Widget build(BuildContext context) {
    final showDropdown = _keyword.isNotEmpty && _focusNode.hasFocus;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.white,
          elevation: 3,
          shadowColor: Colors.black26,
          borderRadius: BorderRadius.circular(12),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: _onChanged,
            decoration: InputDecoration(
              hintText: '장소 이름 검색',
              hintStyle: const TextStyle(
                color: Color(0xFF8E8E93),
                fontSize: 14,
              ),
              prefixIcon: const Icon(Icons.search,
                  color: _accentColor, size: 20),
              suffixIcon: _keyword.isNotEmpty || _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear,
                          color: Color(0xFF8E8E93), size: 18),
                      onPressed: _clear,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 12),
              isDense: true,
            ),
            style: const TextStyle(fontSize: 14),
          ),
        ),
        if (showDropdown)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: _SearchResultsCard(
              keyword: _keyword,
              onTap: _onTapResult,
            ),
          ),
      ],
    );
  }
}

class _SearchResultsCard extends ConsumerWidget {
  final String keyword;
  final Future<void> Function(PlaceResponse) onTap;
  const _SearchResultsCard({required this.keyword, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(placeSearchProvider(keyword));
    return Material(
      color: Colors.white,
      elevation: 3,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 260),
        child: list.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: Text('검색 결과 없음',
                    style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93))),
              )
            : ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: list.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: Color(0xFFEFEFF4)),
                itemBuilder: (_, i) {
                  final p = list[i];
                  return InkWell(
                    onTap: () => onTap(p),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          Text(p.category.icon,
                              style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1C1C1E),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (p.address != null)
                                  Text(
                                    p.address!,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF8E8E93),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

/// 상세 시트 하단 액션 버튼 (좌표 보정 / 정보 수정). 크기 통일용 헬퍼.
class _EditActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _EditActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16, color: _accentColor),
        label: Text(
          label,
          style: const TextStyle(
            color: _accentColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: _accentColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _PlaceDetailSheet extends StatelessWidget {
  final PlaceResponse place;
  const _PlaceDetailSheet({required this.place});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(place.category.icon,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      )),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1C1C1E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        place.category.label,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _accentColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (place.address != null) ...[
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(CupertinoIcons.location,
                      size: 16, color: Color(0xFF8E8E93)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      place.address!,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF4A4A4A)),
                    ),
                  ),
                ],
              ),
            ],
            if (place.description != null) ...[
              const SizedBox(height: 12),
              Text(
                place.description!,
                style: const TextStyle(
                    fontSize: 13, height: 1.45, color: Color(0xFF1C1C1E)),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _EditActionButton(
                    icon: Icons.edit_outlined,
                    label: '정보 수정',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PlaceInfoEditScreen(place: place),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _EditActionButton(
                    icon: Icons.my_location,
                    label: '좌표 보정',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              PlaceCoordinateEditScreen(place: place),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            // TODO: 카카오맵/네이버 지도 딥링크 버튼, 자체 리뷰 섹션은 후속 작업.
          ],
        ),
      ),
    );
  }
}
