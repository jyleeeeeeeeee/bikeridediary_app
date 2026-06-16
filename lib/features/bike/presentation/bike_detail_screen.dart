import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/model/bike_category.dart';
import '../data/model/bike_response.dart';
import '../data/repository/bike_repository.dart';
import '../domain/bike_provider.dart';

final bikeDetailProvider = FutureProvider.family<BikeResponse, String>((ref, bikeId) {
  return ref.watch(bikeRepositoryProvider).getBike(bikeId);
});

class BikeDetailScreen extends ConsumerWidget {
  final String bikeId;

  const BikeDetailScreen({super.key, required this.bikeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bikeAsync = ref.watch(bikeDetailProvider(bikeId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('바이크 상세'),
        actions: [
          bikeAsync.whenOrNull(
                data: (bike) => PopupMenuButton<String>(
                  onSelected: (value) async {
                    switch (value) {
                      case 'edit':
                        context.push('/bikes/$bikeId/edit', extra: bike);
                        break;
                      case 'representative':
                        await ref.read(bikeListProvider.notifier).setRepresentative(bikeId);
                        ref.invalidate(bikeDetailProvider(bikeId));
                        break;
                      case 'delete':
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('바이크 삭제'),
                            content: const Text('정말 삭제하시겠습니까?'),
                            actions: [
                              TextButton(onPressed: () => ctx.pop(false), child: const Text('취소')),
                              TextButton(onPressed: () => ctx.pop(true), child: const Text('삭제')),
                            ],
                          ),
                        );
                        if (confirm == true && context.mounted) {
                          await ref.read(bikeListProvider.notifier).delete(bikeId);
                          if (context.mounted) context.pop();
                        }
                        break;
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('수정')),
                    const PopupMenuItem(value: 'representative', child: Text('대표 바이크 설정')),
                    const PopupMenuItem(value: 'delete', child: Text('삭제')),
                  ],
                ),
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: bikeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (bike) {
          final category = BikeCategory.values.firstWhere(
            (c) => c.name == bike.category,
            orElse: () => BikeCategory.OTHER,
          );
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Icon(
                  Icons.two_wheeler,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                bike.displayName,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              if (bike.isRepresentative) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star, size: 16, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 4),
                    Text('대표 바이크', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              _infoTile('카테고리', category.displayName),
              _infoTile('총 주행거리', '${bike.totalMileageKm} km'),
              if (bike.purchasedAt != null) _infoTile('구매일', bike.purchasedAt!),
              if (bike.memo != null && bike.memo!.isNotEmpty) _infoTile('메모', bike.memo!),
              _infoTile('등록일', bike.createdAt.substring(0, 10)),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => context.push('/bikes/$bikeId/maintenances'),
                icon: const Icon(Icons.build),
                label: const Text('정비 기록 보기'),
              ),
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
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
