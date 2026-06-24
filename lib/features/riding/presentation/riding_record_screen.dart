import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../data/model/gps_point.dart';
import '../domain/riding_provider.dart';

// 라이딩 기록 화면 — GPS 기록 시작/정지 + 실시간 경로 표시
class RidingRecordScreen extends ConsumerStatefulWidget {
  const RidingRecordScreen({super.key});

  @override
  ConsumerState<RidingRecordScreen> createState() => _RidingRecordScreenState();
}

class _RidingRecordScreenState extends ConsumerState<RidingRecordScreen> {
  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    final riding = ref.watch(ridingProvider);
    final isIdle = riding.status == RidingStatus.idle;
    final isRecording = riding.status == RidingStatus.recording;
    final isPaused = riding.status == RidingStatus.paused;

    return Scaffold(
      appBar: AppBar(
        title: const Text('라이딩 기록'),
        actions: [
          if (!isIdle)
            IconButton(
              icon: const Icon(Icons.stop_circle, color: Colors.redAccent),
              tooltip: '기록 종료',
              onPressed: _showStopDialog,
            ),
        ],
      ),
      body: Column(
        children: [
          // 지도
          Expanded(
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(37.5665, 126.9780),
                zoom: 15,
              ),
              onMapCreated: (controller) => _mapController = controller,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: false,
              polylines: _buildPolylines(riding.points),
            ),
          ),
          // 상태 패널
          _StatusPanel(riding: riding),
          // 컨트롤 버튼
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  if (isIdle)
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _startRiding,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('기록 시작'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 56),
                        ),
                      ),
                    ),
                  if (isRecording) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => ref.read(ridingProvider.notifier).pause(),
                        icon: const Icon(Icons.pause_rounded),
                        label: const Text('일시정지'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 56),
                        ),
                      ),
                    ),
                  ],
                  if (isPaused) ...[
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => ref.read(ridingProvider.notifier).resume(),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('재개'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 56),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _showStopDialog,
                        icon: const Icon(Icons.stop_rounded),
                        label: const Text('종료'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          minimumSize: const Size(0, 56),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Set<Polyline> _buildPolylines(List<GpsPoint> points) {
    if (points.length < 2) return {};
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: points.map((p) => LatLng(p.lat, p.lng)).toList(),
        color: const Color(0xFFFF6B35),
        width: 5,
      ),
    };
  }

  Future<void> _startRiding() async {
    try {
      await ref.read(ridingProvider.notifier).start();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  void _showStopDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('라이딩 종료'),
        content: const Text('기록을 종료하고 저장하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _stopAndSave();
            },
            child: const Text('종료 및 저장'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(ridingProvider.notifier).reset();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _stopAndSave() {
    final result = ref.read(ridingProvider.notifier).stop();
    if (result.points.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('기록된 경로가 너무 짧습니다.')),
      );
      ref.read(ridingProvider.notifier).reset();
      return;
    }
    context.push('/riding/save', extra: result);
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

// ─── Status Panel ───────────────────────────────────────────────────────────

class _StatusPanel extends StatelessWidget {
  final RidingState riding;
  const _StatusPanel({required this.riding});

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isIdle = riding.status == RidingStatus.idle;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatColumn(
            label: '시간',
            value: isIdle ? '--:--:--' : _formatDuration(riding.elapsed),
          ),
          _StatColumn(
            label: '거리',
            value: isIdle ? '-.-' : riding.distanceKm.toStringAsFixed(1),
            unit: 'km',
          ),
          _StatColumn(
            label: '속도',
            value: isIdle ? '-' : riding.currentSpeedKmh.toStringAsFixed(0),
            unit: 'km/h',
          ),
          _StatColumn(
            label: '최고속도',
            value: isIdle ? '-' : riding.maxSpeedKmh.toStringAsFixed(0),
            unit: 'km/h',
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;

  const _StatColumn({required this.label, required this.value, this.unit});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1B2838),
              ),
            ),
            if (unit != null) ...[
              const SizedBox(width: 2),
              Text(
                unit!,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
