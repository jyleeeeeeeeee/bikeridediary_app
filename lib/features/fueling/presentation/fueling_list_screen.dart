import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../bike/domain/bike_provider.dart';
import '../data/model/fuel_type.dart';
import '../data/model/fueling_response.dart';
import '../data/model/fueling_stats_response.dart';
import '../domain/fueling_provider.dart';
import '../../../core/theme/app_theme.dart';

class FuelingListScreen extends ConsumerStatefulWidget {
  const FuelingListScreen({super.key});

  @override
  ConsumerState<FuelingListScreen> createState() => _FuelingListScreenState();
}

class _FuelingListScreenState extends ConsumerState<FuelingListScreen> {
  String? _selectedBikeId;
  bool _didInit = false;

  // Format numbers with comma separators (e.g., 12345 → "12,345")
  String _formatNumber(num n) => n
      .toString()
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    final bikesAsync = ref.watch(bikeListProvider);

    // Initialise selected bike once the list is available
    if (!_didInit && bikesAsync.hasValue && bikesAsync.value!.isNotEmpty) {
      _didInit = true;
      final bikes = bikesAsync.value!;
      final rep = bikes.where((b) => b.isRepresentative).firstOrNull ?? bikes.first;
      // Use addPostFrameCallback to avoid calling setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selectedBikeId == null) {
          setState(() => _selectedBikeId = rep.id);
        }
      });
    }

    return Scaffold(
      body: bikesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (bikes) {
          if (bikes.isEmpty) {
            return _EmptyBikeState();
          }

          final currentBikeId = _selectedBikeId ?? bikes.first.id;

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                title: const Text('주유 기록'),
                pinned: true,
                expandedHeight: 220,
                flexibleSpace: FlexibleSpaceBar(
                  background: _StatsHeader(
                    bikeId: currentBikeId,
                    formatNumber: _formatNumber,
                  ),
                ),
              ),
            ],
            body: Column(
              children: [
                // Bike selector
                _BikeSelectorBar(
                  bikes: bikes,
                  selectedBikeId: currentBikeId,
                  onChanged: (id) => setState(() => _selectedBikeId = id),
                ),
                // Fueling list
                Expanded(
                  child: _FuelingList(
                    bikeId: currentBikeId,
                    formatNumber: _formatNumber,
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/fuel/new'),
        tooltip: '주유 기록 추가',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ─── Stats Header ────────────────────────────────────────────────────────────

class _StatsHeader extends ConsumerWidget {
  final String bikeId;
  final String Function(num) formatNumber;

  const _StatsHeader({required this.bikeId, required this.formatNumber});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(fuelingStatsProvider(bikeId));

    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.headerGradient),
      padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
      child: statsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.white54),
        ),
        error: (_, __) => const Center(
          child: Text('통계를 불러올 수 없습니다', style: TextStyle(color: Colors.white70)),
        ),
        data: (stats) => _StatsContent(stats: stats, formatNumber: formatNumber),
      ),
    );
  }
}

class _StatsContent extends StatelessWidget {
  final FuelingStatsResponse stats;
  final String Function(num) formatNumber;

  const _StatsContent({required this.stats, required this.formatNumber});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '주유 통계 (총 ${stats.totalCount}회)',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatItem(
                icon: Icons.local_gas_station,
                label: '평균 연비',
                value: stats.averageFuelEfficiency != null
                    ? '${stats.averageFuelEfficiency!.toStringAsFixed(1)} km/L'
                    : '–',
                highlight: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatItem(
                icon: Icons.water_drop,
                label: '총 주유량',
                value: '${stats.totalFuelAmount.toStringAsFixed(1)} L',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatItem(
                icon: Icons.receipt_long,
                label: '총 비용',
                value: '${formatNumber(stats.totalCost)}원',
              ),
            ),
          ],
        ),
        if (stats.latestFuelEfficiency != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.trending_up, size: 14, color: Color(0xFFFF8F5E)),
                const SizedBox(width: 6),
                Text(
                  '최근 연비 ${stats.latestFuelEfficiency!.toStringAsFixed(1)} km/L',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: highlight ? const Color(0xFFFF6B35) : Colors.white54),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: highlight ? const Color(0xFFFF8F5E) : Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ─── Bike Selector Bar ────────────────────────────────────────────────────────

class _BikeSelectorBar extends StatelessWidget {
  final List bikes;
  final String selectedBikeId;
  final ValueChanged<String> onChanged;

  const _BikeSelectorBar({
    required this.bikes,
    required this.selectedBikeId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.two_wheeler, size: 18, color: Color(0xFF1B2838)),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedBikeId,
                isExpanded: true,
                isDense: true,
                style: const TextStyle(
                  color: Color(0xFF1B2838),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                items: bikes.map<DropdownMenuItem<String>>((b) {
                  return DropdownMenuItem(
                    value: b.id as String,
                    child: Row(
                      children: [
                        Text(b.displayName as String),
                        if (b.isRepresentative as bool) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.star, size: 14, color: Color(0xFFFF6B35)),
                        ],
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) onChanged(v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Fueling Record List ──────────────────────────────────────────────────────

class _FuelingList extends ConsumerWidget {
  final String bikeId;
  final String Function(num) formatNumber;

  const _FuelingList({required this.bikeId, required this.formatNumber});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(fuelingListProvider(bikeId));

    return listAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('오류: $e')),
      data: (records) {
        if (records.isEmpty) {
          return _EmptyRecordsState();
        }
        return RefreshIndicator(
          onRefresh: () => ref.refresh(fuelingListProvider(bikeId).future),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            itemCount: records.length,
            itemBuilder: (context, index) => _FuelingCard(
              record: records[index],
              formatNumber: formatNumber,
              onTap: () => context.push('/fuel/${records[index].id}/edit', extra: records[index]),
            ),
          ),
        );
      },
    );
  }
}

// ─── Fueling Card ─────────────────────────────────────────────────────────────

class _FuelingCard extends StatelessWidget {
  final FuelingResponse record;
  final String Function(num) formatNumber;
  final VoidCallback onTap;

  const _FuelingCard({
    required this.record,
    required this.formatNumber,
    required this.onTap,
  });

  FuelType get _fuelType => FuelType.values.firstWhere(
        (t) => t.name == record.fuelType,
        orElse: () => FuelType.REGULAR,
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: date + badges
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    record.fuelingDate,
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  // Full tank badge
                  if (record.isFullTank)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: AppTheme.accentGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '만탱크',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(width: 6),
                  // Fuel type badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B2838).withAlpha(13),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _fuelType.displayName,
                      style: const TextStyle(
                        color: Color(0xFF1B2838),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Station name
              if (record.stationName != null) ...[
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Color(0xFFFF6B35)),
                    const SizedBox(width: 4),
                    Text(
                      record.stationName!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              // Key stats row
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.water_drop_outlined,
                    text: '${record.fuelAmount.toStringAsFixed(1)} L',
                  ),
                  const SizedBox(width: 12),
                  if (record.totalCost != null)
                    _InfoChip(
                      icon: Icons.payments_outlined,
                      text: '${formatNumber(record.totalCost!)}원',
                    ),
                  const Spacer(),
                  // Fuel efficiency highlight
                  if (record.fuelEfficiency != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.local_gas_station,
                              size: 14, color: Colors.green.shade700),
                          const SizedBox(width: 4),
                          Text(
                            '${record.fuelEfficiency!.toStringAsFixed(1)} km/L',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              // Mileage
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.speed, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${formatNumber(record.mileageAtFueling)} km',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }
}

// ─── Empty States ─────────────────────────────────────────────────────────────

class _EmptyRecordsState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35).withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_gas_station,
              size: 40,
              color: Color(0xFFFF6B35),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '주유 기록이 없습니다',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1B2838),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '주유 기록을 추가해보세요',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

class _EmptyBikeState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
}
