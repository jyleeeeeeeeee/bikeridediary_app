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
                _dropdown<String>(
                  value: fuelType,
                  items: const [
                    DropdownMenuItem(value: 'B027', child: Text('휘발유')),
                    DropdownMenuItem(value: 'B034', child: Text('고급휘발유')),
                  ],
                  onChanged: (v) {
                    ref.read(stationFuelTypeProvider.notifier).state = v;
                    ref.read(nearbyStationsProvider.notifier).search();
                  },
                ),
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

  Widget _dropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          style: const TextStyle(fontSize: 12, color: Color(0xFF1B2838)),
          items: items,
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}
