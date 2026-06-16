import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/model/maintenance_schedule_response.dart';
import '../data/model/maintenance_schedule_update_request.dart';
import '../data/model/maintenance_type.dart';
import '../domain/maintenance_provider.dart';

class ScheduleDetailScreen extends ConsumerStatefulWidget {
  final String bikeId;
  final String scheduleId;

  const ScheduleDetailScreen({
    super.key,
    required this.bikeId,
    required this.scheduleId,
  });

  @override
  ConsumerState<ScheduleDetailScreen> createState() => _ScheduleDetailScreenState();
}

class _ScheduleDetailScreenState extends ConsumerState<ScheduleDetailScreen> {
  bool _isEditing = false;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _intervalKmController;
  late final TextEditingController _intervalMonthsController;

  @override
  void initState() {
    super.initState();
    _intervalKmController = TextEditingController();
    _intervalMonthsController = TextEditingController();
  }

  @override
  void dispose() {
    _intervalKmController.dispose();
    _intervalMonthsController.dispose();
    super.dispose();
  }

  void _startEditing(MaintenanceScheduleResponse s) {
    setState(() {
      _isEditing = true;
      _intervalKmController.text = s.intervalKm?.toString() ?? '';
      _intervalMonthsController.text = s.intervalMonths?.toString() ?? '';
    });
  }

  void _cancelEditing() {
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    final schedulesAsync = ref.watch(scheduleListProvider(widget.bikeId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('정비 주기 상세'),
        actions: [
          if (!_isEditing)
            schedulesAsync.whenOrNull(
                  data: (schedules) {
                    final s = schedules.firstWhereOrNull((s) => s.id == widget.scheduleId);
                    if (s == null) return const SizedBox.shrink();
                    return IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _confirmDelete(s),
                    );
                  },
                ) ??
                const SizedBox.shrink(),
        ],
      ),
      body: schedulesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (schedules) {
          final s = schedules.firstWhereOrNull((s) => s.id == widget.scheduleId);
          if (s == null) return const Center(child: Text('정비 주기를 찾을 수 없습니다'));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: _isEditing ? _buildEditView(s) : _buildDetailView(s),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailView(MaintenanceScheduleResponse s) {
    final type = MaintenanceType.values.firstWhere(
      (t) => t.name == s.maintenanceType,
      orElse: () => MaintenanceType.OTHER,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (s.overdue)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.red.shade700, size: 20),
                const SizedBox(width: 8),
                Text('정비가 필요합니다',
                    style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        _infoTile('정비 종류', type.displayName),
        if (s.intervalKm != null) _infoTile('km 기준 주기', '${s.intervalKm}km마다'),
        if (s.intervalMonths != null) _infoTile('개월 기준 주기', '${s.intervalMonths}개월마다'),
        const Divider(height: 32),
        if (s.lastMaintenanceMileage != null)
          _infoTile('마지막 정비 주행거리', '${s.lastMaintenanceMileage}km'),
        if (s.lastMaintenanceDate != null)
          _infoTile('마지막 정비 날짜', s.lastMaintenanceDate!),
        if (s.lastMaintenanceMileage == null && s.lastMaintenanceDate == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('정비 기록이 없습니다', style: TextStyle(color: Colors.grey)),
          ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => _startEditing(s),
          icon: const Icon(Icons.edit),
          label: const Text('수정'),
        ),
      ],
    );
  }

  Widget _buildEditView(MaintenanceScheduleResponse s) {
    final type = MaintenanceType.values.firstWhere(
      (t) => t.name == s.maintenanceType,
      orElse: () => MaintenanceType.OTHER,
    );
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('정비 종류: ${type.displayName}',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text('정비 종류는 변경할 수 없습니다', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          TextFormField(
            controller: _intervalKmController,
            decoration: const InputDecoration(
              labelText: 'km 기준 주기 (예: 3000)',
              border: OutlineInputBorder(),
              helperText: 'km 또는 개월 중 하나는 필수',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _intervalMonthsController,
            decoration: const InputDecoration(
              labelText: '개월 기준 주기 (예: 6)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _isLoading ? null : () => _save(s),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('저장'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _cancelEditing,
                  child: const Text('취소'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _save(MaintenanceScheduleResponse s) async {
    if (!_formKey.currentState!.validate()) return;

    final kmText = _intervalKmController.text.trim();
    final monthsText = _intervalMonthsController.text.trim();
    if (kmText.isEmpty && monthsText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('km 또는 개월 기준 주기 중 하나는 입력해야 합니다')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(scheduleListProvider(widget.bikeId).notifier).updateSchedule(
            s.id,
            MaintenanceScheduleUpdateRequest(
              intervalKm: kmText.isNotEmpty ? int.tryParse(kmText) : null,
              intervalMonths: monthsText.isNotEmpty ? int.tryParse(monthsText) : null,
            ),
          );
      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('정비 주기가 수정되었습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmDelete(MaintenanceScheduleResponse s) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('정비 주기 삭제'),
        content: const Text('정말 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => ctx.pop(false), child: const Text('취소')),
          TextButton(onPressed: () => ctx.pop(true), child: const Text('삭제')),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await ref.read(scheduleListProvider(widget.bikeId).notifier).deleteSchedule(s.id);
      if (mounted) context.pop();
    }
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
