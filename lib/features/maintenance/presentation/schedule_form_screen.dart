import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/model/maintenance_schedule_create_request.dart';
import '../data/model/maintenance_schedule_response.dart';
import '../data/model/maintenance_schedule_update_request.dart';
import '../data/model/maintenance_type.dart';
import '../domain/maintenance_provider.dart';

class ScheduleFormScreen extends ConsumerStatefulWidget {
  final String bikeId;
  final MaintenanceScheduleResponse? schedule;

  const ScheduleFormScreen({super.key, required this.bikeId, this.schedule});

  @override
  ConsumerState<ScheduleFormScreen> createState() => _ScheduleFormScreenState();
}

class _ScheduleFormScreenState extends ConsumerState<ScheduleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late MaintenanceType _selectedType;
  late final TextEditingController _intervalKmController;
  late final TextEditingController _intervalMonthsController;
  bool _isLoading = false;

  bool get _isEdit => widget.schedule != null;

  @override
  void initState() {
    super.initState();
    final s = widget.schedule;
    _selectedType = s != null
        ? MaintenanceType.values.firstWhere(
            (t) => t.name == s.maintenanceType,
            orElse: () => MaintenanceType.ENGINE_OIL,
          )
        : MaintenanceType.ENGINE_OIL;
    _intervalKmController = TextEditingController(text: s?.intervalKm?.toString() ?? '');
    _intervalMonthsController = TextEditingController(text: s?.intervalMonths?.toString() ?? '');
  }

  @override
  void dispose() {
    _intervalKmController.dispose();
    _intervalMonthsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? '정비 주기 수정' : '정비 주기 추가')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!_isEdit)
                    DropdownButtonFormField<MaintenanceType>(
                      value: _selectedType,
                      decoration: const InputDecoration(
                        labelText: '정비 종류',
                        border: OutlineInputBorder(),
                      ),
                      items: MaintenanceType.values.map((t) {
                        return DropdownMenuItem(value: t, child: Text(t.displayName));
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedType = v);
                      },
                    ),
                  if (_isEdit) ...[
                    Text(
                      '정비 종류: ${_selectedType.displayName}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text('정비 종류는 변경할 수 없습니다', style: TextStyle(color: Colors.grey)),
                  ],
                  const SizedBox(height: 16),
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
                  FilledButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isEdit ? '수정' : '등록'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
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
      if (_isEdit) {
        await ref.read(scheduleListProvider(widget.bikeId).notifier).updateSchedule(
              widget.schedule!.id,
              MaintenanceScheduleUpdateRequest(
                intervalKm: kmText.isNotEmpty ? int.tryParse(kmText) : null,
                intervalMonths: monthsText.isNotEmpty ? int.tryParse(monthsText) : null,
              ),
            );
      } else {
        await ref.read(scheduleListProvider(widget.bikeId).notifier).createSchedule(
              MaintenanceScheduleCreateRequest(
                bikeId: widget.bikeId,
                maintenanceType: _selectedType.name,
                intervalKm: kmText.isNotEmpty ? int.tryParse(kmText) : null,
                intervalMonths: monthsText.isNotEmpty ? int.tryParse(monthsText) : null,
              ),
            );
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
