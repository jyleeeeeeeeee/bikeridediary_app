import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../data/model/maintenance_type.dart';
import '../domain/maintenance_provider.dart';

String _fmt(num n) => n
    .toString()
    .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

class MaintenanceListScreen extends ConsumerStatefulWidget {
  final String bikeId;

  const MaintenanceListScreen({super.key, required this.bikeId});

  @override
  ConsumerState<MaintenanceListScreen> createState() => _MaintenanceListScreenState();
}

class _MaintenanceListScreenState extends ConsumerState<MaintenanceListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            title: const Text('정비 관리'),
            pinned: true,
            floating: true,
            forceElevated: innerBoxIsScrolled,
            expandedHeight: 100,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: AppTheme.headerGradient),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: '정비 기록'),
                Tab(text: '정비 주기'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _MaintenanceTab(bikeId: widget.bikeId),
            _ScheduleTab(bikeId: widget.bikeId),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            context.push('/bikes/${widget.bikeId}/maintenances/new');
          } else {
            context.push('/bikes/${widget.bikeId}/schedules/new');
          }
        },
        tooltip: _tabController.index == 0 ? '정비 기록 추가' : '정비 주기 추가',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _MaintenanceTab extends ConsumerWidget {
  final String bikeId;

  const _MaintenanceTab({required this.bikeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maintenancesAsync = ref.watch(maintenanceListProvider(bikeId));

    return maintenancesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('오류: $e')),
      data: (maintenances) {
        if (maintenances.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B2838).withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.build_rounded, size: 36, color: Color(0xFF1B2838)),
                ),
                const SizedBox(height: 16),
                const Text(
                  '정비 기록이 없습니다',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B2838),
                  ),
                ),
                const SizedBox(height: 6),
                Text('정비 기록을 추가해보세요', style: TextStyle(color: Colors.grey[500])),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref.refresh(maintenanceListProvider(bikeId).future),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            itemCount: maintenances.length,
            itemBuilder: (context, index) {
              final m = maintenances[index];
              final type = MaintenanceType.values.firstWhere(
                (t) => t.name == m.maintenanceType,
                orElse: () => MaintenanceType.OTHER,
              );
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 5),
                child: InkWell(
                  onTap: () => context.push('/bikes/$bikeId/maintenances/${m.id}'),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B2838).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.build_rounded, size: 20, color: Color(0xFF1B2838)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                type.displayName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1B2838),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Wrap(
                                spacing: 10,
                                runSpacing: 2,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.calendar_today, size: 12, color: Colors.grey[500]),
                                      const SizedBox(width: 4),
                                      Text(
                                        m.maintenanceDate,
                                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.speed, size: 12, color: Colors.grey[500]),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${_fmt(m.mileageAtMaintenance)} km',
                                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (m.cost != null)
                          Text(
                            '${_fmt(m.cost!)}원',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1B2838),
                            ),
                          ),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey[400]),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _ScheduleTab extends ConsumerWidget {
  final String bikeId;

  const _ScheduleTab({required this.bikeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedulesAsync = ref.watch(scheduleListProvider(bikeId));

    return schedulesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('오류: $e')),
      data: (schedules) {
        if (schedules.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35).withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.schedule_rounded, size: 36, color: Color(0xFFFF6B35)),
                ),
                const SizedBox(height: 16),
                const Text(
                  '설정된 정비 주기가 없습니다',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B2838),
                  ),
                ),
                const SizedBox(height: 6),
                Text('정비 주기를 설정하면 알림을 받을 수 있어요', style: TextStyle(color: Colors.grey[500])),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () => context.push('/bikes/$bikeId/schedules/new'),
                  icon: const Icon(Icons.add),
                  label: const Text('정비 주기 추가'),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
          itemCount: schedules.length,
          itemBuilder: (context, index) {
            final s = schedules[index];
            final type = MaintenanceType.values.firstWhere(
              (t) => t.name == s.maintenanceType,
              orElse: () => MaintenanceType.OTHER,
            );
            final intervals = [
              if (s.intervalKm != null) '${_fmt(s.intervalKm!)} km마다',
              if (s.intervalMonths != null) '${s.intervalMonths}개월마다',
            ].join(' / ');

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 5),
              child: InkWell(
                onTap: () => context.push('/bikes/$bikeId/schedules/${s.id}'),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: s.overdue
                              ? Colors.red.shade50
                              : const Color(0xFFFF6B35).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          s.overdue ? Icons.warning_amber_rounded : Icons.schedule_rounded,
                          size: 20,
                          color: s.overdue ? Colors.redAccent : const Color(0xFFFF6B35),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              type.displayName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1B2838),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              intervals,
                              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                      if (s.overdue)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: const Text(
                            '정비 필요',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      else
                        Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey[400]),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
