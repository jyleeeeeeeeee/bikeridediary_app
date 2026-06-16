import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/domain/auth_provider.dart';
import '../../bike/data/model/bike_category.dart';
import '../../bike/domain/bike_provider.dart';
import '../../maintenance/domain/maintenance_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bikesAsync = ref.watch(bikeListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('바라다'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: bikesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('오류: $e'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(bikeListProvider),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
        data: (bikes) {
          if (bikes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.two_wheeler, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('바이크를 등록해주세요'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => context.push('/bikes/new'),
                    icon: const Icon(Icons.add),
                    label: const Text('바이크 등록'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(bikeListProvider.future),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 대표 바이크 or 첫 번째 바이크 요약
                _BikeCard(
                  bike: bikes.firstWhere((b) => b.isRepresentative, orElse: () => bikes.first),
                ),
                const SizedBox(height: 16),
                // 정비 필요 알림
                _OverdueSection(
                  bikeId: bikes.firstWhere((b) => b.isRepresentative, orElse: () => bikes.first).id,
                ),
                const SizedBox(height: 16),
                // 빠른 메뉴
                Row(
                  children: [
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.two_wheeler,
                        label: '바이크 목록',
                        onTap: () => context.push('/bikes'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.build,
                        label: '정비 기록',
                        onTap: () {
                          final bike = bikes.firstWhere(
                            (b) => b.isRepresentative,
                            orElse: () => bikes.first,
                          );
                          context.push('/bikes/${bike.id}/maintenances');
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // 전체 바이크 목록
                if (bikes.length > 1) ...[
                  Text('내 바이크', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...bikes.map((bike) {
                    final category = BikeCategory.values.firstWhere(
                      (c) => c.name == bike.category,
                      orElse: () => BikeCategory.OTHER,
                    );
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.two_wheeler),
                        title: Text(bike.displayName),
                        subtitle: Text('${category.displayName} · ${bike.totalMileageKm}km'),
                        trailing: bike.isRepresentative
                            ? Icon(Icons.star, color: Theme.of(context).colorScheme.primary)
                            : null,
                        onTap: () => context.push('/bikes/${bike.id}'),
                      ),
                    );
                  }),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BikeCard extends StatelessWidget {
  final dynamic bike;

  const _BikeCard({required this.bike});

  @override
  Widget build(BuildContext context) {
    final category = BikeCategory.values.firstWhere(
      (c) => c.name == bike.category,
      orElse: () => BikeCategory.OTHER,
    );
    return Card(
      child: InkWell(
        onTap: () => context.push('/bikes/${bike.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.two_wheeler, size: 32, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(bike.displayName, style: Theme.of(context).textTheme.titleMedium),
                        Text(category.displayName, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.speed, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${bike.totalMileageKm} km'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverdueSection extends ConsumerWidget {
  final String bikeId;

  const _OverdueSection({required this.bikeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedulesAsync = ref.watch(scheduleListProvider(bikeId));

    return schedulesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (schedules) {
        final overdue = schedules.where((s) => s.overdue).toList();
        if (overdue.isEmpty) return const SizedBox.shrink();

        return Card(
          color: Colors.red.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(
                      '정비 필요 (${overdue.length}건)',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...overdue.map((s) {
                  final typeName = s.maintenanceType;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text('· $typeName'),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}
