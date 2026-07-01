import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../data/model/session.dart';
import '../domain/recording_provider.dart';
import 'banking_theme.dart';

class SessionDetailScreen extends ConsumerWidget {
  final int sessionId;
  const SessionDetailScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(sessionDetailProvider(sessionId));

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
          '세션 상세',
          style: TextStyle(
            color: BankingColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            '불러오기 실패: $e',
            style: const TextStyle(color: BankingColors.textPrimary),
          ),
        ),
        data: (data) {
          final session = data.session;
          final samples = data.samples;
          if (session == null) {
            return const Center(
              child: Text(
                '세션을 찾을 수 없습니다',
                style: TextStyle(color: BankingColors.textPrimary),
              ),
            );
          }
          return _DetailBody(session: session, samples: samples);
        },
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  final Session session;
  final List<AngleSample> samples;
  const _DetailBody({required this.session, required this.samples});

  Future<void> _onBackup(BuildContext context, WidgetRef ref) async {
    // TODO: 백엔드 BankingSession API 연결.
    // 완성 후 markSynced(session.id!, DateTime.now()) 호출하고 sessionListProvider/sessionDetailProvider invalidate.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('서버 백업 기능은 준비 중입니다')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFmt = DateFormat('yyyy.MM.dd HH:mm:ss');
    final mins = session.durationMs ~/ 60000;
    final secs = (session.durationMs % 60000) ~/ 1000;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: BankingColors.bgCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row('시작', dateFmt.format(session.startedAt)),
                _row('종료', dateFmt.format(session.endedAt)),
                _row('지속 시간', '$mins분 $secs초'),
                _row('좌측 최대',
                    '${session.maxLeftAngle.abs().toStringAsFixed(0)}°'),
                _row('우측 최대',
                    '${session.maxRightAngle.abs().toStringAsFixed(0)}°'),
                _row('평균 절대값', '${session.avgAbsAngle.toStringAsFixed(0)}°'),
                _row(
                  '백업 상태',
                  session.isSynced
                      ? '${DateFormat('yyyy.MM.dd HH:mm').format(session.syncedAt!)} 백업됨'
                      : '미백업',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          color: BankingColors.bgCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 16, 16),
            child: SizedBox(
              height: 260,
              child: samples.isEmpty
                  ? const Center(
                      child: Text(
                        '샘플 데이터 없음',
                        style: TextStyle(color: BankingColors.textSecondary),
                      ),
                    )
                  : _AngleLineChart(samples: samples),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: session.isSynced ? null : () => _onBackup(context, ref),
          style: ElevatedButton.styleFrom(
            backgroundColor: BankingColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: BankingColors.bgCard,
            disabledForegroundColor: BankingColors.textSecondary,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          icon: Icon(
            session.isSynced
                ? CupertinoIcons.cloud_fill
                : CupertinoIcons.cloud_upload_fill,
          ),
          label: Text(session.isSynced ? '이미 백업됨' : '서버 백업'),
        ),
      ],
    );
  }

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(k,
                style: const TextStyle(color: BankingColors.textSecondary)),
          ),
          Expanded(
            child: Text(v,
                style: const TextStyle(color: BankingColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}

class _AngleLineChart extends StatelessWidget {
  final List<AngleSample> samples;
  const _AngleLineChart({required this.samples});

  @override
  Widget build(BuildContext context) {
    final spots = _downsample(samples, maxPoints: 600);
    double minY = 0, maxY = 0;
    for (final s in spots) {
      if (s.y < minY) minY = s.y;
      if (s.y > maxY) maxY = s.y;
    }
    final bound = (minY.abs() > maxY ? minY.abs() : maxY).clamp(10.0, 90.0) + 5;

    return LineChart(
      LineChartData(
        minY: -bound,
        maxY: bound,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: bound / 2,
          getDrawingHorizontalLine: (v) => FlLine(
            color: Colors.white12,
            strokeWidth: 1,
            dashArray: v == 0 ? null : [4, 4],
          ),
        ),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: bound / 2,
              getTitlesWidget: (v, _) => Text(
                '${v.toInt()}°',
                style: const TextStyle(
                  color: BankingColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: BankingColors.primary,
            barWidth: 1.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: BankingColors.primary.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _downsample(List<AngleSample> data, {required int maxPoints}) {
    if (data.length <= maxPoints) {
      return data
          .map((s) => FlSpot(s.tMs / 1000, s.angle))
          .toList(growable: false);
    }
    final bucket = (data.length / maxPoints).ceil();
    final result = <FlSpot>[];
    for (int i = 0; i < data.length; i += bucket) {
      double sumT = 0;
      double sumA = 0;
      int count = 0;
      for (int j = i; j < i + bucket && j < data.length; j++) {
        sumT += data[j].tMs;
        sumA += data[j].angle;
        count++;
      }
      result.add(FlSpot(sumT / count / 1000, sumA / count));
    }
    return result;
  }
}
