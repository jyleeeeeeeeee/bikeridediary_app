import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../bike/domain/bike_provider.dart';
import '../data/model/fuel_type.dart';
import '../data/model/fueling_response.dart';
import '../data/model/fueling_stats_response.dart';
import '../domain/fueling_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_bike_view.dart';

class FuelingListScreen extends ConsumerStatefulWidget {
  const FuelingListScreen({super.key});

  @override
  ConsumerState<FuelingListScreen> createState() => _FuelingListScreenState();
}

final double iconSize = 18;
class _FuelingListScreenState extends ConsumerState<FuelingListScreen> {
  String? _selectedBikeId;
  bool _didInit = false;

  // Format numbers with comma separators (e.g., 12345 → "12,345")
  String _formatNumber(num n) => n.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );

  @override
  Widget build(BuildContext context) {
    final bikesAsync = ref.watch(bikeListProvider);

    // Initialise selected bike once the list is available
    if (!_didInit && bikesAsync.hasValue && bikesAsync.value!.isNotEmpty) {
      _didInit = true;
      final bikes = bikesAsync.value!;
      final rep =
          bikes.where((b) => b.isRepresentative).firstOrNull ?? bikes.first;
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
        error: (_, _) => const Center(
          child: Text(
            '통계를 불러올 수 없습니다',
            style: TextStyle(color: Colors.white70),
          ),
        ),
        data: (stats) =>
            _StatsContent(stats: stats, formatNumber: formatNumber),
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
                highlight: false,
                iconColor: Colors.blue,
                iconSize: iconSize,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatItem(
                icon: Icons.water_drop,
                label: '총 주유량',
                value: '${stats.totalFuelAmount.toStringAsFixed(1)} L',
                iconColor: Colors.black,
                iconSize: iconSize,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatItem(
                icon: Icons.attach_money,
                label: '총 비용',
                value: '${formatNumber(stats.totalCost)}원',
                iconColor: Colors.green,
                iconSize: iconSize,
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
                const Icon(
                  Icons.trending_up,
                  size: 20,
                  color: Color(0xFFFF8F5E),
                ),
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
  final Color? iconColor;
  final double? iconSize;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
    this.iconColor,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: iconSize ?? 14,
              color: highlight
                  ? const Color(0xFF007AFF)
                  : iconColor ?? Colors.white54,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
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
          const Icon(Icons.two_wheeler, size: 18, color: Color(0xFF1C1C1E)),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedBikeId,
                isExpanded: true,
                isDense: true,
                style: const TextStyle(
                  color: Color(0xFF1C1C1E),
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
                          const Icon(
                            Icons.star,
                            size: 14,
                            color: Colors.yellow,
                          ),
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
          onRefresh: () {
            ref.invalidate(fuelingListProvider(bikeId));
            ref.invalidate(fuelingStatsProvider(bikeId));
            return ref.read(fuelingListProvider(bikeId).future);
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              return Dismissible(
                key: Key(record.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('주유 기록 삭제'),
                          content: const Text('이 주유 기록을 삭제하시겠습니까?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('취소'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('삭제'),
                            ),
                          ],
                        ),
                      ) ??
                      false;
                },
                onDismissed: (direction) {
                  ref
                      .read(fuelingListProvider(bikeId).notifier)
                      .deleteFueling(record.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('주유 기록이 삭제되었습니다')),
                  );
                },
                child: _FuelingCard(
                  record: record,
                  formatNumber: formatNumber,
                  onTap: () =>
                      context.push('/fuel/${record.id}/edit', extra: record),
                ),
              );
            },
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
                  const Icon(
                    Icons.calendar_month,
                    size: 14,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    record.fuelingDate,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 6),
                  // Fuel type badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E).withAlpha(13),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _fuelType.displayName,
                      style: const TextStyle(
                        color: Color(0xFF1C1C1E),
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
                    Icon(
                      Icons.location_on,
                      size: iconSize,
                      color: const Color(0xFF007AFF),
                    ),
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
                    icon: Icons.water_drop,
                    text: '${record.fuelAmount.toStringAsFixed(1)} L',
                    iconColor: Colors.black,
                    size: iconSize,
                  ),
                  const SizedBox(width: 12),
                  if (record.totalCost != null)
                    _InfoChip(
                      icon: Icons.attach_money,
                      text: '${formatNumber(record.totalCost!)}원',
                      iconColor: Colors.green,
                      size: iconSize,
                    ),
                  const Spacer(),
                  // Fuel efficiency highlight
                  if (record.fuelEfficiency != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.local_gas_station,
                            size: iconSize,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${record.fuelEfficiency!.toStringAsFixed(1)} km/L',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontSize: 15,
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
                  Icon(Icons.speed, size: iconSize, color: Colors.red),
                  const SizedBox(width: 4),
                  Text(
                    '${formatNumber(record.mileageAtFueling)} km',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
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
  final Color? iconColor;
  final double? size;
  const _InfoChip({
    required this.icon,
    required this.text,
    this.iconColor,
    this.size
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: size ?? 14,
          color: iconColor == null ? Colors.grey[600] : iconColor,
        ),
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
              color: const Color(0xFF007AFF).withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_gas_station,
              size: 40,
              color: Color(0xFF007AFF),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '주유 기록이 없습니다',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1C1C1E),
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
    return const EmptyBikeView();
  }
}
