import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../bike/domain/bike_provider.dart';
import '../data/model/fuel_type.dart';
import '../data/model/fueling_create_request.dart';
import '../data/model/fueling_response.dart';
import '../data/model/fueling_update_request.dart';
import '../domain/fueling_provider.dart';

class FuelingFormScreen extends ConsumerStatefulWidget {
  final FuelingResponse? fueling;
  const FuelingFormScreen({super.key, this.fueling});

  @override
  ConsumerState<FuelingFormScreen> createState() => _FuelingFormScreenState();
}

class _FuelingFormScreenState extends ConsumerState<FuelingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedBikeId;
  late FuelType _fuelType;
  late final TextEditingController _dateCtl;
  late final TextEditingController _mileageCtl;
  late final TextEditingController _amountCtl;
  late final TextEditingController _priceCtl;
  late final TextEditingController _totalCostCtl;
  late final TextEditingController _stationCtl;
  late final TextEditingController _memoCtl;
  bool _isLoading = false;
  bool _autoCalc = true;

  bool get _isEdit => widget.fueling != null;

  @override
  void initState() {
    super.initState();
    final f = widget.fueling;
    _selectedBikeId = f?.bikeId;
    _fuelType = f != null
        ? FuelType.values.firstWhere((t) => t.name == f.fuelType, orElse: () => FuelType.PREMIUM)
        : FuelType.PREMIUM;
    _dateCtl = TextEditingController(
        text: f?.fuelingDate ?? DateTime.now().toString().substring(0, 10));
    _mileageCtl = TextEditingController(text: f?.mileageAtFueling.toString() ?? '');
    _amountCtl = TextEditingController(
        text: f != null ? f.fuelAmount.toStringAsFixed(2) : '');
    _priceCtl = TextEditingController(text: f?.pricePerLiter?.toString() ?? '');
    _totalCostCtl = TextEditingController(text: f?.totalCost?.toString() ?? '');
    _stationCtl = TextEditingController(text: f?.stationName ?? '');
    _memoCtl = TextEditingController(text: f?.memo ?? '');

    _amountCtl.addListener(_calcTotal);
    _priceCtl.addListener(_calcTotal);
  }

  void _calcTotal() {
    if (!_autoCalc) return;
    final amount = double.tryParse(_amountCtl.text);
    final price = int.tryParse(_priceCtl.text);
    if (amount != null && price != null) {
      _totalCostCtl.text = (amount * price).round().toString();
    }
  }

  @override
  void dispose() {
    _dateCtl.dispose();
    _mileageCtl.dispose();
    _amountCtl.dispose();
    _priceCtl.dispose();
    _totalCostCtl.dispose();
    _stationCtl.dispose();
    _memoCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bikesAsync = ref.watch(bikeListProvider);

    // 바이크 목록 로드 후 기본 선택
    if (_selectedBikeId == null && bikesAsync.hasValue && bikesAsync.value!.isNotEmpty) {
      final bikes = bikesAsync.value!;
      _selectedBikeId = bikes.firstWhereOrNull((b) => b.isRepresentative)?.id ?? bikes.first.id;
      if (_mileageCtl.text.isEmpty) {
        final bike = bikes.firstWhereOrNull((b) => b.id == _selectedBikeId);
        if (bike != null && bike.totalMileageKm > 0) {
          _mileageCtl.text = bike.totalMileageKm.toString();
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? '주유 기록 수정' : '주유 기록 추가')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 바이크 선택
                  if (!_isEdit)
                    bikesAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('바이크 목록 로드 실패: $e'),
                      data: (bikes) => DropdownButtonFormField<String>(
                        initialValue: _selectedBikeId,
                        decoration: const InputDecoration(
                          labelText: '바이크',
                          prefixIcon: Icon(Icons.two_wheeler),
                        ),
                        items: bikes.map((b) => DropdownMenuItem(
                          value: b.id,
                          child: Text(b.displayName),
                        )).toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _selectedBikeId = v);
                            final bike = bikes.firstWhereOrNull((b) => b.id == v);
                            if (bike != null && _mileageCtl.text.isEmpty) {
                              _mileageCtl.text = bike.totalMileageKm.toString();
                            }
                          }
                        },
                      ),
                    ),
                  const SizedBox(height: 16),

                  // 날짜
                  TextFormField(
                    controller: _dateCtl,
                    decoration: const InputDecoration(
                      labelText: '주유 날짜',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.tryParse(_dateCtl.text) ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        _dateCtl.text = date.toString().substring(0, 10);
                      }
                    },
                    validator: (v) => v == null || v.isEmpty ? '날짜를 선택하세요' : null,
                  ),
                  const SizedBox(height: 16),

                  // 주행거리
                  TextFormField(
                    controller: _mileageCtl,
                    decoration: const InputDecoration(
                      labelText: '주유 시 주행거리 (km)',
                      prefixIcon: Icon(Icons.speed),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return '주행거리를 입력하세요';
                      if (int.tryParse(v) == null) return '숫자만 입력하세요';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 주유량 + 리터당 가격
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _amountCtl,
                          decoration: const InputDecoration(labelText: '주유량 (L)'),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (v) {
                            if (v == null || v.isEmpty) return '필수';
                            if (double.tryParse(v) == null) return '숫자';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _priceCtl,
                          decoration: const InputDecoration(labelText: '리터당 가격 (원)'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 총 금액
                  TextFormField(
                    controller: _totalCostCtl,
                    decoration: const InputDecoration(
                      labelText: '총 금액 (원)',
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _autoCalc = false,
                  ),
                  const SizedBox(height: 16),

                  // 연료 종류
                  DropdownButtonFormField<FuelType>(
                    initialValue: _fuelType,
                    decoration: const InputDecoration(
                      labelText: '연료 종류',
                      prefixIcon: Icon(Icons.oil_barrel),
                    ),
                    items: FuelType.values.map((t) =>
                        DropdownMenuItem(value: t, child: Text(t.displayName))).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _fuelType = v);
                    },
                  ),

                  const SizedBox(height: 16),

                  // 주유소명
                  TextFormField(
                    controller: _stationCtl,
                    decoration: InputDecoration(
                      labelText: '주유소명 (선택)',
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        tooltip: '주유소 검색',
                        onPressed: () async {
                          final result = await context.push<Map<String, dynamic>>('/stations/pick');
                          if (result != null && mounted) {
                            _stationCtl.text = result['name'] as String;
                            final price = result['price'] as int?;
                            if (price != null && _priceCtl.text.isEmpty) {
                              _priceCtl.text = price.toString();
                            }
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 메모
                  TextFormField(
                    controller: _memoCtl,
                    decoration: const InputDecoration(labelText: '메모 (선택)'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),

                  // 제출
                  FilledButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
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
    final bikeId = _isEdit ? widget.fueling!.bikeId : _selectedBikeId;
    if (bikeId == null) return;

    setState(() => _isLoading = true);
    try {
      final amount = double.parse(_amountCtl.text);
      final price = _priceCtl.text.isNotEmpty ? int.tryParse(_priceCtl.text) : null;
      final cost = _totalCostCtl.text.isNotEmpty ? int.tryParse(_totalCostCtl.text) : null;
      final memo = _memoCtl.text.trim().isEmpty ? null : _memoCtl.text.trim();
      final station = _stationCtl.text.trim().isEmpty ? null : _stationCtl.text.trim();

      if (_isEdit) {
        await ref.read(fuelingListProvider(bikeId).notifier).updateFueling(
          widget.fueling!.id,
          FuelingUpdateRequest(
            fuelingDate: _dateCtl.text,
            mileageAtFueling: int.parse(_mileageCtl.text),
            fuelAmount: amount,
            pricePerLiter: price,
            totalCost: cost,
            fuelType: _fuelType.name,
            memo: memo,
            stationName: station,
          ),
        );
      } else {
        await ref.read(fuelingListProvider(bikeId).notifier).createFueling(
          FuelingCreateRequest(
            bikeId: bikeId,
            fuelingDate: _dateCtl.text,
            mileageAtFueling: int.parse(_mileageCtl.text),
            fuelAmount: amount,
            pricePerLiter: price,
            totalCost: cost,
            fuelType: _fuelType.name,
            memo: memo,
            stationName: station,
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
