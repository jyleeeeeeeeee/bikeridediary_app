import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/station_provider.dart';

class StationPickScreen extends ConsumerStatefulWidget {
  const StationPickScreen({super.key});

  @override
  ConsumerState<StationPickScreen> createState() => _StationPickScreenState();
}

class _StationPickScreenState extends ConsumerState<StationPickScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(nearbyStationsProvider.notifier).search(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stationsAsync = ref.watch(nearbyStationsProvider);
    final fuelType = ref.watch(stationFuelTypeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('주유소 선택')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _chip('일반유', 'B027', fuelType),
                const SizedBox(width: 6),
                _chip('고급유', 'B034', fuelType),
                const SizedBox(width: 6),
                _chip('경유', 'D047', fuelType),
              ],
            ),
          ),
          Expanded(
            child: stationsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(e.toString().replaceAll('Exception: ', '')),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () =>
                          ref.read(nearbyStationsProvider.notifier).search(),
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              ),
              data: (stations) {
                if (stations.isEmpty) {
                  return const Center(child: Text('주변에 주유소가 없습니다'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: stations.length,
                  itemBuilder: (context, index) {
                    final s = stations[index];
                    return ListTile(
                      leading: const Icon(Icons.local_gas_station,
                          color: Color(0xFFFF6B35)),
                      title: Text(s.name,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                          '${s.brandDisplayName} · ${s.distanceDisplay}'),
                      trailing: Text(
                        '${s.priceDisplay}원',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFF6B35),
                        ),
                      ),
                      onTap: () => context.pop<Map<String, dynamic>>({
                        'name': s.name,
                        'price': s.price,
                      }),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String code, String selected) {
    final isSelected = code == selected;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        ref.read(stationFuelTypeProvider.notifier).state = code;
        ref.read(nearbyStationsProvider.notifier).search();
      },
      selectedColor: const Color(0xFFFF6B35),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isSelected ? Colors.white : const Color(0xFF1B2838),
      ),
      visualDensity: VisualDensity.compact,
    );
  }
}
