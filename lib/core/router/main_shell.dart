import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../network/loading_state.dart';
import '../widgets/bike_loading_overlay.dart';

class MainShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;
  const MainShell({super.key, required this.navigationShell});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fabController;
  late final Animation<double> _fabAnimation;
  bool _isExpanded = false;

  static const int _bikeIndex = 2; // 바이크 아이콘 위치 (가운데)

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  void _onTap(int index) {
    if (index == _bikeIndex) {
      _toggleExpand();
      return;
    }
    if (_isExpanded) _collapse();
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _fabController.forward();
      } else {
        _fabController.reverse();
      }
    });
  }

  void _collapse() {
    if (!_isExpanded) return;
    setState(() {
      _isExpanded = false;
      _fabController.reverse();
    });
  }

  void _onExplore() {
    _collapse();
    // 라이딩/코스 도메인 복구 시 라우트 연결 (예: context.push('/courses'))
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('탐색 기능 준비 중')),
    );
  }

  void _onRecord() {
    _collapse();
    context.push('/banking');
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(isLoadingProvider);
    final currentIndex = widget.navigationShell.currentIndex;

    final viewPaddingBottom = MediaQuery.of(context).viewPadding.bottom;
    const barHeight = 60.0;

    return Stack(
      children: [
        // 1) Scaffold (가장 아래 z-order)
        Positioned.fill(
          child: Scaffold(
            body: BikeLoadingOverlay(
              isLoading: isLoading,
              child: widget.navigationShell,
            ),
            bottomNavigationBar: _buildBottomBar(currentIndex),
          ),
        ),
        // 2) 확장 시 어두운 barrier (바텀바 위에 덮임)
        if (_isExpanded)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _collapse,
              child: AnimatedBuilder(
                animation: _fabAnimation,
                builder: (_, _) => Container(
                  color: Colors.black.withValues(
                    alpha: 0.25 * _fabAnimation.value.clamp(0.0, 1.0).toDouble(),
                  ),
                ),
              ),
            ),
          ),
        // 3) sub-button (탐색/기록) — 바이크 원 위로 펼쳐짐
        Positioned(
          left: 0,
          right: 0,
          bottom: barHeight + viewPaddingBottom + 10,
          child: IgnorePointer(
            ignoring: !_isExpanded,
            child: Center(
              child: _ExpandedMenu(
                animation: _fabAnimation,
                onExplore: _onExplore,
                onRecord: _onRecord,
              ),
            ),
          ),
        ),
        // 4) 바이크 원 — 최상위 z-order, 바텀바 위에 시각적으로 얹힘
        Positioned(
          left: 0,
          right: 0,
          bottom: barHeight + viewPaddingBottom - 60,
          child: Center(
            child: _BikeCenterButton(
              isExpanded: _isExpanded,
              onTap: _toggleExpand,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(int currentIndex) {
    return Container(
        decoration: BoxDecoration(
          color: Colors.white,

          border: Border(
              top: BorderSide(
              color: Color(0xFF007AFF).withValues(alpha: 0.4), // 테두리 색상
              width: 2.0,         // 테두리 두께
            )
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: Row(
              children: [
            _NavItem(icon: Icons.home_rounded, label: '홈', index: 0, currentIndex: currentIndex, isExpanded: false, onTap: _onTap),
            _NavItem(icon: Icons.build_rounded, label: '정비', index: 1, currentIndex: currentIndex, isExpanded: false, onTap: _onTap),
            // 바이크 슬롯: 큰 원형 버튼은 body의 Positioned 오버레이로 따로 그림.
            // 여기는 다른 항목들과의 간격 유지용 빈 공간만 차지.
                const Expanded(child: SizedBox.shrink()),
                const Expanded(child: SizedBox.shrink()),
            _NavItem(icon: Icons.local_gas_station_rounded, label: '주유', index: 3, currentIndex: currentIndex, isExpanded: false, onTap: _onTap),
            _NavItem(icon: Icons.settings_rounded, label: '설정', index: 4, currentIndex: currentIndex, isExpanded: false, onTap: _onTap),
              ],
            ),
          ),
        ),
      );
  }
}

class _BikeCenterButton extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onTap;

  const _BikeCenterButton({required this.isExpanded, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF007AFF);
    const double size = 60;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isExpanded ? activeColor : Colors.white,
          border: isExpanded
              ? null
              : Border.all(color: activeColor.withValues(alpha: 0.4), width: 2),
          boxShadow: [
            BoxShadow(
              color: activeColor.withValues(alpha: isExpanded ? 0.45 : 0.25),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          isExpanded ? Icons.close_rounded : Icons.two_wheeler_rounded,
          color: isExpanded ? Colors.white : activeColor,
          size: isExpanded ? 40 : 30,
        ),
      ),
    );
  }
}

class _ExpandedMenu extends StatelessWidget {
  final Animation<double> animation;
  final VoidCallback onExplore;
  final VoidCallback onRecord;

  const _ExpandedMenu({
    required this.animation,
    required this.onExplore,
    required this.onRecord,
  });

  @override
  Widget build(BuildContext context) {
    // 바이크 아이콘 기준으로 좌상단/우상단으로 펼쳐지는 거리
    const double spread = 50;

    return SizedBox(
      width: 220,
      height: 100,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          _SubFab(
            animation: animation,
            offset: const Offset(-spread, -spread),
            icon: Icons.map_outlined,
            label: '코스 탐색',
            iconColor: Colors.green,
            onTap: onExplore,
          ),
          _SubFab(
            animation: animation,
            offset: const Offset(spread, -spread),
            icon: Icons.speed,
            label: '뱅킹각 측정',
            iconColor: const Color(0xFFFF3B30),
            onTap: onRecord,
          ),
        ],
      ),
    );
  }
}

class _SubFab extends StatelessWidget {
  final Animation<double> animation;
  final Offset offset;
  final IconData icon;
  final String label;
  final Color? iconColor;
  final VoidCallback onTap;

  const _SubFab({
    required this.animation,
    required this.offset,
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = animation.value.clamp(0.0, 1.0).toDouble();
        return Positioned(
          bottom: -offset.dy * t, // dy 음수라 위로 이동
          left: 110 + offset.dx * t - 28, // 컨테이너 가로 220 기준 중앙 정렬
          child: IgnorePointer(
            ignoring: t < 0.5,
            child: Opacity(opacity: t, child: child),
          ),
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: iconColor ?? const Color(0xFF007AFF),
                size: 35,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int currentIndex;
  final bool isExpanded;
  final void Function(int) onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = isExpanded || index == currentIndex;
    const activeColor = Color(0xFF007AFF);
    const inactiveColor = Color(0xFF8E8E93);
    final iconWidget = Icon(
            icon,
            color: isSelected ? activeColor : inactiveColor,
            size: 24,
          );

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 60,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              iconWidget,
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? activeColor : inactiveColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
