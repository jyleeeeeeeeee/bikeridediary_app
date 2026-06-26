import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../data/model/bike_category.dart';
import '../data/model/bike_response.dart';
import '../domain/bike_provider.dart';
import '../../maintenance/domain/maintenance_provider.dart';
import '../../fueling/domain/fueling_provider.dart';

String _fmt(num n) => n
    .toString()
    .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

class BikeDetailScreen extends ConsumerWidget {
  final String bikeId;

  const BikeDetailScreen({super.key, required this.bikeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bikeAsync = ref.watch(bikeDetailProvider(bikeId));

    return Scaffold(
      body: bikeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (bike) => _BikeDetailBody(bike: bike, bikeId: bikeId),
      ),
    );
  }
}

class _BikeDetailBody extends ConsumerWidget {
  final BikeResponse bike;
  final String bikeId;

  const _BikeDetailBody({required this.bike, required this.bikeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryName = BikeTypeDisplay.displayName(bike.category);

    final schedulesAsync = ref.watch(scheduleListProvider(bikeId));
    final fuelingStatsAsync = ref.watch(fuelingStatsProvider(bikeId));

    final overdueCount = schedulesAsync.whenOrNull(
          data: (list) => list.where((s) => s.overdue).length,
        ) ?? 0;

    final avgEfficiency = fuelingStatsAsync.whenOrNull(
      data: (stats) => stats.averageFuelEfficiency,
    );

    return RefreshIndicator(
      onRefresh: () {
        ref.invalidate(bikeDetailProvider(bikeId));
        ref.invalidate(scheduleListProvider(bikeId));
        ref.invalidate(fuelingStatsProvider(bikeId));
        return ref.read(bikeDetailProvider(bikeId).future);
      },
      child: CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) async {
                switch (value) {
                  case 'edit':
                    context.push('/bikes/$bikeId/edit', extra: bike);
                    break;
                  case 'representative':
                    await ref.read(bikeListProvider.notifier).setRepresentative(bikeId);
                    break;
                  case 'delete':
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('바이크 삭제'),
                        content: const Text('이 바이크와 관련된 모든 기록이 삭제됩니다.\n정말 삭제하시겠습니까?'),
                        actions: [
                          TextButton(onPressed: () => ctx.pop(false), child: const Text('취소')),
                          TextButton(
                            onPressed: () => ctx.pop(true),
                            child: const Text('삭제', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true && context.mounted) {
                      await ref.read(bikeListProvider.notifier).delete(bikeId);
                      ref.invalidate(fuelingListProvider(bikeId));
                      ref.invalidate(fuelingStatsProvider(bikeId));
                      ref.invalidate(maintenanceListProvider(bikeId));
                      ref.invalidate(scheduleListProvider(bikeId));
                      if (context.mounted) context.pop();
                    }
                    break;
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('수정')),
                const PopupMenuItem(value: 'representative', child: Text('메인 바이크 설정')),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('삭제', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(gradient: AppTheme.headerGradient),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: AppTheme.accentGradient,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.two_wheeler,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        bike.displayName,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (bike.isRepresentative) ...[
                                      const SizedBox(width: 8),
                                      const Icon(Icons.star_rounded,
                                          size: 18, color: Color(0xFF007AFF)),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$categoryName · ${bike.year}년식',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Stats row
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.speed_rounded,
                      label: '총 주행거리',
                      value: _fmt(bike.totalMileageKm),
                      unit: 'km',
                      iconColor: const Color(0xFF1C1C1E),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.local_gas_station_rounded,
                      label: '평균 연비',
                      value: avgEfficiency != null
                          ? avgEfficiency.toStringAsFixed(1)
                          : '--',
                      unit: 'km/L',
                      iconColor: const Color(0xFF007AFF),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.build_rounded,
                      label: '정비 필요',
                      value: overdueCount.toString(),
                      unit: '건',
                      iconColor: overdueCount > 0
                          ? Colors.redAccent
                          : const Color(0xFF1C1C1E),
                      valueColor: overdueCount > 0 ? Colors.redAccent : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Info section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '바이크 정보',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1C1C1E),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _InfoRow(label: '제조사', value: bike.manufacturerName),
                      _InfoRow(label: '모델', value: bike.modelName),
                      _InfoRow(label: '연식', value: '${bike.year}년'),
                      _InfoRow(label: '카테고리', value: categoryName),
                      if (bike.purchasedAt != null)
                        _InfoRow(label: '구매일', value: bike.purchasedAt!),
                      _InfoRow(label: '등록일', value: bike.createdAt.substring(0, 10)),
                      if (bike.memo != null && bike.memo!.isNotEmpty)
                        _InfoRow(label: '메모', value: bike.memo!),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Quick actions
              const Text(
                '관리',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1C1C1E),
                ),
              ),
              const SizedBox(height: 10),
              _ActionTile(
                icon: Icons.build_rounded,
                iconColor: const Color(0xFF1C1C1E),
                label: '정비 기록',
                subtitle: '교체 이력 및 정비 스케줄 관리',
                onTap: () => context.push('/bikes/$bikeId/maintenances'),
              ),
              _ActionTile(
                icon: Icons.local_gas_station_rounded,
                iconColor: const Color(0xFF007AFF),
                label: '주유 기록',
                subtitle: '주유 이력 및 연비 통계',
                onTap: () => context.go('/fuel'),
              ),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color iconColor;
  final Color? valueColor;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.iconColor,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(height: 6),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: valueColor ??
                          Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  TextSpan(
                    text: ' $unit',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1C1C1E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1C1C1E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
