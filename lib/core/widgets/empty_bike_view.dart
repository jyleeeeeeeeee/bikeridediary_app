import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 바이크 미등록 시 공통 빈 상태 위젯
/// — 홈, 바이크 목록, 주유 화면에서 동일하게 사용
class EmptyBikeView extends StatelessWidget {
  const EmptyBikeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 원형 아이콘
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: const Color(0xFF1B2838).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.two_wheeler,
                size: 48,
                color: Color(0xFF1B2838),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '등록된 바이크가 없습니다',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '바이크를 등록하고 관리를 시작하세요',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => context.push('/bikes/new'),
              icon: const Icon(Icons.add),
              label: const Text('바이크 등록'),
            ),
          ],
        ),
      ),
    );
  }
}
