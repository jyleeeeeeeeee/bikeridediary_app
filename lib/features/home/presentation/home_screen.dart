import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_bike_view.dart';
import '../../auth/domain/auth_provider.dart';
import '../../bike/data/model/bike_category.dart';
import '../../bike/data/model/bike_response.dart';
import '../../bike/domain/bike_provider.dart';
import '../../fueling/domain/fueling_provider.dart';
import '../../maintenance/domain/maintenance_provider.dart';
import '../../station/data/model/avg_oil.dart';
import '../../station/domain/station_provider.dart';

// Formats a number with comma separators (e.g. 12345 → "12,345")
String _formatNumber(num n) => n
    .toString()
    .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    // 로컬 게스트는 서버 API 호출이 불가능하므로 뱅킹 사용 안내 화면 표시.
    // 나머지 도메인은 Phase 3에서 로컬 우선으로 이전되면 그때 사용 가능해짐.
    if (auth.isLocalGuest) {
      return const _LocalGuestHome();
    }

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
            onRefresh: () {
              ref.invalidate(scheduleListProvider(repBike.id));
              ref.invalidate(fuelingStatsProvider(repBike.id));
              ref.invalidate(avgOilPriceProvider);
              return ref.refresh(bikeListProvider.future);
            },
            child: CustomScrollView(
              slivers: [
                // ── Custom gradient header ──────────────────────────────────
                SliverToBoxAdapter(
                  child: _HomeHeader(
                    bike: repBike,
                    nickname: ref.watch(authProvider).user?.nickname,
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
                            .go('/bikes/${repBike.id}/maintenances'),
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

class _HomeHeader extends ConsumerWidget {
  final BikeResponse bike;
  final String? nickname;
  final VoidCallback onLogout;

  const _HomeHeader({required this.bike, this.nickname, required this.onLogout});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryName = BikeTypeDisplay.displayName(bike.category);
    final avgOilAsync = ref.watch(avgOilPriceProvider);

    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.headerGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 8, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: greeting + avg price
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
                        Text.rich(
                          TextSpan(
                            text: nickname ?? '라이더',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                            children: const [
                              TextSpan(
                                text: '님',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  avgOilAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (oils) {
                      if (oils.isEmpty) return const SizedBox.shrink();
                      final targets = oils.where(
                        (o) => o.prodcd == 'B027' || o.prodcd == 'B034',
                      ).toList();
                      if (targets.isEmpty) return const SizedBox.shrink();
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (int i = 0; i < targets.length; i++) ...[
                            if (i > 0) const SizedBox(width: 6),
                            _OilPriceChip(oil: targets[i]),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Representative bike info card (white on dark)
              GestureDetector(
                onTap: () => context.go('/bikes/${bike.id}'),
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

    final overdueCount = schedulesAsync.whenOrNull(
          data: (list) => list.where((s) => s.overdue).length,
        ) ??
        0;

    final avgEfficiency = fuelingStatsAsync.whenOrNull(
      data: (stats) => stats.averageFuelEfficiency,
    );

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.speed_rounded,
            label: '총 주행거리',
            value: _formatNumber(bike.totalMileageKm),
            unit: 'km',
            iconColor: const Color(0xFF1C1C1E),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.local_gas_station_rounded,
            label: '평균 연비',
            value: avgEfficiency != null
                ? avgEfficiency.toStringAsFixed(1)
                : '--',
            unit: 'km/L',
            iconColor: const Color(0xFF007AFF),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.build_rounded,
            label: '정비 필요',
            value: overdueCount.toString(),
            unit: '건',
            iconColor:
                overdueCount > 0 ? Colors.redAccent : const Color(0xFF1C1C1E),
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
      error: (_, _) => const SizedBox.shrink(),
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
              iconColor: const Color(0xFF1C1C1E),
              onTap: () => context.go('/maintenance'),
            ),
            _QuickActionCard(
              icon: Icons.local_gas_station_rounded,
              label: '주유 기록',
              iconColor: const Color(0xFF007AFF),
              onTap: () {
                context.go('/fuel');
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  context.push('/fuel/new');
                });
              },
            ),
            _QuickActionCard(
              icon: Icons.directions_bike_rounded,
              label: '바이크 상세',
              iconColor: const Color(0xFF5AC8FA),
              onTap: () => context.go('/bikes/${bike.id}'),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _OilPriceChip extends StatelessWidget {
  final AvgOil oil;
  const _OilPriceChip({required this.oil});

  @override
  Widget build(BuildContext context) {
    final diffColor = oil.diff > 0
        ? const Color(0xFFFF6B6B)
        : oil.diff < 0
            ? const Color(0xFF51CF66)
            : Colors.white54;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                oil.prodnm,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 10,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${oil.priceDisplay}원',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                oil.diff > 0
                    ? Icons.arrow_drop_up_rounded
                    : oil.diff < 0
                        ? Icons.arrow_drop_down_rounded
                        : Icons.remove_rounded,
                color: diffColor,
                size: 16,
              ),
              Text(
                '${oil.diff > 0 ? '+' : ''}${oil.diff.toStringAsFixed(1)}원',
                style: TextStyle(
                  color: diffColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
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

/// 로컬 게스트 전용 홈 화면.
/// 서버 API 호출이 불가능하므로 뱅킹각 측정만 사용 가능함을 안내하고 진입 경로 제공.
/// 다른 도메인(바이크/정비/주유)은 Phase 3에서 로컬 우선 지원되면 여기에 추가된다.
class _LocalGuestHome extends ConsumerWidget {
  const _LocalGuestHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '가입 없이 사용 중',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        ref.read(authProvider.notifier).logout(),
                    child: const Text('나가기'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3CD),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      CupertinoIcons.wifi_slash,
                      color: Color(0xFF856404),
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '오프라인 게스트 세션이라 정비/주유 기록은 사용할 수 없습니다. '
                        '뱅킹각 측정은 인터넷 없이도 완전히 사용 가능합니다.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF856404),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _LocalGuestActionCard(
                icon: CupertinoIcons.gauge,
                title: '뱅킹각 측정',
                description: '스마트폰 센서로 라이딩 뱅킹각을 실시간 측정하고 기록합니다.',
                onTap: () => context.push('/banking'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocalGuestActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _LocalGuestActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.primaryColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                CupertinoIcons.chevron_right,
                color: AppTheme.textSecondary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
