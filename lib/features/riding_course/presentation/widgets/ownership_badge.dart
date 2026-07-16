// 코스 카드 우측 원형 배지.
// 내 코스 = 하트(#FF6B6B 배경), 즐겨찾기한 남의 코스 = 별(#FFCC00 배경).

import 'package:flutter/material.dart';

/// [ownedByMe] true이면 하트, false이면 별 배지 표시.
class OwnershipBadge extends StatelessWidget {
  final bool ownedByMe;

  const OwnershipBadge({super.key, required this.ownedByMe});

  @override
  Widget build(BuildContext context) {
    final bgColor = ownedByMe
        ? const Color(0xFFFF6B6B).withValues(alpha: 0.12)
        : const Color(0xFFFFCC00).withValues(alpha: 0.15);
    final icon = ownedByMe ? '❤️' : '⭐';

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(icon, style: const TextStyle(fontSize: 17)),
      ),
    );
  }
}
