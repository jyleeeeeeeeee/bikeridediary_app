// 코스 목록 아이템 카드.
// [showFavoriteStar] true이면 탐색 탭 모드: 별 토글 버튼 표시.
//                    false이면 내 코스 탭 모드: 소유 배지(하트/별) 표시.

import 'package:flutter/material.dart';

import '../../data/model/course_summary_response.dart';
import 'ownership_badge.dart';

class CourseListItem extends StatelessWidget {
  final CourseSummaryResponse course;

  /// true = 탐색 탭 (별 토글), false = 내 코스 탭 (소유 배지)
  final bool showFavoriteStar;

  /// 별 토글 콜백 (showFavoriteStar == true일 때만 사용)
  final VoidCallback? onToggleFavorite;

  /// 카드 탭 콜백
  final VoidCallback onTap;

  const CourseListItem({
    super.key,
    required this.course,
    required this.onTap,
    this.showFavoriteStar = false,
    this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // 코스 정보 (좌측)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1C1C1E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        course.distanceLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 3,
                        height: 3,
                        decoration: const BoxDecoration(
                          color: Color(0xFF8E8E93),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(
                        course.authorNickname,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 우측 배지 또는 별 버튼
            if (showFavoriteStar) ...[
              if (course.ownedByMe)
                // 내가 만든 코스는 탐색에서도 하트로 표시 (즐겨찾기 불가)
                const Padding(
                  padding: EdgeInsets.all(7),
                  child: Text('❤️', style: TextStyle(fontSize: 22)),
                )
              else
                _FavoriteStarButton(
                  isFavorited: course.isFavorited,
                  onTap: onToggleFavorite,
                ),
            ] else ...[
              // 내 코스 탭: 소유 배지
              OwnershipBadge(ownedByMe: course.ownedByMe),
            ],
          ],
        ),
      ),
    );
  }
}

/// 즐겨찾기 별 토글 버튼.
/// 노란별 = 등록됨, 회색별 = 미등록.
class _FavoriteStarButton extends StatelessWidget {
  final bool isFavorited;
  final VoidCallback? onTap;

  const _FavoriteStarButton({required this.isFavorited, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 36,
        height: 36,
        child: Center(
          child: Text(
            isFavorited ? '⭐' : '☆',
            style: TextStyle(
              fontSize: 22,
              color: isFavorited
                  ? const Color(0xFFFFCC00)
                  : const Color(0xFFC7C7CC),
            ),
          ),
        ),
      ),
    );
  }
}
