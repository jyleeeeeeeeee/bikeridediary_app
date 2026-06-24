import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../bike/domain/bike_provider.dart';
import '../data/model/course_create_request.dart';
import '../data/repository/course_repository.dart';
import '../domain/course_provider.dart';
import '../domain/riding_provider.dart';

// 라이딩 종료 후 저장 화면 — 경로 미리보기 + 제목/메모 입력
class RidingSaveScreen extends ConsumerStatefulWidget {
  final RidingState ridingResult;
  const RidingSaveScreen({super.key, required this.ridingResult});

  @override
  ConsumerState<RidingSaveScreen> createState() => _RidingSaveScreenState();
}

class _RidingSaveScreenState extends ConsumerState<RidingSaveScreen> {
  final _titleCtl = TextEditingController();
  final _memoCtl = TextEditingController();
  String? _selectedBikeId;
  bool _isLoading = false;

  RidingState get _result => widget.ridingResult;

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return '${h}시간 ${m}분';
    return '$m분';
  }

  @override
  void initState() {
    super.initState();
    _titleCtl.text =
        '${_result.startedAt?.month}/${_result.startedAt?.day} 라이딩';
  }

  @override
  void dispose() {
    _titleCtl.dispose();
    _memoCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bikesAsync = ref.watch(bikeListProvider);

    if (_selectedBikeId == null && bikesAsync.hasValue && bikesAsync.value!.isNotEmpty) {
      final bikes = bikesAsync.value!;
      _selectedBikeId = bikes.firstWhereOrNull((b) => b.isRepresentative)?.id ?? bikes.first.id;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('라이딩 저장')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 경로 미리보기
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 200,
                child: GoogleMap(
                  initialCameraPosition: _initialCamera(),
                  polylines: _buildPolylines(),
                  myLocationEnabled: false,
                  zoomControlsEnabled: false,
                  scrollGesturesEnabled: false,
                  rotateGesturesEnabled: false,
                  tiltGesturesEnabled: false,
                  zoomGesturesEnabled: false,
                  liteModeEnabled: true,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 주행 요약
            _SummaryRow(result: _result, formatDuration: _formatDuration),
            const SizedBox(height: 20),
            // 바이크 선택
            bikesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('바이크 로드 실패: $e'),
              data: (bikes) => DropdownButtonFormField<String>(
                initialValue: _selectedBikeId,
                decoration: const InputDecoration(
                  labelText: '바이크',
                  prefixIcon: Icon(Icons.two_wheeler),
                ),
                items: bikes
                    .map((b) => DropdownMenuItem(value: b.id, child: Text(b.displayName)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedBikeId = v),
              ),
            ),
            const SizedBox(height: 16),
            // 제목
            TextFormField(
              controller: _titleCtl,
              decoration: const InputDecoration(
                labelText: '제목',
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 16),
            // 메모
            TextFormField(
              controller: _memoCtl,
              decoration: const InputDecoration(
                labelText: '메모 (선택)',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            // 저장
            FilledButton(
              onPressed: _isLoading ? null : _save,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }

  CameraPosition _initialCamera() {
    if (_result.points.isEmpty) {
      return const CameraPosition(target: LatLng(37.5665, 126.9780), zoom: 15);
    }
    final mid = _result.points[_result.points.length ~/ 2];
    return CameraPosition(target: LatLng(mid.lat, mid.lng), zoom: 13);
  }

  Set<Polyline> _buildPolylines() {
    if (_result.points.length < 2) return {};
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: _result.points.map((p) => LatLng(p.lat, p.lng)).toList(),
        color: const Color(0xFFFF6B35),
        width: 4,
      ),
    };
  }

  Future<void> _save() async {
    if (_selectedBikeId == null || _titleCtl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('바이크와 제목을 입력해주세요.')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final request = CourseCreateRequest(
        bikeId: _selectedBikeId!,
        title: _titleCtl.text.trim(),
        memo: _memoCtl.text.trim().isEmpty ? null : _memoCtl.text.trim(),
        startedAt: _result.startedAt!.toIso8601String(),
        endedAt: _result.startedAt!.add(_result.elapsed).toIso8601String(),
        durationSeconds: _result.elapsed.inSeconds,
        distanceKm: _result.distanceKm,
        avgSpeedKmh: _result.avgSpeedKmh,
        maxSpeedKmh: _result.maxSpeedKmh,
        points: _result.points,
      );
      await ref.read(courseRepositoryProvider).createCourse(request);
      ref.invalidate(courseListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('라이딩 코스가 저장되었습니다.')),
        );
        context.go('/riding');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _SummaryRow extends StatelessWidget {
  final RidingState result;
  final String Function(Duration) formatDuration;

  const _SummaryRow({required this.result, required this.formatDuration});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2838).withAlpha(13),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryItem(
            icon: Icons.straighten,
            label: '거리',
            value: '${result.distanceKm.toStringAsFixed(1)} km',
          ),
          _SummaryItem(
            icon: Icons.timer,
            label: '시간',
            value: formatDuration(result.elapsed),
          ),
          _SummaryItem(
            icon: Icons.speed,
            label: '평균',
            value: '${result.avgSpeedKmh.toStringAsFixed(0)} km/h',
          ),
          _SummaryItem(
            icon: Icons.flash_on,
            label: '최고',
            value: '${result.maxSpeedKmh.toStringAsFixed(0)} km/h',
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: const Color(0xFFFF6B35)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1B2838),
          ),
        ),
      ],
    );
  }
}
