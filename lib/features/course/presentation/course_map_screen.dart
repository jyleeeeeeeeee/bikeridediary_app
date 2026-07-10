import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../place/data/model/place_category.dart';
import '../../place/data/model/place_response.dart';
import '../../place/domain/place_provider.dart';

/// 네이버 지도 + 카테고리 필터 + POI 마커.
class CourseMapScreen extends ConsumerStatefulWidget {
  const CourseMapScreen({super.key});

  @override
  ConsumerState<CourseMapScreen> createState() => _CourseMapScreenState();
}

class _CourseMapScreenState extends ConsumerState<CourseMapScreen> {
  NaverMapController? _mapController;

  Future<void> _refreshMarkers(List<PlaceResponse> places) async {
    final controller = _mapController;
    if (controller == null) return;
    await controller.clearOverlays(type: NOverlayType.marker);
    for (final p in places) {
      final marker = NMarker(
        id: p.id,
        position: NLatLng(p.latitude, p.longitude),
        caption: NOverlayCaption(text: p.name, textSize: 11),
        iconTintColor: p.category.color,
      );
      marker.setOnTapListener((_) => _showPlaceSheet(p));
      await controller.addOverlay(marker);
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

  @override
  Widget build(BuildContext context) {
    // places가 갱신되면 마커도 갱신.
    ref.listen<AsyncValue<List<PlaceResponse>>>(placesProvider, (_, next) {
      next.whenData(_refreshMarkers);
    });

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
            options: const NaverMapViewOptions(
              initialCameraPosition: NCameraPosition(
                target: NLatLng(37.5666, 126.9782),
                zoom: 11,
              ),
              locationButtonEnable: true,
            ),
            onMapReady: (controller) async {
              _mapController = controller;
              // 초기 로드된 places가 있으면 즉시 마커 그리기.
              final async = ref.read(placesProvider);
              async.whenData(_refreshMarkers);
            },
          ),
          const Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: _CategoryFilterBar(),
          ),
        ],
      ),
    );
  }
}

class _CategoryFilterBar extends ConsumerWidget {
  const _CategoryFilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedCategoriesProvider);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final cat in PlaceCategory.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _CategoryChip(
                category: cat,
                isSelected: selected.contains(cat),
                onTap: () {
                  final next = Set<PlaceCategory>.from(selected);
                  if (next.contains(cat)) {
                    next.remove(cat);
                  } else {
                    next.add(cat);
                  }
                  ref.read(selectedCategoriesProvider.notifier).state = next;
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final PlaceCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? category.color : Colors.white,
      elevation: 3,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                category.icon,
                size: 16,
                color: isSelected ? Colors.white : category.color,
              ),
              const SizedBox(width: 6),
              Text(
                category.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF1C1C1E),
                ),
              ),
            ],
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
                    color: place.category.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(place.category.icon,
                      size: 20, color: place.category.color),
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
                        style: TextStyle(
                          fontSize: 12,
                          color: place.category.color,
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
            // TODO: 카카오맵/네이버 지도 딥링크 버튼, 자체 리뷰 섹션은 후속 작업.
          ],
        ),
      ),
    );
  }
}
