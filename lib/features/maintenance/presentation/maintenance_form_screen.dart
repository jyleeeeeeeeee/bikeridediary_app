import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/widgets/authenticated_image.dart';
import '../../bike/data/model/bike_response.dart';
import '../../bike/domain/bike_provider.dart';
import '../data/model/maintenance_create_request.dart';
import '../data/model/maintenance_response.dart';
import '../data/model/maintenance_schedule_create_request.dart';
import '../data/model/maintenance_schedule_response.dart';
import '../data/model/maintenance_type.dart';
import '../data/model/maintenance_update_request.dart';
import '../data/repository/maintenance_repository.dart';
import '../domain/maintenance_provider.dart';

class MaintenanceFormScreen extends ConsumerStatefulWidget {
  final String bikeId;
  final MaintenanceResponse? maintenance;

  const MaintenanceFormScreen({super.key, required this.bikeId, this.maintenance});

  @override
  ConsumerState<MaintenanceFormScreen> createState() => _MaintenanceFormScreenState();
}

class _MaintenanceFormScreenState extends ConsumerState<MaintenanceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedBikeId;
  late MaintenanceType _selectedType;
  late final TextEditingController _dateController;
  late final TextEditingController _mileageController;
  late final TextEditingController _costController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _nextDueKmController;
  bool _isLoading = false;
  bool _didInitialAutoFill = false;
  String? _autoFilledInfo;
  int? _scheduleIntervalKm;
  final List<File> _selectedImages = [];
  final List<String> _existingImageUrls = [];
  final _imagePicker = ImagePicker();

  bool get _isEdit => widget.maintenance != null;

  @override
  void initState() {
    super.initState();
    _selectedBikeId = widget.bikeId;
    final m = widget.maintenance;
    _selectedType = m != null
        ? MaintenanceType.values.firstWhere(
            (t) => t.name == m.maintenanceType,
            orElse: () => MaintenanceType.ENGINE_OIL,
          )
        : MaintenanceType.ENGINE_OIL;
    _dateController = TextEditingController(
      text: m?.maintenanceDate ?? DateTime.now().toString().substring(0, 10),
    );
    _mileageController = TextEditingController(text: m?.mileageAtMaintenance.toString() ?? '');
    _mileageController.addListener(_onMileageChanged);
    _costController = TextEditingController(text: m?.cost?.toString() ?? '');
    _descriptionController = TextEditingController(text: m?.description ?? '');
    _nextDueKmController = TextEditingController(text: m?.nextDueKm?.toString() ?? '');
    if (m?.imageUrls != null) {
      _existingImageUrls.addAll(m!.imageUrls!);
    }
  }

  @override
  void dispose() {
    _mileageController.removeListener(_onMileageChanged);
    _dateController.dispose();
    _mileageController.dispose();
    _costController.dispose();
    _descriptionController.dispose();
    _nextDueKmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bikesAsync = ref.watch(bikeListProvider);

    if (!_isEdit) {
      final schedulesAsync = ref.watch(scheduleListProvider(_selectedBikeId));
      if (!_didInitialAutoFill && bikesAsync.hasValue && schedulesAsync.hasValue) {
        _didInitialAutoFill = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _doAutoFill(bikesAsync.value!, schedulesAsync.value!);
        });
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? '정비 기록 수정' : '정비 기록 추가')),
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
                  // 바이크 선택
                  bikesAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('바이크 목록 로드 실패: $e'),
                    data: (bikes) => DropdownButtonFormField<String>(
                      initialValue: _selectedBikeId,
                      decoration: const InputDecoration(
                        labelText: '바이크',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.two_wheeler),
                      ),
                      items: bikes.map((b) {
                        return DropdownMenuItem(
                          value: b.id,
                          child: Text(b.displayName),
                        );
                      }).toList(),
                      onChanged: _isEdit
                          ? null
                          : (v) {
                              if (v != null) {
                                _mileageController.clear();
                                _nextDueKmController.clear();
                                setState(() {
                                  _selectedBikeId = v;
                                  _didInitialAutoFill = false;
                                  _autoFilledInfo = null;
                                  _scheduleIntervalKm = null;
                                });
                              }
                            },
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<MaintenanceType>(
                    initialValue: _selectedType,
                    decoration: const InputDecoration(
                      labelText: '정비 종류',
                      border: OutlineInputBorder(),
                    ),
                    items: MaintenanceType.values.map((t) {
                      return DropdownMenuItem(value: t, child: Text(t.displayName));
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _selectedType = v);
                        if (!_isEdit) _recalculateNextDueKm();
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _dateController,
                    decoration: const InputDecoration(
                      labelText: '정비 날짜 (YYYY-MM-DD)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.tryParse(_dateController.text) ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        _dateController.text = date.toString().substring(0, 10);
                      }
                    },
                    validator: (v) => v == null || v.isEmpty ? '날짜를 선택하세요' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _mileageController,
                    decoration: const InputDecoration(
                      labelText: '정비 당시 주행거리 (km)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return '주행거리를 입력하세요';
                      if (int.tryParse(v) == null) return '숫자만 입력하세요';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _costController,
                    decoration: const InputDecoration(
                      labelText: '비용 (원, 선택)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: '메모 (선택)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  _buildImageSection(),
                  const SizedBox(height: 16),
                  if (_scheduleIntervalKm != null)
                    _buildNextDueKmReadOnly()
                  else
                    TextFormField(
                      controller: _nextDueKmController,
                      decoration: const InputDecoration(
                        labelText: '다음 정비 예정 주행거리 (km, 선택)',
                        border: OutlineInputBorder(),
                        helperText: '입력하면 정비 주기가 자동 등록됩니다',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  if (_autoFilledInfo != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _autoFilledInfo!,
                              style: TextStyle(color: Colors.blue.shade700, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
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

    setState(() => _isLoading = true);
    try {
      final costText = _costController.text.trim();
      final mileage = int.parse(_mileageController.text);
      final nextDueKm = _scheduleIntervalKm != null
          ? _calculatedNextDueKm
          : (_nextDueKmController.text.trim().isNotEmpty
              ? int.tryParse(_nextDueKmController.text.trim())
              : null);
      final bikeId = _isEdit ? widget.bikeId : _selectedBikeId;

      if (_isEdit) {
        await ref.read(maintenanceListProvider(widget.bikeId).notifier).updateMaintenance(
              widget.maintenance!.id,
              MaintenanceUpdateRequest(
                maintenanceType: _selectedType.name,
                maintenanceDate: _dateController.text,
                mileageAtMaintenance: mileage,
                cost: costText.isNotEmpty ? int.tryParse(costText) : null,
                description: _descriptionController.text.trim().isEmpty
                    ? null
                    : _descriptionController.text.trim(),
                nextDueKm: nextDueKm,
              ),
              newImages: _selectedImages.isNotEmpty ? _selectedImages : null,
              existingImageUrls: _existingImageUrls,
            );
      } else {
        await ref.read(maintenanceListProvider(_selectedBikeId).notifier).createMaintenance(
              MaintenanceCreateRequest(
                bikeId: _selectedBikeId,
                maintenanceType: _selectedType.name,
                maintenanceDate: _dateController.text,
                mileageAtMaintenance: mileage,
                cost: costText.isNotEmpty ? int.tryParse(costText) : null,
                description: _descriptionController.text.trim().isEmpty
                    ? null
                    : _descriptionController.text.trim(),
                nextDueKm: nextDueKm,
              ),
              images: _selectedImages.isNotEmpty ? _selectedImages : null,
            );
      }

      final syncMsg = await _syncScheduleAfterSave(
        bikeId: bikeId,
        maintenanceType: _selectedType.name,
        mileageAtMaintenance: mileage,
        nextDueKm: nextDueKm,
      );

      if (mounted) {
        if (syncMsg != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(syncMsg)),
          );
        }
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _doAutoFill(
    List<BikeResponse> bikes,
    List<MaintenanceScheduleResponse> schedules,
  ) {
    final bike = bikes.where((b) => b.id == _selectedBikeId).firstOrNull;
    bool filled = false;

    if (bike != null && bike.totalMileageKm > 0 && _mileageController.text.isEmpty) {
      _mileageController.text = bike.totalMileageKm.toString();
      filled = true;
    }

    final schedule = schedules
        .where((s) => s.maintenanceType == _selectedType.name)
        .firstOrNull;

    if (schedule?.intervalKm != null) {
      _scheduleIntervalKm = schedule!.intervalKm;
      final mileage = int.tryParse(_mileageController.text);
      if (mileage != null && _nextDueKmController.text.isEmpty) {
        _nextDueKmController.text = (mileage + schedule.intervalKm!).toString();
        filled = true;
      }
    } else {
      _scheduleIntervalKm = null;
    }

    if (filled) {
      setState(() => _autoFilledInfo = '바이크 정보와 정비 주기에서 자동 입력되었습니다');
    }
  }

  void _recalculateNextDueKm() {
    final schedulesAsync = ref.read(scheduleListProvider(_selectedBikeId));
    schedulesAsync.whenData((schedules) {
      final schedule = schedules
          .where((s) => s.maintenanceType == _selectedType.name)
          .firstOrNull;

      if (schedule?.intervalKm != null) {
        final mileage = int.tryParse(_mileageController.text);
        if (mileage != null) {
          _nextDueKmController.text =
              (mileage + schedule!.intervalKm!).toString();
        }
        setState(() {
          _scheduleIntervalKm = schedule!.intervalKm;
          _autoFilledInfo = '정비 주기에서 다음 정비 거리가 자동 계산되었습니다';
        });
      } else {
        _nextDueKmController.clear();
        setState(() {
          _scheduleIntervalKm = null;
          _autoFilledInfo = null;
        });
      }
    });
  }

  void _onMileageChanged() {
    if (_scheduleIntervalKm != null) {
      final mileage = int.tryParse(_mileageController.text);
      if (mileage != null) {
        _nextDueKmController.text = (mileage + _scheduleIntervalKm!).toString();
      } else {
        _nextDueKmController.clear();
      }
      setState(() {});
    }
  }

  int? get _calculatedNextDueKm {
    final mileage = int.tryParse(_mileageController.text);
    if (mileage != null && _scheduleIntervalKm != null) {
      return mileage + _scheduleIntervalKm!;
    }
    return null;
  }

  Widget _buildNextDueKmReadOnly() {
    final nextDue = _calculatedNextDueKm;
    return InputDecorator(
      decoration: InputDecoration(
        labelText: '다음 정비 예정 주행거리',
        border: const OutlineInputBorder(),
        helperText: '정비 주기: ${_fmt(_scheduleIntervalKm!)}km마다',
        filled: true,
        fillColor: Colors.grey.shade100,
      ),
      child: Text(
        nextDue != null ? '${_fmt(nextDue)} km' : '-',
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildImageSection() {
    final totalCount = _existingImageUrls.length + _selectedImages.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('사진', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Text('$totalCount/5', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ..._existingImageUrls.asMap().entries.map((entry) => _buildExistingImageTile(entry.key, entry.value)),
              ..._selectedImages.asMap().entries.map((entry) => _buildNewImageTile(entry.key, entry.value)),
              if (totalCount < 5) _buildAddButton(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExistingImageTile(int index, String url) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AuthenticatedImage(
              imageUrl: url,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 100, height: 100,
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
          ),
          Positioned(
            top: 4, right: 4,
            child: GestureDetector(
              onTap: () => setState(() => _existingImageUrls.removeAt(index)),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewImageTile(int index, File file) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(file, width: 100, height: 100, fit: BoxFit.cover),
          ),
          Positioned(
            top: 4, right: 4,
            child: GestureDetector(
              onTap: () => setState(() => _selectedImages.removeAt(index)),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Container(
        width: 100, height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, color: Colors.grey[500], size: 28),
            const SizedBox(height: 4),
            Text('사진 추가', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('갤러리에서 선택'),
              onTap: () {
                ctx.pop();
                _pickFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('카메라로 촬영'),
              onTap: () {
                ctx.pop();
                _pickFromCamera();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromGallery() async {
    final remaining = 5 - _existingImageUrls.length - _selectedImages.length;
    if (remaining <= 0) return;
    final picked = await _imagePicker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (picked.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(
          picked.take(remaining).map((x) => File(x.path)),
        );
      });
    }
  }

  Future<void> _pickFromCamera() async {
    final remaining = 5 - _existingImageUrls.length - _selectedImages.length;
    if (remaining <= 0) return;
    final picked = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _selectedImages.add(File(picked.path)));
    }
  }

  String _fmt(num n) => n
      .toString()
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  Future<String?> _syncScheduleAfterSave({
    required String bikeId,
    required String maintenanceType,
    required int mileageAtMaintenance,
    int? nextDueKm,
  }) async {
    if (nextDueKm == null || nextDueKm <= mileageAtMaintenance) return null;
    try {
      final repo = ref.read(maintenanceRepositoryProvider);
      final schedules = await repo.getSchedules(bikeId);
      final hasSchedule = schedules.any((s) => s.maintenanceType == maintenanceType);

      if (!hasSchedule) {
        final intervalKm = nextDueKm - mileageAtMaintenance;
        await repo.createSchedule(MaintenanceScheduleCreateRequest(
          bikeId: bikeId,
          maintenanceType: maintenanceType,
          intervalKm: intervalKm,
        ));
        ref.invalidate(scheduleListProvider(bikeId));
        return '정비 주기가 자동 등록되었습니다 (${intervalKm}km마다)';
      }
    } catch (_) {}
    return null;
  }
}
