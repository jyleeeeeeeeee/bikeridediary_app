import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/banking_provider.dart';
import '../domain/intro_dialog_preference.dart';
import '../domain/recording_provider.dart';
import 'banking_intro_dialog.dart';
import 'banking_theme.dart';
import 'widgets/tachometer_gauge.dart';

class BankingScreen extends ConsumerStatefulWidget {
  const BankingScreen({super.key});

  @override
  ConsumerState<BankingScreen> createState() => _BankingScreenState();
}

class _BankingScreenState extends ConsumerState<BankingScreen> {
  @override
  Widget build(BuildContext context) {
    // 최상단은 banking/recording을 watch 하지 않는다.
    // 50Hz로 갱신되는 bankingProvider가 상위 위젯을 rebuild하면 recording controls까지
    // 함께 rebuild되어 layout 재진입 assertion을 유발. 각 sub-widget이 자기 필요한 것만 watch.
    return Scaffold(
      backgroundColor: BankingColors.bgDark,
      appBar: AppBar(
        backgroundColor: BankingColors.bgDark,
        foregroundColor: BankingColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          '뱅킹각 측정',
          style: TextStyle(
            color: BankingColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.clock, color: BankingColors.textPrimary),
            onPressed: () => context.push('/banking/sessions'),
          ),
        ],
      ),
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(8, 12, 8, 12),
          child: Column(
            children: [
              _GaugeSection(),
              SizedBox(height: 16),
              _MaxAngleStats(),
              SizedBox(height: 16),
              _RecordingControls(),
              SizedBox(height: 8),
              _DisclaimerText(),
            ],
          ),
        ),
      ),
    );
  }
}

/// 타코미터 게이지 — banking 상태만 watch. 50Hz rebuild 대상.
class _GaugeSection extends ConsumerWidget {
  const _GaugeSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banking = ref.watch(bankingProvider);
    return TachometerGauge(
      angle: banking.angle,
      maxLeft: banking.maxLeft,
      maxRight: banking.maxRight,
    );
  }
}

class _MaxAngleStats extends ConsumerWidget {
  const _MaxAngleStats();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banking = ref.watch(bankingProvider);
    final leftAbs = banking.maxLeft.abs();
    final rightAbs = banking.maxRight.abs();
    return Card(
      color: BankingColors.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: _MaxItem(
                label: '좌측 최대',
                value: leftAbs,
                color: bankingZoneColor(leftAbs),
              ),
            ),
            Container(width: 1, height: 30, color: Colors.white12),
            Expanded(
              child: _MaxItem(
                label: '우측 최대',
                value: rightAbs,
                color: bankingZoneColor(rightAbs),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MaxItem extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _MaxItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
              color: BankingColors.textSecondary,
              fontSize: 12,
            )),
        const SizedBox(height: 4),
        Text(
          '${value.toStringAsFixed(0)}°',
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _RecordingControls extends ConsumerStatefulWidget {
  const _RecordingControls();

  @override
  ConsumerState<_RecordingControls> createState() => _RecordingControlsState();
}

class _RecordingControlsState extends ConsumerState<_RecordingControls> {
  Timer? _elapsedTicker;

  @override
  void dispose() {
    _elapsedTicker?.cancel();
    super.dispose();
  }

  void _ensureTickerRunning(bool isRecording) {
    if (isRecording && _elapsedTicker == null) {
      _elapsedTicker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (!isRecording && _elapsedTicker != null) {
      _elapsedTicker?.cancel();
      _elapsedTicker = null;
    }
  }

  Future<void> _handleStart(BuildContext context) async {
    final pref = ref.read(introDialogPreferenceProvider);
    final dismissed = await pref.isDismissed();
    if (!context.mounted) return;

    if (!dismissed) {
      final result = await showBankingIntroDialog(context);
      if (result == null) return; // 취소 또는 배경 탭
      if (result.dontShowAgain) {
        await pref.setDismissed(true);
      }
    }
    await ref.read(recordingProvider.notifier).start();
  }

  @override
  Widget build(BuildContext context) {
    final recording = ref.watch(recordingProvider);
    _ensureTickerRunning(recording.isRecording);
    final notifier = ref.read(recordingProvider.notifier);

    if (recording.isRecording) {
      final elapsed = DateTime.now().difference(recording.startedAt!);
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                final id = await notifier.stopAndSave();
                ref.invalidate(sessionListProvider);
                if (id != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('세션 저장 완료')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: BankingColors.danger,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              icon: const Icon(CupertinoIcons.stop_fill),
              label: Text('중지 (${_formatElapsed(elapsed)})'),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => notifier.cancel(),
            style: OutlinedButton.styleFrom(
              // AppTheme.outlinedButtonTheme의 minimumSize(inf, 52) override —
              // Row 안에서 unbounded width면 layout assertion 발생.
              minimumSize: const Size(0, 52),
              foregroundColor: BankingColors.textPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              side: const BorderSide(color: Colors.white24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('취소'),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _handleStart(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: BankingColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            icon: const Icon(CupertinoIcons.circle_fill),
            label: const Text('기록 시작'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              ref.read(bankingProvider.notifier).calibrate();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('현재 각도를 0°로 설정했습니다'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: BankingColors.primary, width: 1.5),
              foregroundColor: BankingColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            icon: const Icon(CupertinoIcons.refresh),
            label: const Text('각도 리셋'),
          ),
        ),
      ],
    );
  }
}

String _formatElapsed(Duration d) {
  final mm = (d.inMinutes % 60).toString().padLeft(2, '0');
  final ss = (d.inSeconds % 60).toString().padLeft(2, '0');
  if (d.inHours > 0) return '${d.inHours}:$mm:$ss';
  return '$mm:$ss';
}

class _DisclaimerText extends StatelessWidget {
  const _DisclaimerText();

  @override
  Widget build(BuildContext context) {
    return const Text(
      '(정밀 IMU 측정값이 아닌 스마트폰 센서 기반의 참고값입니다)',
      style: TextStyle(color: BankingColors.textSecondary, fontSize: 11),
    );
  }
}
