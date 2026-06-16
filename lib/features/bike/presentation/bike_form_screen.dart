import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/model/bike_category.dart';
import '../data/model/bike_create_request.dart';
import '../data/model/bike_response.dart';
import '../data/model/bike_update_request.dart';
import '../domain/bike_provider.dart';

class BikeFormScreen extends ConsumerStatefulWidget {
  final BikeResponse? bike;

  const BikeFormScreen({super.key, this.bike});

  @override
  ConsumerState<BikeFormScreen> createState() => _BikeFormScreenState();
}

class _BikeFormScreenState extends ConsumerState<BikeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _manufacturerController;
  late final TextEditingController _modelController;
  late final TextEditingController _yearController;
  late final TextEditingController _mileageController;
  late final TextEditingController _memoController;
  late BikeCategory _selectedCategory;
  bool _isLoading = false;

  bool get _isEdit => widget.bike != null;

  @override
  void initState() {
    super.initState();
    _manufacturerController = TextEditingController(text: widget.bike?.manufacturerName ?? '');
    _modelController = TextEditingController(text: widget.bike?.modelName ?? '');
    _yearController = TextEditingController(
      text: widget.bike?.year.toString() ?? DateTime.now().year.toString(),
    );
    _mileageController = TextEditingController(
      text: widget.bike?.totalMileageKm.toString() ?? '0',
    );
    _memoController = TextEditingController(text: widget.bike?.memo ?? '');
    _selectedCategory = widget.bike != null
        ? BikeCategory.values.firstWhere(
            (c) => c.name == widget.bike!.category,
            orElse: () => BikeCategory.OTHER,
          )
        : BikeCategory.NAKED;
  }

  @override
  void dispose() {
    _manufacturerController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _mileageController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? '바이크 수정' : '바이크 등록')),
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
                  TextFormField(
                    controller: _manufacturerController,
                    decoration: const InputDecoration(
                      labelText: '제조사',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.isEmpty ? '제조사를 입력하세요' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _modelController,
                    decoration: const InputDecoration(
                      labelText: '모델명',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.isEmpty ? '모델명을 입력하세요' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _yearController,
                    decoration: const InputDecoration(
                      labelText: '연식',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return '연식을 입력하세요';
                      final year = int.tryParse(v);
                      if (year == null || year < 1900 || year > 2100) return '올바른 연식을 입력하세요';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<BikeCategory>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: '카테고리',
                      border: OutlineInputBorder(),
                    ),
                    items: BikeCategory.values.map((c) {
                      return DropdownMenuItem(value: c, child: Text(c.displayName));
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedCategory = v);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _mileageController,
                    decoration: const InputDecoration(
                      labelText: '총 주행거리 (km)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return '주행거리를 입력하세요';
                      if (int.tryParse(v) == null) return '숫자만 입력하세요';
                      return null;
                    },
                  ),
                  if (_isEdit) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _memoController,
                      decoration: const InputDecoration(
                        labelText: '메모',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
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
      if (_isEdit) {
        await ref.read(bikeListProvider.notifier).updateBike(
              widget.bike!.id,
              BikeUpdateRequest(
                manufacturerName: _manufacturerController.text.trim(),
                modelName: _modelController.text.trim(),
                year: int.parse(_yearController.text),
                category: _selectedCategory.name,
                totalMileageKm: int.parse(_mileageController.text),
                memo: _memoController.text.trim().isEmpty ? null : _memoController.text.trim(),
              ),
            );
      } else {
        await ref.read(bikeListProvider.notifier).create(
              BikeCreateRequest(
                manufacturerName: _manufacturerController.text.trim(),
                modelName: _modelController.text.trim(),
                year: int.parse(_yearController.text),
                category: _selectedCategory.name,
                totalMileageKm: int.parse(_mileageController.text),
              ),
            );
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
