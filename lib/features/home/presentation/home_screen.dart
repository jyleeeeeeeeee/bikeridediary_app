import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_bike_view.dart';
import '../../auth/domain/auth_provider.dart';
import '../../bike/data/model/bike_category.dart';
import '../../bike/data/model/bike_response.dart';
import '../../bike/domain/bike_provider.dart';
import '../../maintenance/domain/maintenance_provider.dart';
import '../../fueling/domain/fueling_provider.dart';

// Formats a number with comma separators (e.g. 12345 → "12,345")
String _formatNumber(num n) => n
    .toString()
    .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bikesAsync = ref.watch(bikeListProvider);

    return Scaffold(
      body: bikesAsync.when(
        loading: () => const _LoadingView(),
        error: (e, _) => _ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(bikeListProvider),
        ),
        data: (bikes) {
          if (bikes.isEmpty) {
            return _EmptyBikeView();
          }

          final repBike = bikes.firstWhere(
            (b) => b.isRepresentative,
            orElse: () => bikes.first,
          );

          return RefreshIndicator(
            onRefresh: () => ref.refresh(bikeListProvider.future),
            child: CustomScrollView(
              slivers: [
                // ── Custom gradient header ──────────────────────────────────
                SliverToBoxAdapter(
                  child: _HomeHeader(
                    bike: repBike,
                    onLogout: () => ref.read(authProvider.notifier).logout(),
                  ),
                ),
                // ── Body content ────────────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Quick stats row
                      _QuickStatsRow(bike: repBike),
                      const SizedBox(height: 16),
                      // Overdue maintenance alerts
                      _OverdueSection(
                        bikeId: repBike.id,
                        onTap: () => context
                            .push('/bikes/${repBike.id}/maintenances'),
                      ),
                      // Quick actions grid
                      _QuickActionsGrid(bike: repBike),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Loading / Error / Empty states ──────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              '오류가 발생했습니다',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onRetry,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyBikeView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SafeArea(child: EmptyBikeView());
  }
}

// ── Gradient header ──────────────────────────────────────────────────────────

class _HomeHeader extends StatelessWidget {
  final BikeResponse bike;
  final VoidCallback onLogout;

  const _HomeHeader({required this.bike, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final categoryName = BikeTypeDisplay.displayName(bike.category);

    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.headerGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 8, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: greeting + logout button
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '안녕하세요!',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          '바라다',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, color: Colors.white70),
                    tooltip: '로그아웃',
                    onPressed: onLogout,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Representative bike info card (white on dark)
              GestureDetector(
                onTap: () => context.push('/bikes/${bike.id}'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Bike icon with accent gradient background
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: AppTheme.accentGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.two_wheeler,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bike.displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$categoryName · ${_formatNumber(bike.totalMileageKm)} km',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white54,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Quick stats row ──────────────────────────────────────────────────────────

class _QuickStatsRow extends ConsumerWidget {
  final BikeResponse bike;

  const _QuickStatsRow({required this.bike});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fuelingStatsAsync = ref.watch(fuelingStatsProvider(bike.id));
    final schedulesAsync = ref.watch(scheduleListProvider(bike.id));

    // Overdue count derived from schedules
    final overdueCount = schedulesAsync.whenOrNull(
          data: (list) => list.where((s) => s.overdue).length,
        ) ??
        0;

    // Average fuel efficiency from stats
    final avgEfficiency = fuelingStatsAsync.whenOrNull(
      data: (stats) => stats.averageFuelEfficiency,
    );

    return Row(
      children: [
        // Total mileage
        Expanded(
          child: _StatCard(
            icon: Icons.speed_rounded,
            label: '총 주행거리',
            value: _formatNumber(bike.totalMileageKm),
            unit: 'km',
            iconColor: const Color(0xFF1B2838),
          ),
        ),
        const SizedBox(width: 10),
        // Average fuel efficiency
        Expanded(
          child: _StatCard(
            icon: Icons.local_gas_station_rounded,
            label: '평균 연비',
            value: avgEfficiency != null
                ? avgEfficiency.toStringAsFixed(1)
                : '--',
            unit: 'km/L',
            iconColor: const Color(0xFFFF6B35),
          ),
        ),
        const SizedBox(width: 10),
        // Overdue maintenance count
        Expanded(
          child: _StatCard(
            icon: Icons.build_rounded,
            label: '정비 필요',
            value: overdueCount.toString(),
            unit: '건',
            iconColor:
                overdueCount > 0 ? Colors.redAccent : const Color(0xFF1B2838),
            valueColor: overdueCount > 0 ? Colors.redAccent : null,
          ),
        ),
      ],
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
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Overdue alerts section ───────────────────────────────────────────────────

class _OverdueSection extends ConsumerWidget {
  final String bikeId;
  final VoidCallback onTap;

  const _OverdueSection({required this.bikeId, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedulesAsync = ref.watch(scheduleListProvider(bikeId));

    return schedulesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (schedules) {
        final overdue = schedules.where((s) => s.overdue).toList();
        if (overdue.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '정비 필요 (${overdue.length}건)',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.redAccent,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.redAccent,
                          size: 18,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Overdue item chips
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: overdue.map((s) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            s.maintenanceType,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Quick actions 2x2 grid ───────────────────────────────────────────────────

class _QuickActionsGrid extends StatelessWidget {
  final BikeResponse bike;

  const _QuickActionsGrid({required this.bike});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '빠른 메뉴',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.grey[700],
              ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.4,
          children: [
            _QuickActionCard(
              icon: Icons.build_rounded,
              label: '정비 기록',
              iconColor: const Color(0xFF1B2838),
              onTap: () => context.push('/bikes/${bike.id}/maintenances'),
            ),
            _QuickActionCard(
              icon: Icons.local_gas_station_rounded,
              label: '주유 기록',
              iconColor: const Color(0xFFFF6B35),
              onTap: () => context.push('/fuel'),
            ),
            _QuickActionCard(
              icon: Icons.directions_bike_rounded,
              label: '바이크 상세',
              iconColor: const Color(0xFF2D4059),
              onTap: () => context.push('/bikes/${bike.id}'),
            ),
            _QuickActionCard(
              icon: Icons.ev_station_rounded,
              label: '주유소 검색',
              iconColor: Colors.grey,
              comingSoon: true,
              onTap: null,
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback? onTap;
  final bool comingSoon;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.iconColor,
    this.onTap,
    this.comingSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: comingSoon ? Colors.grey[400] : iconColor,
                    size: 26,
                  ),
                  if (comingSoon) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Soon',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: comingSoon
                      ? Colors.grey[400]
                      : Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
