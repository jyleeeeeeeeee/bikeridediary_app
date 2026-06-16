import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/model/maintenance_type.dart';
import '../domain/maintenance_provider.dart';

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
    final maintenancesAsync = ref.watch(maintenanceListProvider(widget.bikeId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('정비 관리'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '정비 기록'),
            Tab(text: '정비 주기'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          maintenancesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('오류: $e')),
            data: (maintenances) {
              if (maintenances.isEmpty) {
                return const Center(child: Text('정비 기록이 없습니다'));
              }
              return RefreshIndicator(
                onRefresh: () => ref.refresh(maintenanceListProvider(widget.bikeId).future),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: maintenances.length,
                  itemBuilder: (context, index) {
                    final m = maintenances[index];
                    final type = MaintenanceType.values.firstWhere(
                      (t) => t.name == m.maintenanceType,
                      orElse: () => MaintenanceType.OTHER,
                    );
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.edit_note),
                        title: Text(type.displayName),
                        subtitle: Text(
                          '${m.maintenanceDate} · ${m.mileageAtMaintenance}km'
                          '${m.cost != null ? ' · ${m.cost}원' : ''}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(
                          '/bikes/${widget.bikeId}/maintenances/${m.id}',
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          _ScheduleTab(bikeId: widget.bikeId),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            context.push('/bikes/${widget.bikeId}/maintenances/new');
          } else {
            context.push('/bikes/${widget.bikeId}/schedules/new');
          }
        },
        child: const Icon(Icons.add),
      ),
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
                const Text('설정된 정비 주기가 없습니다'),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => context.push('/bikes/$bikeId/schedules/new'),
                  child: const Text('정비 주기 추가'),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: schedules.length,
          itemBuilder: (context, index) {
            final s = schedules[index];
            final type = MaintenanceType.values.firstWhere(
              (t) => t.name == s.maintenanceType,
              orElse: () => MaintenanceType.OTHER,
            );
            return Card(
              color: s.overdue ? Colors.red.shade50 : null,
              child: ListTile(
                leading: Icon(
                  s.overdue ? Icons.warning : Icons.schedule,
                  color: s.overdue ? Colors.red : null,
                ),
                title: Text(type.displayName),
                subtitle: Text(
                  [
                    if (s.intervalKm != null) '${s.intervalKm}km마다',
                    if (s.intervalMonths != null) '${s.intervalMonths}개월마다',
                  ].join(' / '),
                ),
                trailing: s.overdue
                    ? const Text('정비 필요',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
                    : const Icon(Icons.chevron_right),
                onTap: () => context.push('/bikes/$bikeId/schedules/${s.id}'),
              ),
            );
          },
        );
      },
    );
  }
}
