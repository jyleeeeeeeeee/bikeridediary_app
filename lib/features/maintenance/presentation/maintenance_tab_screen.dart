import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/empty_bike_view.dart';
import '../../bike/domain/bike_provider.dart';
import 'maintenance_list_screen.dart';

class MaintenanceTabScreen extends ConsumerWidget {
  const MaintenanceTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bikesAsync = ref.watch(bikeListProvider);

    return bikesAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('오류: $e')),
      ),
      data: (bikes) {
        if (bikes.isEmpty) {
          return const Scaffold(body: SafeArea(child: EmptyBikeView()));
        }
        final rep = bikes.firstWhere(
          (b) => b.isRepresentative,
          orElse: () => bikes.first,
        );
        return MaintenanceListScreen(key: ValueKey(rep.id), bikeId: rep.id);
      },
    );
  }
}
