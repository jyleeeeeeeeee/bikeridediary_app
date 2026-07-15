import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../data/model/session.dart';
import '../domain/recording_provider.dart';
import 'banking_theme.dart';

class SessionListScreen extends ConsumerWidget {
  const SessionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(sessionListProvider);

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
          '뱅킹 기록',
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
        data: (sessions) {
          if (sessions.isEmpty) {
            return const Center(
              child: Text(
                '저장된 세션이 없습니다',
                style: TextStyle(color: BankingColors.textSecondary),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(sessionListProvider),
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(
                  16, 16, 16, 16 + MediaQuery.of(context).viewPadding.bottom),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: sessions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _SessionCard(session: sessions[i]),
            ),
          );
        },
      ),
    );
  }
}

class _SessionCard extends ConsumerWidget {
  final Session session;
  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFmt = DateFormat('yyyy.MM.dd HH:mm');
    final mins = session.durationMs ~/ 60000;
    final secs = (session.durationMs % 60000) ~/ 1000;

    return Card(
      color: BankingColors.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/banking/sessions/${session.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      dateFmt.format(session.startedAt),
                      style: const TextStyle(
                        color: BankingColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (session.isSynced)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(
                        CupertinoIcons.cloud_fill,
                        color: BankingColors.success,
                        size: 16,
                      ),
                    ),
                  PopupMenuButton<String>(
                    color: BankingColors.bgCard,
                    icon: const Icon(
                      Icons.more_vert,
                      color: BankingColors.textSecondary,
                    ),
                    onSelected: (v) async {
                      if (v == 'delete') {
                        await ref
                            .read(sessionRepositoryProvider)
                            .deleteSession(session.id!);
                        ref.invalidate(sessionListProvider);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          '삭제',
                          style: TextStyle(color: BankingColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '$mins분 $secs초',
                style: const TextStyle(
                  color: BankingColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _MiniStat(
                    label: '좌측 최대',
                    value: '${session.maxLeftAngle.abs().toStringAsFixed(0)}°',
                    color: BankingColors.primary,
                  ),
                  _MiniStat(
                    label: '우측 최대',
                    value: '${session.maxRightAngle.abs().toStringAsFixed(0)}°',
                    color: BankingColors.danger,
                  ),
                  _MiniStat(
                    label: '평균',
                    value: '${session.avgAbsAngle.toStringAsFixed(0)}°',
                    color: BankingColors.textPrimary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(
                color: BankingColors.textSecondary,
                fontSize: 11,
              )),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
