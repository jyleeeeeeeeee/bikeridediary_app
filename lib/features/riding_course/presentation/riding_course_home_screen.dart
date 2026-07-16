// 라이딩 코스 홈 화면.
// "내 코스 / 탐색" 커스텀 탭바 + FAB(+ = "곧 지원 예정" 스낵바).
// shell 밖 전체 화면 → SafeArea 상단 처리 직접 필요.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'explore_courses_tab.dart';
import 'my_courses_tab.dart';

class RidingCourseHomeScreen extends StatefulWidget {
  const RidingCourseHomeScreen({super.key});

  @override
  State<RidingCourseHomeScreen> createState() => _RidingCourseHomeScreenState();
}

class _RidingCourseHomeScreenState extends State<RidingCourseHomeScreen> {
  int _tabIndex = 0; // 0 = 내 코스, 1 = 탐색

  static const _primary = Color(0xFF007AFF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        leading: BackButton(color: _primary, onPressed: () => context.pop()),
        title: const Text(
          '라이딩 코스',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1C1C1E),
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: const Color(0xFFE5E5EA),
          ),
        ),
      ),
      body: Column(
        children: [
          // 커스텀 탭바
          _buildTabBar(),
          // 탭 컨텐츠
          Expanded(
            child: _tabIndex == 0
                ? const MyCoursesTab()
                : const ExploreCoursesTab(),
          ),
        ],
      ),

      // FAB: 우하단 (시스템 하단바 위)
      floatingActionButton: SafeArea(
        top: false,
        child: FloatingActionButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('코스 생성 기능은 곧 지원 예정입니다.'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          elevation: 4,
          child: const Icon(Icons.add, size: 28),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E5EA), width: 1),
        ),
      ),
      child: Row(
        children: [
          _TabItem(
            label: '내 코스',
            isActive: _tabIndex == 0,
            onTap: () => setState(() => _tabIndex = 0),
          ),
          _TabItem(
            label: '탐색',
            isActive: _tabIndex == 1,
            onTap: () => setState(() => _tabIndex = 1),
          ),
        ],
      ),
    );
  }
}

/// 커스텀 탭 아이템.
class _TabItem extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF007AFF);
    const secondary = Color(0xFF8E8E93);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? primary : secondary,
            ),
          ),
        ),
      ),
    );
  }
}
