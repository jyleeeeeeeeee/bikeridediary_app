// 내 코스 탭.
// 내가 만든 코스(하트 배지) + 즐겨찾기한 남의 코스(별 배지) 두 섹션으로 분리.
// 당김 새로고침 지원 (AlwaysScrollableScrollPhysics).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/course_provider.dart';
import 'widgets/course_list_item.dart';

class MyCoursesTab extends ConsumerWidget {
  const MyCoursesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(myCoursesProvider);

    return RefreshIndicator(
      onRefresh: () {
        ref.invalidate(myCoursesProvider);
        return ref.read(myCoursesProvider.future);
      },
      child: coursesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.redAccent),
                    const SizedBox(height: 12),
                    Text('오류: $e', textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => ref.invalidate(myCoursesProvider),
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        data: (courses) {
          final mine = courses.where((c) => c.ownedByMe).toList();
          final favorited = courses.where((c) => !c.ownedByMe).toList();

          if (courses.isEmpty) {
            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  child: _EmptyState(
                    icon: Icons.route_outlined,
                    title: '코스가 없습니다',
                    desc: 'FAB(+) 버튼으로 첫 코스를 만들어보세요.\n즐겨찾기한 코스도 여기서 볼 수 있어요.',
                  ),
                ),
              ],
            );
          }

          final bottomPadding =
              72.0 + MediaQuery.of(context).viewPadding.bottom;

          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(12, 12, 12, bottomPadding),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // 내가 만든 코스 섹션
                    if (mine.isNotEmpty) ...[
                      _SectionHeader(label: '내가 만든 코스', count: mine.length),
                      ...mine.map((c) => CourseListItem(
                            course: c,
                            onTap: () =>
                                context.push('/riding-courses/${c.id}'),
                          )),
                    ],

                    // 즐겨찾기한 코스 섹션
                    if (favorited.isNotEmpty) ...[
                      if (mine.isNotEmpty) const SizedBox(height: 8),
                      _SectionHeader(
                          label: '즐겨찾기한 코스', count: favorited.length),
                      ...favorited.map((c) => CourseListItem(
                            course: c,
                            onTap: () =>
                                context.push('/riding-courses/${c.id}'),
                          )),
                    ],
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;

  const _SectionHeader({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 8, top: 4),
      child: Text(
        '$label · $count',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF8E8E93),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: const Color(0xFF8E8E93).withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1C1C1E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF8E8E93),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
