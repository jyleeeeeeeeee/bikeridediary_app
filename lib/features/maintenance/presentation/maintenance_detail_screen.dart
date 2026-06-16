import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../data/model/maintenance_type.dart';
import '../data/repository/maintenance_repository.dart';
import '../data/model/maintenance_response.dart';
import '../domain/maintenance_provider.dart';

String _fmt(num n) => n
    .toString()
    .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

final maintenanceDetailProvider =
    FutureProvider.family<MaintenanceResponse, String>((ref, id) {
  return ref.watch(maintenanceRepositoryProvider).getMaintenance(id);
});

class MaintenanceDetailScreen extends ConsumerWidget {
  final String bikeId;
  final String maintenanceId;

  const MaintenanceDetailScreen({
    super.key,
    required this.bikeId,
    required this.maintenanceId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(maintenanceDetailProvider(maintenanceId));

    return Scaffold(
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (m) {
          final type = MaintenanceType.values.firstWhere(
            (t) => t.name == m.maintenanceType,
            orElse: () => MaintenanceType.OTHER,
          );
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 160,
                pinned: true,
                actions: [
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onSelected: (value) async {
                      if (value == 'edit') {
                        context.push(
                          '/bikes/$bikeId/maintenances/$maintenanceId/edit',
                          extra: m,
                        );
                      } else if (value == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('정비 기록 삭제'),
                            content: const Text('이 정비 기록을 삭제하시겠습니까?'),
                            actions: [
                              TextButton(
                                onPressed: () => ctx.pop(false),
                                child: const Text('취소'),
                              ),
                              TextButton(
                                onPressed: () => ctx.pop(true),
                                child: const Text('삭제', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && context.mounted) {
                          await ref
                              .read(maintenanceListProvider(bikeId).notifier)
                              .deleteMaintenance(maintenanceId);
                          if (context.mounted) context.pop();
                        }
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('수정')),
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
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.build_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        type.displayName,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        m.maintenanceDate,
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
                          child: _MiniStat(
                            icon: Icons.speed_rounded,
                            label: '주행거리',
                            value: '${_fmt(m.mileageAtMaintenance)} km',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MiniStat(
                            icon: Icons.payments_outlined,
                            label: '비용',
                            value: m.cost != null ? '${_fmt(m.cost!)}원' : '-',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Detail info card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '상세 정보',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1B2838),
                              ),
                            ),
                            const SizedBox(height: 14),
                            _InfoRow(label: '정비 종류', value: type.displayName),
                            _InfoRow(label: '정비 날짜', value: m.maintenanceDate),
                            _InfoRow(label: '주행거리', value: '${_fmt(m.mileageAtMaintenance)} km'),
                            if (m.cost != null)
                              _InfoRow(label: '비용', value: '${_fmt(m.cost!)}원'),
                            if (m.description != null && m.description!.isNotEmpty)
                              _InfoRow(label: '메모', value: m.description!),
                            if (m.nextDueKm != null)
                              _InfoRow(label: '다음 정비', value: '${_fmt(m.nextDueKm!)} km'),
                            if (m.nextDueDate != null)
                              _InfoRow(label: '다음 정비일', value: m.nextDueDate!),
                          ],
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF1B2838)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B2838),
                    ),
                  ),
                ],
              ),
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
            width: 90,
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
                color: Color(0xFF1B2838),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
