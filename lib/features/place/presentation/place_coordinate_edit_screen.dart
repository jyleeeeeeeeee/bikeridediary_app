import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/model/place_response.dart';
import '../data/repository/place_repository.dart';
import '../domain/place_provider.dart';

/// 좌표 보정 화면.
/// 지도 중앙 크로스헤어가 새 좌표. 원본 위치는 빨간 참조 마커로 함께 표시.
class PlaceCoordinateEditScreen extends ConsumerStatefulWidget {
  final PlaceResponse place;
  const PlaceCoordinateEditScreen({super.key, required this.place});

  @override
  ConsumerState<PlaceCoordinateEditScreen> createState() =>
      _PlaceCoordinateEditScreenState();
}

class _PlaceCoordinateEditScreenState
    extends ConsumerState<PlaceCoordinateEditScreen> {
  NaverMapController? _mapController;
  late NLatLng _center;
  NOverlayImage? _originalMarkerIcon;
  bool _saving = false;

  static const _accentColor = Color(0xFF007AFF);
  static const _originalColor = Color(0xFFFF3B30);

  @override
  void initState() {
    super.initState();
    _center = NLatLng(widget.place.latitude, widget.place.longitude);
  }

  Future<void> _ensureOriginalMarkerIcon() async {
    if (_originalMarkerIcon != null || !mounted) return;
    _originalMarkerIcon = await NOverlayImage.fromWidget(
      widget: const SizedBox(
        width: 32,
        height: 32,
        child: Center(child: Text('📍', style: TextStyle(fontSize: 24))),
      ),
      size: const Size(32, 32),
      context: context,
    );
  }

  Future<void> _addOriginalMarker() async {
    final controller = _mapController;
    if (controller == null) return;
    await _ensureOriginalMarkerIcon();
    final origin = NMarker(
      id: 'origin-${widget.place.id}',
      position: NLatLng(widget.place.latitude, widget.place.longitude),
      icon: _originalMarkerIcon,
      anchor: const NPoint(0.5, 1.0),
      caption: NOverlayCaption(
        text: '기존',
        textSize: 11,
        color: _originalColor,
      ),
    );
    await controller.addOverlay(origin);
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(placeRepositoryProvider).updateCoordinates(
            widget.place.id,
            _center.latitude,
            _center.longitude,
          );
      // 지도가 새 좌표를 반영하도록 places 캐시 무효화.
      ref.invalidate(allPlacesProvider);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('저장 실패: ${e.response?.statusCode ?? '네트워크 오류'}'),
          backgroundColor: _originalColor,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final original = NLatLng(widget.place.latitude, widget.place.longitude);
    final movedMeters = _center.distanceTo(original);

    return Scaffold(
      appBar: AppBar(
        title: Text('좌표 보정 — ${widget.place.name}'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          NaverMap(
            options: NaverMapViewOptions(
              initialCameraPosition: NCameraPosition(target: original, zoom: 17),
              locationButtonEnable: true,
            ),
            onMapReady: (controller) async {
              _mapController = controller;
              await _addOriginalMarker();
            },
            onCameraChange: (reason, animated) async {
              final controller = _mapController;
              if (controller == null) return;
              final pos = await controller.getCameraPosition();
              setState(() => _center = pos.target);
            },
          ),
          // 중앙 크로스헤어. IgnorePointer로 지도 조작 방해 안 함.
          const IgnorePointer(
            child: Center(
              child: Icon(Icons.add, size: 44, color: _accentColor),
            ),
          ),
          // 상단 좌표/이동거리 표시.
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Card(
              color: Colors.white,
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.add,
                            size: 14, color: _accentColor),
                        const SizedBox(width: 4),
                        Text(
                          '${_center.latitude.toStringAsFixed(7)},  ${_center.longitude.toStringAsFixed(7)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1C1C1E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Text('📍',
                            style: TextStyle(fontSize: 11)),
                        const SizedBox(width: 4),
                        Text(
                          '기존 좌표에서 ${movedMeters.toStringAsFixed(1)} m 이동',
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF8E8E93)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 하단 저장 버튼. 시스템 nav(제스처바)에 가리지 않도록 SafeArea로 감쌈.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.only(bottom: 24),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('이 위치로 저장',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
