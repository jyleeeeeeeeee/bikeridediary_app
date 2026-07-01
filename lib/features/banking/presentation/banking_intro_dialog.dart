import 'package:flutter/cupertino.dart';

/// "기록 시작 전 안내" 다이얼로그.
/// 반환값:
///   - null:            취소 또는 배경 탭 (기록 시작 안 함)
///   - _IntroResult:    "확인하고 시작" 눌렀을 때 (dontShowAgain 포함)
class BankingIntroResult {
  final bool dontShowAgain;
  const BankingIntroResult({required this.dontShowAgain});
}

Future<BankingIntroResult?> showBankingIntroDialog(BuildContext context) {
  return showCupertinoDialog<BankingIntroResult>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const _BankingIntroDialog(),
  );
}

class _BankingIntroDialog extends StatefulWidget {
  const _BankingIntroDialog();

  @override
  State<_BankingIntroDialog> createState() => _BankingIntroDialogState();
}

class _BankingIntroDialogState extends State<_BankingIntroDialog> {
  bool _dontShowAgain = false;

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Padding(
        padding: EdgeInsets.only(bottom: 4),
        child: Text('정확한 뱅킹각 기록을 위해'),
      ),
      content: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _Section(
              icon: CupertinoIcons.exclamationmark_triangle_fill,
              iconColor: CupertinoColors.systemOrange,
              title: '화면이 꺼진 채 방치하면 기록이 유실됩니다',
              body:
                  '스마트폰 OS가 배터리 절약을 위해 센서 이벤트를 지연시키거나 차단합니다.',
            ),
            const SizedBox(height: 14),
            _Section(
              icon: CupertinoIcons.checkmark_seal_fill,
              iconColor: CupertinoColors.systemGreen,
              title: '아래 상황에서는 정상 기록됩니다',
              bullets: [
                '이 앱 화면을 보고 있을 때',
                '네비게이션 앱이 켜져 있을 때',
                '다른 앱 사용 중이지만 화면이 켜져 있을 때',
              ],
            ),
            const SizedBox(height: 14),
            _Section(
              icon: CupertinoIcons.lightbulb_fill,
              iconColor: CupertinoColors.systemYellow,
              title: '팁',
              body: '라이딩 중에는 네비게이션 앱을 함께 켜두시는 것을 권장합니다.',
            ),
            const SizedBox(height: 16),
            _DontShowAgainRow(
              value: _dontShowAgain,
              onChanged: (v) => setState(() => _dontShowAgain = v ?? false),
            ),
          ],
        ),
      ),
      // Cupertino 관례는 취소=왼쪽, 확인=오른쪽이지만 요청대로 확인=왼쪽, 취소=오른쪽으로 배치.
      actions: [
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(context).pop(
            BankingIntroResult(dontShowAgain: _dontShowAgain),
          ),
          child: const Text('확인하고 시작'),
        ),
        CupertinoDialogAction(
          isDestructiveAction: false,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? body;
  final List<String>? bullets;

  const _Section({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.body,
    this.bullets,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.left,
              ),
              if (body != null) ...[
                const SizedBox(height: 4),
                Text(
                  body!,
                  style: const TextStyle(fontSize: 12, height: 1.35),
                  textAlign: TextAlign.left,
                ),
              ],
              if (bullets != null) ...[
                const SizedBox(height: 4),
                for (final b in bullets!)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '• $b',
                      style: const TextStyle(fontSize: 12, height: 1.35),
                      textAlign: TextAlign.left,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DontShowAgainRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  const _DontShowAgainRow({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CupertinoCheckbox(
              value: value,
              onChanged: onChanged,
              activeColor: CupertinoColors.activeBlue,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            '다시 보지 않기',
            style: TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }
}
