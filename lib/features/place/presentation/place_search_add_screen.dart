import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/model/place_candidate.dart';
import '../data/model/place_category.dart';
import '../data/repository/place_repository.dart';
import '../domain/place_provider.dart';

/// Naver 지역검색으로 후보를 찾아 place로 등록하는 화면.
/// 두 단계 stepper:
///   1) 검색 → 결과 리스트에서 선택
///   2) 지도 크로스헤어로 좌표 보정 + 이름/카테고리 확정 → 저장
class PlaceSearchAddScreen extends ConsumerStatefulWidget {
  const PlaceSearchAddScreen({super.key});

  @override
  ConsumerState<PlaceSearchAddScreen> createState() =>
      _PlaceSearchAddScreenState();
}

class _PlaceSearchAddScreenState extends ConsumerState<PlaceSearchAddScreen> {
  PlaceCandidate? _selected;

  void _onSelect(PlaceCandidate candidate) {
    setState(() => _selected = candidate);
  }

  void _onBack() {
    setState(() => _selected = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selected == null ? '네이버로 장소 검색' : '위치 및 정보 확인'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () {
            if (_selected != null) {
              _onBack();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: _selected == null
          ? _SearchStep(onSelect: _onSelect)
          : _ConfirmStep(candidate: _selected!),
    );
  }
}

/// 1단계 — 검색어 입력 + 결과 리스트.
class _SearchStep extends ConsumerStatefulWidget {
  final void Function(PlaceCandidate) onSelect;
  const _SearchStep({required this.onSelect});

  @override
  ConsumerState<_SearchStep> createState() => _SearchStepState();
}

class _SearchStepState extends ConsumerState<_SearchStep> {
  static const _accentColor = Color(0xFF007AFF);
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';
  List<PlaceCandidate>? _results;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final trimmed = value.trim();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      if (trimmed.isEmpty) {
        setState(() {
          _query = '';
          _results = null;
          _loading = false;
          _error = null;
        });
        return;
      }
      setState(() => _query = trimmed);
      _fetch(trimmed);
    });
  }

  Future<void> _fetch(String query) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list =
          await ref.read(placeRepositoryProvider).searchExternal(query);
      if (!mounted || query != _query) return; // 사용자가 그 사이 입력을 바꿈
      setState(() {
        _results = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '검색 실패';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 검색창
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Material(
            color: const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(12),
            child: TextField(
              controller: _controller,
              onChanged: _onChanged,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '장소명 검색 (예: 남산타워, 진주 카페)',
                hintStyle: const TextStyle(
                    color: Color(0xFF8E8E93), fontSize: 14),
                prefixIcon: const Icon(Icons.search,
                    color: _accentColor, size: 20),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: Color(0xFF8E8E93), size: 18),
                        onPressed: () {
                          _controller.clear();
                          _onChanged('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    if (_query.isEmpty && _results == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            '장소명을 입력하면 네이버에서 검색합니다.\n검색 결과의 좌표를 앱 지도에서 미세 조정하고 저장할 수 있어요.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93), height: 1.5),
          ),
        ),
      );
    }
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Text(_error!,
            style:
                const TextStyle(fontSize: 13, color: Color(0xFFFF3B30))),
      );
    }
    final list = _results ?? const [];
    if (list.isEmpty) {
      return const Center(
        child: Text('검색 결과 없음',
            style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93))),
      );
    }
    return ListView.separated(
      itemCount: list.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, color: Color(0xFFEFEFF4)),
      itemBuilder: (_, i) {
        final c = list[i];
        return InkWell(
          onTap: () => widget.onSelect(c),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1C1C1E),
                  ),
                ),
                if (c.naverCategory != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    c.naverCategory!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: _accentColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                if (c.roadAddress != null || c.address != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    c.roadAddress ?? c.address!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 2단계 — 크로스헤어로 좌표 보정 + 이름/카테고리 확정 + 저장.
class _ConfirmStep extends ConsumerStatefulWidget {
  final PlaceCandidate candidate;
  const _ConfirmStep({required this.candidate});

  @override
  ConsumerState<_ConfirmStep> createState() => _ConfirmStepState();
}

class _ConfirmStepState extends ConsumerState<_ConfirmStep> {
  static const _accentColor = Color(0xFF007AFF);

  NaverMapController? _mapController;
  late NLatLng _center;
  late final TextEditingController _nameController;
  PlaceCategory _category = PlaceCategory.other; // Naver 카테고리는 임의라 기본 '기타'
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _center = NLatLng(widget.candidate.latitude, widget.candidate.longitude);
    _nameController = TextEditingController(text: widget.candidate.name);
    _category = _guessCategory(widget.candidate.naverCategory);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Naver의 카테고리 문자열로 우리 5개 카테고리 대충 추정.
  /// 확실치 않은 건 OTHER로. 사용자가 UI에서 최종 결정.
  PlaceCategory _guessCategory(String? naverCategory) {
    if (naverCategory == null) return PlaceCategory.other;
    final s = naverCategory;
    if (s.contains('카페') || s.contains('디저트')) return PlaceCategory.cafe;
    if (s.contains('음식') || s.contains('식당') || s.contains('한식') ||
        s.contains('일식') || s.contains('중식') || s.contains('양식')) {
      return PlaceCategory.restaurant;
    }
    if (s.contains('정비') || s.contains('센터') || s.contains('수리')) {
      return PlaceCategory.service;
    }
    if (s.contains('명소') || s.contains('관광') || s.contains('전망') ||
        s.contains('공원')) {
      return PlaceCategory.famous;
    }
    return PlaceCategory.other;
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이름을 입력해주세요')),
      );
      return;
    }
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(placeRepositoryProvider).create(
            name: name,
            category: _category,
            latitude: _center.latitude,
            longitude: _center.longitude,
            address: widget.candidate.address,
            roadAddress: widget.candidate.roadAddress,
          );
      ref.invalidate(allPlacesProvider);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('저장 실패: ${e.response?.statusCode ?? '네트워크 오류'}'),
          backgroundColor: const Color(0xFFFF3B30),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        NaverMap(
          options: NaverMapViewOptions(
            initialCameraPosition: NCameraPosition(target: _center, zoom: 17),
            locationButtonEnable: true,
          ),
          onMapReady: (controller) => _mapController = controller,
          onCameraChange: (reason, animated) async {
            final controller = _mapController;
            if (controller == null) return;
            final pos = await controller.getCameraPosition();
            setState(() => _center = pos.target);
          },
        ),
        const IgnorePointer(
          child: Center(
            child: Icon(Icons.add, size: 44, color: _accentColor),
          ),
        ),
        // 상단 좌표 안내
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: Card(
            color: Colors.white,
            elevation: 3,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.my_location,
                      size: 14, color: _accentColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${_center.latitude.toStringAsFixed(7)},  ${_center.longitude.toStringAsFixed(7)}',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1C1C1E)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // 하단 폼
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, -2)),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.candidate.roadAddress != null ||
                      widget.candidate.address != null) ...[
                    Text(
                      widget.candidate.roadAddress ??
                          widget.candidate.address!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Wrap(
                    spacing: 6,
                    children: PlaceCategory.values.map((cat) {
                      final selected = _category == cat;
                      return ChoiceChip(
                        label: Text('${cat.icon} ${cat.label}'),
                        selected: selected,
                        onSelected: (_) => setState(() => _category = cat),
                        selectedColor: _accentColor.withValues(alpha: 0.15),
                        side: BorderSide(
                            color:
                                selected ? _accentColor : Colors.black26),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? _accentColor
                              : const Color(0xFF1C1C1E),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _nameController,
                    decoration: _fieldDecoration('이름 *'),
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('저장',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      isDense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.black26),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.black26),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _accentColor),
      ),
    );
  }
}
