import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_bike_view.dart';
import '../../bike/domain/bike_provider.dart';
import '../data/model/course_response.dart';
import '../domain/course_provider.dart';

// 라이딩 코스 목록 화면
class CourseListScreen extends ConsumerStatefulWidget {
  const CourseListScreen({super.key});

  @override
  ConsumerState<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends ConsumerState<CourseListScreen> {
  String? _selectedBikeId;
  bool _didInit = false;

  @override
  Widget build(BuildContext context) {
    final bikesAsync = ref.watch(bikeListProvider);

    if (!_didInit && bikesAsync.hasValue && bikesAsync.value!.isNotEmpty) {
      _didInit = true;
      final bikes = bikesAsync.value!;
      final rep = bikes.where((b) => b.isRepresentative).firstOrNull ?? bikes.first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selectedBikeId == null) {
          setState(() => _selectedBikeId = rep.id);
        }
      });
    }

    return Scaffold(
      body: bikesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (bikes) {
          if (bikes.isEmpty) return const EmptyBikeView();
          final bikeId = _selectedBikeId ?? bikes.first.id;
          return _CourseListBody(
            bikes: bikes,
            selectedBikeId: bikeId,
            onBikeChanged: (id) => setState(() => _selectedBikeId = id),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/riding/record'),
        tooltip: '라이딩 기록',
        child: const Icon(Icons.play_arrow_rounded),
      ),
    );
  }
}

class _CourseListBody extends ConsumerWidget {
  final List bikes;
  final String selectedBikeId;
  final ValueChanged<String> onBikeChanged;

  const _CourseListBody({
    required this.bikes,
    required this.selectedBikeId,
    required this.onBikeChanged,
  });

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}시간 ${m}분';
    return '${m}분';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(courseListProvider(selectedBikeId));

    return NestedScrollView(
      headerSliverBuilder: (context, _) => [
        SliverAppBar(
          title: const Text('라이딩 코스'),
          pinned: true,
          expandedHeight: 140,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(gradient: AppTheme.headerGradient),
              padding: const EdgeInsets.fromLTRB(20, 80, 20, 16),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(Icons.route_rounded, size: 32, color: Colors.white),
                  SizedBox(width: 10),
                  Text(
                    '나의 라이딩',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
      body: Column(
        children: [
          // 바이크 선택
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.two_wheeler, size: 18, color: Color(0xFF1B2838)),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedBikeId,
                      isExpanded: true,
                      isDense: true,
                      style: const TextStyle(
                        color: Color(0xFF1B2838),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      items: bikes.map<DropdownMenuItem<String>>((b) {
                        return DropdownMenuItem(
                          value: b.id as String,
                          child: Text(b.displayName as String),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) onBikeChanged(v);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 코스 목록
          Expanded(
            child: coursesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('오류: $e')),
              data: (courses) {
                if (courses.isEmpty) return const _EmptyCourseView();
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.refresh(courseListProvider(selectedBikeId).future),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: courses.length,
                    itemBuilder: (context, index) {
                      final course = courses[index];
                      return _CourseCard(
                        course: course,
                        formatDuration: _formatDuration,
                        onTap: () => context.push('/riding/${course.id}'),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final CourseResponse course;
  final String Function(int) formatDuration;
  final VoidCallback onTap;

  const _CourseCard({
    required this.course,
    required this.formatDuration,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      course.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B2838),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 20),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                course.startedAt.substring(0, 10),
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _InfoChip(Icons.straighten, '${course.distanceKm.toStringAsFixed(1)} km'),
                  const SizedBox(width: 12),
                  _InfoChip(Icons.timer, formatDuration(course.durationSeconds)),
                  const SizedBox(width: 12),
                  if (course.avgSpeedKmh != null)
                    _InfoChip(Icons.speed, '${course.avgSpeedKmh!.toStringAsFixed(0)} km/h'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoChip(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFFFF6B35)),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700]),
        ),
      ],
    );
  }
}

class _EmptyCourseView extends StatelessWidget {
  const _EmptyCourseView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35).withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.route_rounded, size: 40, color: Color(0xFFFF6B35)),
          ),
          const SizedBox(height: 20),
          const Text(
            '라이딩 기록이 없습니다',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1B2838)),
          ),
          const SizedBox(height: 8),
          Text(
            '라이딩을 시작해보세요!',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
