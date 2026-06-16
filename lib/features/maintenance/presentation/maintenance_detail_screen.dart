import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/model/maintenance_type.dart';
import '../data/repository/maintenance_repository.dart';
import '../data/model/maintenance_response.dart';
import '../domain/maintenance_provider.dart';

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
      appBar: AppBar(
        title: const Text('정비 상세'),
        actions: [
          detailAsync.whenOrNull(
                data: (m) => PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'edit') {
                      context.push('/bikes/$bikeId/maintenances/$maintenanceId/edit', extra: m);
                    } else if (value == 'delete') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('정비 기록 삭제'),
                          content: const Text('정말 삭제하시겠습니까?'),
                          actions: [
                            TextButton(onPressed: () => ctx.pop(false), child: const Text('취소')),
                            TextButton(onPressed: () => ctx.pop(true), child: const Text('삭제')),
                          ],
                        ),
                      );
                      if (confirm == true && context.mounted) {
                        await ref.read(maintenanceListProvider(bikeId).notifier).deleteMaintenance(maintenanceId);
                        if (context.mounted) context.pop();
                      }
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('수정')),
                    const PopupMenuItem(value: 'delete', child: Text('삭제')),
                  ],
                ),
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (m) {
          final type = MaintenanceType.values.firstWhere(
            (t) => t.name == m.maintenanceType,
            orElse: () => MaintenanceType.OTHER,
          );
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _infoTile('정비 종류', type.displayName),
              _infoTile('정비 날짜', m.maintenanceDate),
              _infoTile('주행거리', '${m.mileageAtMaintenance} km'),
              if (m.cost != null) _infoTile('비용', '${m.cost}원'),
              if (m.description != null && m.description!.isNotEmpty)
                _infoTile('메모', m.description!),
              if (m.nextDueKm != null) _infoTile('다음 정비 예정', '${m.nextDueKm} km'),
              if (m.nextDueDate != null) _infoTile('다음 정비 예정일', m.nextDueDate!),
            ],
          );
        },
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
