import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/auth_provider.dart';
import '../domain/auth_state.dart';

/// 마이클(MYCLE) 스타일 로그인 화면
/// — 소셜 로그인 중심, 이메일 로그인은 하단 텍스트 링크
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (_, state) {
      if (state.status == AuthStatus.authenticated) {
        context.go('/');
      }
      if (state.status == AuthStatus.error && state.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.errorMessage!)),
        );
      }
    });

    return Scaffold(
      body: Container(
        // MYCLE 스타일 밝은 그래디언트 배경 (연한 블루 → 화이트)
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFD6E4F0), Color(0xFFE8EFF7), Color(0xFFF5F7FA)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── 상단 영역: 로고 + 슬로건 (화면 중앙 상단) ──
              Expanded(
                flex: 5,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 슬로건 (로고 위에 작은 텍스트)
                      Text(
                        '쉽고 편한 내 바이크 관리',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1B2838).withValues(alpha: 0.6),
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // 앱 아이콘
                      const Icon(
                        Icons.two_wheeler,
                        size: 56,
                        color: Color(0xFF1B2838),
                      ),
                      const SizedBox(height: 8),
                      // 앱 이름
                      const Text(
                        '바라다',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1B2838),
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── 하단 영역: 로그인 버튼들 ──
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // "3초만에 빠른 가입" 말풍선 — MYCLE 스타일
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3A3A3A),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '3초만에 빠른 가입',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      // 말풍선 꼬리 (삼각형)
                      CustomPaint(
                        size: const Size(14, 8),
                        painter: _BubbleTailPainter(),
                      ),
                      const SizedBox(height: 8),

                      // 카카오 로그인 버튼 — 노란색 배경
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('카카오 로그인은 준비 중입니다'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFEE500),
                            foregroundColor: const Color(0xFF3A1D1D),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // 카카오 말풍선 아이콘
                              Icon(Icons.chat_bubble, size: 20),
                              SizedBox(width: 8),
                              Text(
                                '카카오로 시작하기',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Apple 로그인 버튼 — 흰색 배경, 테두리
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: OutlinedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Apple 로그인은 준비 중입니다'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            side: const BorderSide(color: Color(0xFFDDE1E6)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.apple, size: 22),
                              SizedBox(width: 8),
                              Text(
                                'Apple로 계속하기',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // "가입없이 시작하기 | 로그인하기" 텍스트 링크
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () => context.go('/'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF6B7280),
                              textStyle: const TextStyle(fontSize: 14),
                            ),
                            child: const Text('가입없이 시작하기'),
                          ),
                          Container(
                            width: 1,
                            height: 14,
                            color: const Color(0xFFD1D5DB),
                          ),
                          TextButton(
                            onPressed: () => _showEmailLoginSheet(context),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF6B7280),
                              textStyle: const TextStyle(fontSize: 14),
                            ),
                            child: const Text('로그인하기'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── 최하단: 약관 안내 ──
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  '서비스 시작시 서비스 이용약관 및\n개인정보처리방침 동의로 간주합니다',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[400],
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 이메일 로그인 바텀시트 — "로그인하기" 탭 시 표시
  void _showEmailLoginSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _EmailLoginSheet(),
    );
  }
}

/// 말풍선 꼬리 (아래 방향 삼각형)
class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3A3A3A)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 이메일 로그인 바텀시트 — 개발/테스트용 이메일 로그인
class _EmailLoginSheet extends ConsumerStatefulWidget {
  const _EmailLoginSheet();

  @override
  ConsumerState<_EmailLoginSheet> createState() => _EmailLoginSheetState();
}

class _EmailLoginSheetState extends ConsumerState<_EmailLoginSheet> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    ref.listen<AuthState>(authProvider, (_, state) {
      if (state.status == AuthStatus.authenticated) {
        Navigator.of(context).pop();
        context.go('/');
      }
      if (state.status == AuthStatus.error && state.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.errorMessage!)),
        );
      }
    });

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 핸들 바
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '이메일로 로그인',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1B2838),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: '이메일',
                hintText: 'example@email.com',
                prefixIcon: Icon(Icons.email_outlined, size: 20),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return '이메일을 입력하세요';
                if (!v.contains('@')) return '올바른 이메일 형식이 아닙니다';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: '비밀번호',
                hintText: '비밀번호를 입력하세요',
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return '비밀번호를 입력하세요';
                return null;
              },
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: authState.status == AuthStatus.loading ? null : _login,
              child: authState.status == AuthStatus.loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text('로그인'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/signup');
              },
              child: RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                  children: [
                    TextSpan(text: '계정이 없으신가요?  '),
                    TextSpan(
                      text: '회원가입',
                      style: TextStyle(
                        color: Color(0xFFFF6B35),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      ref.read(authProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text,
          );
    }
  }
}
