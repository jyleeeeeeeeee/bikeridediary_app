import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/model/bike_category.dart';
import '../domain/bike_provider.dart';

class BikeListScreen extends ConsumerWidget {
  const BikeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bikesAsync = ref.watch(bikeListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('내 바이크')),
      body: bikesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (bikes) {
          if (bikes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.two_wheeler, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('등록된 바이크가 없습니다'),
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
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: bikes.length,
              itemBuilder: (context, index) {
                final bike = bikes[index];
                final category = BikeCategory.values.firstWhere(
                  (c) => c.name == bike.category,
                  orElse: () => BikeCategory.OTHER,
                );
                return Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.two_wheeler,
                      color: bike.isRepresentative
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    title: Text(bike.displayName),
                    subtitle: Text(
                      '${category.displayName} · ${bike.totalMileageKm.toString()}km',
                    ),
                    trailing: bike.isRepresentative
                        ? Icon(Icons.star, color: Theme.of(context).colorScheme.primary)
                        : null,
                    onTap: () => context.push('/bikes/${bike.id}'),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/bikes/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
