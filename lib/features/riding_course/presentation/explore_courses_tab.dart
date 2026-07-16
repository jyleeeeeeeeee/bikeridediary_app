// 탐색 탭.
// 상단 검색창 + 전체 코스 리스트.
// 검색은 in-memory 필터 (courseSearchProvider), 즉시 반응.
// 별 토글은 낙관적 업데이트 + 실패 시 롤백 적용.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/model/course_summary_response.dart';
import '../data/repository/course_repository.dart';
import '../domain/course_provider.dart';
import 'widgets/course_list_item.dart';

class ExploreCoursesTab extends ConsumerStatefulWidget {
  const ExploreCoursesTab({super.key});

  @override
  ConsumerState<ExploreCoursesTab> createState() => _ExploreCoursesTabState();
}

class _ExploreCoursesTabState extends ConsumerState<ExploreCoursesTab> {
  final _searchController = TextEditingController();
  String _keyword = '';

  /// 낙관적 UI 전용 로컬 상태 (courseId → isFavorited).
  /// 서버 응답 후 provider invalidate되면 자동으로 provider 값으로 교체됨.
  final Map<String, bool> _localFavorites = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite(CourseSummaryResponse course) async {
    if (course.ownedByMe) return; // 내 코스는 즐겨찾기 불가

    final repo = ref.read(courseRepositoryProvider);
    final newFavorited = !course.isFavorited;

    // 낙관적 업데이트
    setState(() {
      _localFavorites[course.id] = newFavorited;
    });

    try {
      if (newFavorited) {
        await repo.addFavorite(course.id);
      } else {
        await repo.removeFavorite(course.id);
      }
      // 성공 시 로컬 캐시 제거 (서버 응답이 원본 역할)
      setState(() {
        _localFavorites.remove(course.id);
      });
      // 관련 provider invalidate
      ref.invalidate(allCoursesProvider);
      ref.invalidate(myCoursesProvider);
    } catch (_) {
      // 실패 시 롤백
      setState(() {
        _localFavorites.remove(course.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('즐겨찾기 변경에 실패했습니다.')),
        );
      }
    }
  }

  bool _isFavorited(CourseSummaryResponse course) {
    if (_localFavorites.containsKey(course.id)) {
      return _localFavorites[course.id]!;
    }
    return course.isFavorited;
  }

  @override
  Widget build(BuildContext context) {
    final allAsync = ref.watch(allCoursesProvider);
    final filtered = ref.watch(courseSearchProvider(_keyword));

    return Column(
      children: [
        // 검색창
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: CupertinoSearchTextField(
            controller: _searchController,
            placeholder: '코스명, 지역으로 검색',
            onChanged: (v) => setState(() => _keyword = v),
          ),
        ),
        const SizedBox(height: 8),

        // 결과 수 라벨
        allAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
          data: (all) {
            final count = _keyword.isEmpty ? all.length : filtered.length;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '전체 코스 · $count개',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              ),
            );
          },
        ),

        // 리스트
        Expanded(
          child: allAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: Colors.redAccent),
                  const SizedBox(height: 12),
                  Text('$e', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => ref.invalidate(allCoursesProvider),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            ),
            data: (all) {
              final displayList = _keyword.isEmpty ? all : filtered;

              if (displayList.isEmpty) {
                return const Center(
                  child: Text(
                    '검색 결과가 없습니다.',
                    style: TextStyle(color: Color(0xFF8E8E93)),
                  ),
                );
              }

              final bottomPadding =
                  16.0 + MediaQuery.of(context).viewPadding.bottom;

              return RefreshIndicator(
                onRefresh: () {
                  ref.invalidate(allCoursesProvider);
                  return ref.read(allCoursesProvider.future);
                },
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(12, 8, 12, bottomPadding),
                  itemCount: displayList.length,
                  itemBuilder: (context, i) {
                    final course = displayList[i];
                    final overrideFavorited = _isFavorited(course);
                    final displayCourse =
                        overrideFavorited != course.isFavorited
                            ? course.copyWithFavorited(overrideFavorited)
                            : course;

                    return CourseListItem(
                      course: displayCourse,
                      showFavoriteStar: true,
                      onTap: () =>
                          context.push('/riding-courses/${course.id}'),
                      onToggleFavorite: () => _toggleFavorite(course),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
