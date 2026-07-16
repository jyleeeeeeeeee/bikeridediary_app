// 코스 상세 화면.
// 상단 절반: flutter_naver_map (경유지 마커 + 폴리라인)
// 하단 절반: 코스명/거리/작성자/경유지 목록 (스크롤)
// shell 밖 전체 화면 → SafeArea 하단 처리 필수.

import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/model/course_waypoint_response.dart';
import '../data/repository/course_repository.dart';
import '../domain/course_provider.dart';

/// 경유지 role별 색상.
const _colorStart = Color(0xFF34C759); // 초록: START
const _colorVia   = Color(0xFF007AFF); // 파랑: VIA
const _colorEnd   = Color(0xFFFF3B30); // 빨강: END

class CourseDetailScreen extends ConsumerStatefulWidget {
  final String courseId;

  const CourseDetailScreen({super.key, required this.courseId});

  @override
  ConsumerState<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen> {
  NaverMapController? _mapController;
  bool _mapReady = false;

  // ── 지도 초기화 ──────────────────────────────────────────────────────────

  void _onMapReady(NaverMapController controller) {
    _mapController = controller;
    setState(() => _mapReady = true);
    _drawCourse();
  }

  /// 지도에 경유지 마커 + 폴리라인을 그린다.
  Future<void> _drawCourse() async {
    final controller = _mapController;
    if (controller == null) return;

    final detail = ref.read(courseDetailProvider(widget.courseId)).valueOrNull;
    if (detail == null) return;

    final waypoints = detail.waypoints;
    if (waypoints.isEmpty) return;

    // 마커
    final markers = <NMarker>{};
    int viaIndex = 1;
    for (final wp in waypoints) {
      final color = _roleColor(wp.role);
      final label = _roleLabel(wp.role, viaIndex);
      if (wp.role == 'VIA') viaIndex++;

      final marker = NMarker(
        id: wp.id,
        position: NLatLng(wp.latitude, wp.longitude),
        caption: NOverlayCaption(text: label),
        iconTintColor: color,
      );
      markers.add(marker);
    }
    await controller.addOverlayAll(markers);

    // 폴리라인 좌표 결정
    List<NLatLng> coords;
    if (detail.pathJson != null) {
      coords = _parsePathJson(detail.pathJson!);
    } else {
      coords = waypoints
          .map((w) => NLatLng(w.latitude, w.longitude))
          .toList();
    }

    if (coords.length >= 2) {
      final polyline = NPolylineOverlay(
        id: 'course-path',
        coords: coords,
        color: const Color(0xFF007AFF),
        width: 4,
      );
      await controller.addOverlay(polyline);
    }

    // 카메라를 모든 마커가 보이도록 이동
    if (waypoints.isNotEmpty) {
      final bounds = NLatLngBounds.from(
        waypoints.map((w) => NLatLng(w.latitude, w.longitude)).toList(),
      );
      await controller.updateCamera(
        NCameraUpdate.fitBounds(bounds, padding: const EdgeInsets.all(40)),
      );
    }
  }

  /// pathJson 문자열("[[lng,lat],...]") → NLatLng 리스트.
  List<NLatLng> _parsePathJson(String pathJson) {
    try {
      final decoded = jsonDecode(pathJson) as List;
      return decoded.map((pair) {
        final arr = pair as List;
        final lng = (arr[0] as num).toDouble();
        final lat = (arr[1] as num).toDouble();
        return NLatLng(lat, lng);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // ── 삭제 ─────────────────────────────────────────────────────────────────

  Future<void> _deleteCourse() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('코스 삭제'),
        content: const Text('정말 삭제하시겠어요? 되돌릴 수 없습니다.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(courseRepositoryProvider).deleteCourse(widget.courseId);
      // 관련 provider invalidate
      ref.invalidate(myCoursesProvider);
      ref.invalidate(allCoursesProvider);
      ref.invalidate(courseDetailProvider(widget.courseId));
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제 실패: $e')),
        );
      }
    }
  }

  // ── 즐겨찾기 토글 ────────────────────────────────────────────────────────

  Future<void> _toggleFavorite(bool currentFavorited) async {
    final repo = ref.read(courseRepositoryProvider);
    try {
      if (currentFavorited) {
        await repo.removeFavorite(widget.courseId);
      } else {
        await repo.addFavorite(widget.courseId);
      }
      // 관련 provider invalidate (서버 응답 반영)
      ref.invalidate(courseDetailProvider(widget.courseId));
      ref.invalidate(myCoursesProvider);
      ref.invalidate(allCoursesProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('즐겨찾기 변경에 실패했습니다.')),
        );
      }
    }
  }

  // ── 빌드 ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(courseDetailProvider(widget.courseId));

    // 지도 데이터 준비되면 다시 그리기
    ref.listen(courseDetailProvider(widget.courseId), (_, next) {
      if (next.hasValue && _mapReady) {
        _drawCourse();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text('$e', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    ref.invalidate(courseDetailProvider(widget.courseId)),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
        data: (detail) => _buildBody(context, detail),
      ),
    );
  }

  Widget _buildBody(BuildContext context, dynamic detail) {
    final isOwner = detail.ownedByMe as bool;
    final isFavorited = detail.isFavorited as bool;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // AppBar
          _buildAppBar(context, isOwner, isFavorited),
          // 지도 (화면 상단 절반)
          Expanded(
            flex: 1,
            child: NaverMap(
              options: const NaverMapViewOptions(
                initialCameraPosition: NCameraPosition(
                  target: NLatLng(36.5, 127.8),
                  zoom: 7,
                ),
                mapType: NMapType.basic,
                activeLayerGroups: [NLayerGroup.building, NLayerGroup.transit],
              ),
              onMapReady: _onMapReady,
            ),
          ),
          // 정보 패널 (화면 하단 절반)
          Expanded(
            flex: 1,
            child: _buildInfoPanel(context, detail),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isOwner, bool isFavorited) {
    return Container(
      height: 56,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E5EA), width: 1),
        ),
      ),
      child: Row(
        children: [
          // 뒤로가기
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 28),
            color: const Color(0xFF007AFF),
            onPressed: () => context.pop(),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
          // 타이틀
          const Expanded(
            child: Text(
              '코스 상세',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1C1C1E),
              ),
            ),
          ),
          // 우측 버튼
          if (!isOwner) ...[
            // 남의 코스: 즐겨찾기 별 토글
            IconButton(
              icon: Text(
                isFavorited ? '⭐' : '☆',
                style: TextStyle(
                  fontSize: 20,
                  color: isFavorited
                      ? const Color(0xFFFFCC00)
                      : const Color(0xFF8E8E93),
                ),
              ),
              onPressed: () => _toggleFavorite(isFavorited),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ],
          // 더보기 메뉴
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF1C1C1E)),
            onSelected: (value) {
              if (value == 'delete') {
                _deleteCourse();
              } else if (value == 'edit' || value == 'copy') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('곧 지원 예정입니다.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            itemBuilder: (_) => [
              if (isOwner) ...[
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 10),
                      Text('코스 편집'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'copy',
                  child: Row(
                    children: [
                      Icon(Icons.copy_outlined, size: 18),
                      SizedBox(width: 10),
                      Text('코스 복사'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      SizedBox(width: 10),
                      Text('삭제', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ] else ...[
                const PopupMenuItem(
                  value: 'copy',
                  child: Row(
                    children: [
                      Icon(Icons.copy_outlined, size: 18),
                      SizedBox(width: 10),
                      Text('내 코스로 복사'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPanel(BuildContext context, dynamic detail) {
    final waypoints = detail.waypoints as List<CourseWaypointResponse>;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return Container(
      color: Colors.white,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding),
        children: [
          // 코스명
          Text(
            detail.name as String,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1C1C1E),
            ),
          ),
          const SizedBox(height: 8),
          // 거리 + 작성자
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  detail.distanceLabel as String,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF007AFF),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _authorLabel(detail.authorNickname as String, detail.ownedByMe as bool),
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF8E8E93),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE5E5EA)),
          const SizedBox(height: 12),
          // 경유지 라벨
          const Text(
            '경유지',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8E8E93),
            ),
          ),
          const SizedBox(height: 10),
          // 경유지 목록
          ...waypoints.indexed.map((entry) {
            final index = entry.$1;
            final wp = entry.$2;
            return _WaypointItem(
              waypoint: wp,
              displayIndex: _viaDisplayIndex(waypoints, index),
            );
          }),
        ],
      ),
    );
  }

  String _authorLabel(String nickname, bool ownedByMe) {
    if (ownedByMe) return '내 코스';
    if (nickname.isEmpty) return '공개 코스';
    return '$nickname · 공개 코스';
  }

  /// VIA 항목의 화면 표시 번호 계산 (START/END는 -1).
  int _viaDisplayIndex(List<CourseWaypointResponse> waypoints, int idx) {
    if (waypoints[idx].role != 'VIA') return -1;
    return waypoints.sublist(0, idx).where((w) => w.role == 'VIA').length + 1;
  }
}

// ── 경유지 아이템 ─────────────────────────────────────────────────────────

class _WaypointItem extends StatelessWidget {
  final CourseWaypointResponse waypoint;
  final int displayIndex; // VIA면 1부터, START/END면 -1

  const _WaypointItem({
    required this.waypoint,
    required this.displayIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // role 도트
          _RoleDot(role: waypoint.role, displayIndex: displayIndex),
          const SizedBox(width: 12),
          // 지점 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _roleLabel(waypoint.role, displayIndex),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8E8E93),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  waypoint.name,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1C1C1E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleDot extends StatelessWidget {
  final String role;
  final int displayIndex;

  const _RoleDot({required this.role, required this.displayIndex});

  @override
  Widget build(BuildContext context) {
    final color = _roleColor(role);
    final text = switch (role) {
      'START' => 'S',
      'END'   => 'E',
      _       => '$displayIndex',
    };

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── 공통 헬퍼 ────────────────────────────────────────────────────────────

Color _roleColor(String role) => switch (role) {
      'START' => _colorStart,
      'END'   => _colorEnd,
      _       => _colorVia,
    };

String _roleLabel(String role, int displayIndex) => switch (role) {
      'START' => '출발지',
      'END'   => '목적지',
      _       => '경유지 $displayIndex',
    };
