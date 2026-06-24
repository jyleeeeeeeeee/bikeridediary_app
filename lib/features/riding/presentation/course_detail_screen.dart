import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/model/gps_point.dart';
import '../domain/course_provider.dart';

// 코스 상세 화면 — 경로 지도 + 통계 + 외부 앱 공유
class CourseDetailScreen extends ConsumerWidget {
  final String courseId;
  const CourseDetailScreen({super.key, required this.courseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courseAsync = ref.watch(courseDetailProvider(courseId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('라이딩 상세'),
        actions: [
          courseAsync.whenOrNull(
            data: (course) => IconButton(
              icon: const Icon(Icons.share_rounded),
              tooltip: '경로 공유',
              onPressed: () => _showShareDialog(context, course.points),
            ),
          ) ?? const SizedBox.shrink(),
        ],
      ),
      body: courseAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (course) {
          final points = course.points.map((p) => LatLng(p.lat, p.lng)).toList();
          return Column(
            children: [
              // 지도
              Expanded(
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: points.isNotEmpty
                        ? points[points.length ~/ 2]
                        : const LatLng(37.5665, 126.9780),
                    zoom: 13,
                  ),
                  polylines: points.length >= 2
                      ? {
                          Polyline(
                            polylineId: const PolylineId('route'),
                            points: points,
                            color: const Color(0xFFFF6B35),
                            width: 5,
                          ),
                        }
                      : {},
                  markers: _buildMarkers(points),
                  myLocationEnabled: false,
                  zoomControlsEnabled: true,
                ),
              ),
              // 통계
              Container(
                padding: const EdgeInsets.all(20),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1B2838),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      course.startedAt.substring(0, 10),
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    ),
                    if (course.memo != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        course.memo!,
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _Stat(Icons.straighten, '거리', '${course.distanceKm.toStringAsFixed(1)} km'),
                        _Stat(Icons.timer, '시간', _formatDuration(course.durationSeconds)),
                        _Stat(Icons.speed, '평균', '${course.avgSpeedKmh?.toStringAsFixed(0) ?? "-"} km/h'),
                        _Stat(Icons.flash_on, '최고', '${course.maxSpeedKmh?.toStringAsFixed(0) ?? "-"} km/h'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Set<Marker> _buildMarkers(List<LatLng> points) {
    if (points.isEmpty) return {};
    final markers = <Marker>{};
    markers.add(Marker(
      markerId: const MarkerId('start'),
      position: points.first,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: const InfoWindow(title: '출발'),
    ));
    if (points.length > 1) {
      markers.add(Marker(
        markerId: const MarkerId('end'),
        position: points.last,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: '도착'),
      ));
    }
    return markers;
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}시간 ${m}분';
    return '${m}분';
  }

  // 외부 지도 앱으로 경로 공유
  void _showShareDialog(BuildContext context, List<GpsPoint> points) {
    if (points.length < 2) return;

    // 경유지 샘플링: 최대 3개 (카카오 제한에 맞춤)
    final start = points.first;
    final end = points.last;
    final waypoints = _sampleWaypoints(points, 3);

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '경로 공유',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.map, color: Color(0xFF03C75A)),
              title: const Text('네이버 지도'),
              onTap: () {
                Navigator.pop(ctx);
                _openNaverMap(start, end, waypoints);
              },
            ),
            ListTile(
              leading: const Icon(Icons.map, color: Color(0xFFFEE500)),
              title: const Text('카카오맵'),
              onTap: () {
                Navigator.pop(ctx);
                _openKakaoMap(start, end, waypoints);
              },
            ),
          ],
        ),
      ),
    );
  }

  // 균등 간격으로 경유지 샘플링
  List<GpsPoint> _sampleWaypoints(List<GpsPoint> points, int count) {
    if (points.length <= 2) return [];
    final result = <GpsPoint>[];
    final step = points.length / (count + 1);
    for (int i = 1; i <= count; i++) {
      final idx = (step * i).round().clamp(1, points.length - 2);
      result.add(points[idx]);
    }
    return result;
  }

  Future<void> _openNaverMap(GpsPoint start, GpsPoint end, List<GpsPoint> waypoints) async {
    // nmap://route/car?slat=&slng=&sname=출발&elat=&elng=&ename=도착&v1lat=&v1lng=&...
    final params = StringBuffer();
    params.write('slat=${start.lat}&slng=${start.lng}&sname=출발');
    params.write('&elat=${end.lat}&elng=${end.lng}&ename=도착');
    for (int i = 0; i < waypoints.length; i++) {
      final w = waypoints[i];
      params.write('&v${i + 1}lat=${w.lat}&v${i + 1}lng=${w.lng}&v${i + 1}name=경유${i + 1}');
    }
    params.write('&appname=com.bikeridediary.brd_app');

    final url = Uri.parse('nmap://route/car?$params');
    final fallback = Uri.parse('market://details?id=com.nhn.android.nmap');

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      await launchUrl(fallback);
    }
  }

  Future<void> _openKakaoMap(GpsPoint start, GpsPoint end, List<GpsPoint> waypoints) async {
    // kakaomap://route?sp=lat,lng&ep=lat,lng&by=lat,lng
    final params = StringBuffer();
    params.write('sp=${start.lat},${start.lng}');
    params.write('&ep=${end.lat},${end.lng}');
    if (waypoints.isNotEmpty) {
      final byParam = waypoints.map((w) => '${w.lat},${w.lng}').join(',');
      params.write('&by=$byParam');
    }

    final url = Uri.parse('kakaomap://route?$params');
    final fallback = Uri.parse('market://details?id=net.daum.android.map');

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      await launchUrl(fallback);
    }
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _Stat(this.icon, this.label, this.value);

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
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1B2838),
          ),
        ),
      ],
    );
  }
}
