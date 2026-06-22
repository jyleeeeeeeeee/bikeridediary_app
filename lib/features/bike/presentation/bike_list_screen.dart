import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_bike_view.dart';
import '../data/model/bike_category.dart';
import '../domain/bike_provider.dart';

String _formatNumber(num n) => n
    .toString()
    .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

class BikeListScreen extends ConsumerWidget {
  const BikeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bikesAsync = ref.watch(bikeListProvider);

    return Scaffold(
      body: bikesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text('오류: $e', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(bikeListProvider),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
        data: (bikes) {
          if (bikes.isEmpty) return const _EmptyBikeView();

          return RefreshIndicator(
            onRefresh: () => ref.refresh(bikeListProvider.future),
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  title: const Text('내 바이크'),
                  pinned: true,
                  expandedHeight: 140,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(gradient: AppTheme.headerGradient),
                      padding: const EdgeInsets.fromLTRB(20, 80, 20, 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${bikes.length}',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 6),
                            child: Text(
                              '대 등록됨',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final bike = bikes[index];
                        return _BikeCard(
                          name: bike.displayName,
                          category: BikeTypeDisplay.displayName(bike.category),
                          mileage: bike.totalMileageKm,
                          year: bike.year,
                          isRepresentative: bike.isRepresentative,
                          onTap: () => context.push('/bikes/${bike.id}'),
                        );
                      },
                      childCount: bikes.length,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/bikes/new'),
        tooltip: '바이크 등록',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _BikeCard extends StatelessWidget {
  final String name;
  final String category;
  final int mileage;
  final int year;
  final bool isRepresentative;
  final VoidCallback onTap;

  const _BikeCard({
    required this.name,
    required this.category,
    required this.mileage,
    required this.year,
    required this.isRepresentative,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: isRepresentative
                      ? AppTheme.accentGradient
                      : null,
                  color: isRepresentative ? null : const Color(0xFF1B2838).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.two_wheeler,
                  color: isRepresentative ? Colors.white : const Color(0xFF1B2838),
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1B2838),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isRepresentative) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: AppTheme.accentGradient,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              '대표',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$category · ${year}년식',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatNumber(mileage),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1B2838),
                    ),
                  ),
                  Text(
                    'km',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyBikeView extends StatelessWidget {
  const _EmptyBikeView();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(child: EmptyBikeView());
  }
}
